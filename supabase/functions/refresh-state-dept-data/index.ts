// Whereabout: State Department advisory/visa refresh — Edge Function version
// (field mapping corrected 2026-08-19)
//
// CADENCE NOTE (2026-10-26): page views now refresh one country at a
// time via refresh-country-state-dept. This full pass is for manual
// backfills/audits, plus prod's monthly pg_cron job (set up by hand,
// not in migrations; dev has none).
//
// 2026-08-19: field mapping corrected against real ?inspect=GR output —
// see HANDOFF.md for the full before/after. Short version of what was
// wrong: TravelAdvisories rows have no Level/LevelLabel/CountryCode
// fields at all (parsed from Title instead — "Greece - Level 1: Exercise
// Normal Precautions"); `Category` looks like an ISO code but isn't
// reliable (Australia's Category is "AS", Mongolia's is "MG" — both
// wrong) so it's not used as the join key; `Link` is a real, correct URL
// straight from the API, no construction needed. entry_exit_requirements
// returns a raw HTML string, not a JSON object with named fields, and has
// no URL of its own — the matching country's own advisory Link is reused
// for that, since there's no better per-country "visa page" URL available
// from this API. Both tables get a delete-before-insert on their natural
// key so re-running this on a schedule doesn't duplicate rows (the bug
// found in import-curated-data.mjs, fixed here so it can't recur monthly).
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically
// into every Edge Function's environment — no secrets to configure here.
//
// 2026-10-26: advisory/visa parse + upsert moved into
// ../_shared/state-dept-refresh.ts, shared with refresh-country-state-dept.
//
// 2026-08-25: fetch/parse helpers (stripHtml, normalizeName, NAME_ALIASES,
// fetchJson, ...) moved into ../_shared/state-dept.ts so this function and
// discover-state-dept-codes (which finds new state_dept_entry_exit_code
// overrides — run that one when a common country like Japan turns up with
// no visa data; see its own file header) can't drift apart on how a
// response gets cleaned or a country name gets matched.

import { createClient } from "npm:@supabase/supabase-js@2";
import { BASE_URL, DEFAULT_REQUEST_DELAY_MS, sleep, fetchJson } from "../_shared/state-dept.ts";
import { type CountryRow, ISSUING_AUTHORITY, refreshAdvisories, refreshUsVisa } from "../_shared/state-dept-refresh.ts";

const REQUEST_DELAY_MS = DEFAULT_REQUEST_DELAY_MS;

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const inspectCode = url.searchParams.get("inspect");

  // ---------------------------------------------------------------
  // Inspect mode — no writes, just returns the raw shape for review
  // ---------------------------------------------------------------
  if (inspectCode) {
    const result: Record<string, unknown> = {};
    try {
      result.advisories = await fetchJson(`${BASE_URL}/TravelAdvisories`);
    } catch (err) {
      result.advisoriesError = (err as Error).message;
    }
    await sleep(REQUEST_DELAY_MS);
    try {
      result.entryExit = await fetchJson(
        `${BASE_URL}/CountryTravelInformation/${inspectCode.toUpperCase()}/entry_exit_requirements`
      );
    } catch (err) {
      result.entryExitError = (err as Error).message;
    }
    return new Response(JSON.stringify(result, null, 2), {
      headers: { "Content-Type": "application/json" },
    });
  }

  // ---------------------------------------------------------------
  // Real run
  // ---------------------------------------------------------------
  const { data: countries, error: countriesError } = await supabase
    .from("countries")
    .select("id, iso_code, name_common, state_dept_entry_exit_code");
  if (countriesError) {
    return new Response(JSON.stringify({ error: countriesError.message }), { status: 500 });
  }
  const countryRows = (countries ?? []) as CountryRow[];

  const log: string[] = [];
  let advisoriesOk = 0, advisoriesSkipped = 0;
  let visasOk = 0, visasSkipped = 0;
  const misroutedVisaCountries = new Set<string>();
  const noAdvisoryLinkCountries = new Set<string>();

  // --- Advisories ---
  // Only on the first visa batch (or an explicit ?skipAdvisories=false) —
  // even bulk-upserted, refetching and rewriting ~200 rows on
  // every batched visa call would be wasted work. Idempotent either way
  // (real unique constraint + upsert, migration 006), so running it again
  // later (a manual ?visaBatchStart=0 call) is always safe.
  const visaBatchStart = Number(url.searchParams.get("visaBatchStart") ?? 0);
  const skipAdvisories = url.searchParams.get("skipAdvisories") === "true" ||
    (url.searchParams.has("visaBatchStart") && visaBatchStart > 0);

  if (!skipAdvisories) {
    try {
      ({ ok: advisoriesOk, skipped: advisoriesSkipped } = await refreshAdvisories(supabase, countryRows, log));
    } catch (err) {
      log.push(`Advisories fetch failed: ${(err as Error).message}`);
    }
  } else {
    log.push("Skipped advisories pass (visaBatchStart > 0).");
  }

  // Country id -> its own advisory Link, reused as the visa row's
  // official_url below (see file header on why there's no better option).
  // Read back from the DB rather than the advisories pass, since that
  // pass is skipped on later batches.
  const { data: advisoryLinkRows } = await supabase
    .from("travel_advisories")
    .select("country_id, official_url")
    .eq("issuing_authority", ISSUING_AUTHORITY);
  const advisoryLinkByCountryId = new Map<string, string>(
    (advisoryLinkRows ?? []).map((r: any) => [r.country_id, r.official_url])
  );

  // --- Visa/entry-exit summaries (US nationality only, per architecture doc) ---
  // Batched — the per-country rate-limit delay means a full ~250-
  // country pass exceeds Supabase's 150s Edge Function idle timeout in a
  // single invocation. ?visaBatchStart=N&visaBatchSize=M processes just
  // that slice (visaBatchStart declared above, alongside skipAdvisories).
  const visaBatchSize = Number(url.searchParams.get("visaBatchSize") ?? 9999);
  const visaCountries = countryRows
    .filter((c) => c.iso_code !== "US")
    .sort((a, b) => a.iso_code.localeCompare(b.iso_code))
    .slice(visaBatchStart, visaBatchStart + visaBatchSize);
  log.push(`Visa batch: ${visaBatchStart}-${visaBatchStart + visaCountries.length} of ${countryRows.length - 1}.`);

  const usId = countryRows.find((c) => c.iso_code === "US")?.id;
  if (usId) {
    for (const country of visaCountries) {
      const label = `${country.name_common} (${country.iso_code})`;
      try {
        const result = await refreshUsVisa(supabase, country, usId, advisoryLinkByCountryId.get(country.id), countryRows);
        if (result === "ok") {
          visasOk++;
        } else {
          visasSkipped++;
          if (result === "misrouted") misroutedVisaCountries.add(label);
          if (result === "noAdvisoryLink") noAdvisoryLinkCountries.add(label);
        }
      } catch {
        visasSkipped++;
      }
      await sleep(REQUEST_DELAY_MS);
    }
  } else {
    log.push("No US country row found — required for the pairwise visa table.");
  }
  if (misroutedVisaCountries.size > 0) {
    log.push(`Misrouted entry_exit_requirements, skipped (${misroutedVisaCountries.size}): ${[...misroutedVisaCountries].join(", ")}`);
  }
  if (noAdvisoryLinkCountries.size > 0) {
    log.push(`No travel_advisories official_url to cite, skipped (${noAdvisoryLinkCountries.size}): ${[...noAdvisoryLinkCountries].join(", ")}`);
  }

  const summary = {
    advisories: { ok: advisoriesOk, skipped: advisoriesSkipped },
    visas: { ok: visasOk, skipped: visasSkipped },
    log,
    ranAt: new Date().toISOString(),
  };

  return new Response(JSON.stringify(summary, null, 2), {
    headers: { "Content-Type": "application/json" },
  });
});
