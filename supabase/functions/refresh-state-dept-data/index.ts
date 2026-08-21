// Whereabout: State Department advisory/visa refresh — Edge Function version
// (field mapping corrected 2026-08-19)
//
// CADENCE NOTE (decided): scheduled MONTHLY via pg_cron while
// pre-release. Switch to DAILY once the app ships — that's a one-line
// change to the cron expression in the migration file, nothing here.
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

import { createClient } from "npm:@supabase/supabase-js@2";

interface CountryRow {
  id: string;
  iso_code: string;
  name_common: string;
}

const BASE_URL = "https://cadataapi.state.gov/api";
const REQUEST_DELAY_MS = 1500;
// Lowered from 15s — a handful of slow/hanging per-country requests
// eating close to the old timeout each was enough, across a batch, to
// blow past Supabase's own 150s Edge Function idle limit.
const FETCH_TIMEOUT_MS = 6_000;

// Mechanical HTML-strip truncation cap for entry_exit_requirements — that
// endpoint returns several paragraphs covering many unrelated topics
// (passport validity, lost-passport policy, HIV restrictions, ...), too
// long for a UI summary field as-is. Cuts at the last sentence boundary
// before the cap rather than mid-sentence. This is NOT curation — it's a
// mechanical excerpt, same "hand-check before fully trusting" status
// import-curated-data.mjs's auto-tokenized phrases already have.
const VISA_SUMMARY_MAX_CHARS = 600;

const HEADERS = {
  "User-Agent": "Mozilla/5.0 (compatible; WhereaboutApp/1.0; personal travel app data refresh)",
  "Accept": "application/json",
};

// Lowercases, strips accents (Côte -> Cote), and drops punctuation and
// lone single-letter tokens (handles French elision either written as
// "d'Ivoire" or, as the State Dept's own feed inconsistently does,
// "d Ivoire" with the apostrophe just gone) — added 2026-08-19 after
// "Côte d'Ivoire" and "Cote d Ivoire" showed up as two different
// unmatched names across two separate real API calls, minutes apart, for
// the same country. Reduces (doesn't eliminate) the need for literal
// aliases below — genuinely different names (Burma/Myanmar) still need one.
const COMBINING_DIACRITICS = new RegExp("[\\u0300-\\u036f]", "g");

function normalizeName(name: string): string {
  return name
    .normalize("NFD").replace(COMBINING_DIACRITICS, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\b[a-z]\b/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

// A handful of known Title-vs-name_common mismatches that normalizeName
// alone can't bridge (genuinely different names, not just accents/
// punctuation). Not exhaustive — anything not listed here just gets
// skipped and logged, same as any other unresolvable row, rather than
// guessed at. Keys and values are both pre-normalized.
const NAME_ALIASES: Record<string, string> = {
  "czech republic": normalizeName("Czechia"),
  "burma": normalizeName("Myanmar"),
  "the bahamas": normalizeName("Bahamas"),
  "the gambia": normalizeName("Gambia"),
  "cabo verde": normalizeName("Cape Verde"),
  "korea south": normalizeName("South Korea"),
  "korea north": normalizeName("North Korea"),
  // Corrected 2026-08-19 — these previously pointed at guessed
  // name_common values ("Micronesia (Federated States of)", ...) that
  // don't actually exist in the countries table; fixed against real
  // query results instead of a second guess. normalizeName makes
  // "Côte d'Ivoire" and "Cote d Ivoire" equal *to each other*, but that
  // shared normalized form still isn't "Ivory Coast"'s — still a
  // genuinely different name, still needs an entry here.
  "cote ivoire": normalizeName("Ivory Coast"),
  "federated states of micronesia": normalizeName("Micronesia"),
  "the kyrgyz republic": normalizeName("Kyrgyzstan"),
  "kingdom of denmark": normalizeName("Denmark"),
  "democratic republic of the congo": normalizeName("DR Congo"),
  "republic of the congo": normalizeName("Congo"),
};

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function fetchJson(url: string) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(url, { headers: HEADERS, signal: controller.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(timeout);
  }
}

function stripHtml(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const text = value
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&(?:#39|apos);/g, "'")
    // Decoded, not blanked — this used to turn "Paraná" into "Paran ".
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    .replace(/\s+/g, " ")
    .trim();
  return text.length > 0 ? text : null;
}

// Advisory Summary fields often lead with a revision/changelog note about
// what changed since the last version ("There were no changes to the
// advisory level...", "Reissued after periodic review without changes.",
// "Updated to reflect...") rather than actual advisory content — spotted
// live: "I feel like that is not meant to be written in the actual travel
// advisory." Confirmed against real data: present on
// roughly 3/4 of advisories, absent on the rest (those start directly
// with real content, e.g. "Exercise normal precaution in Australia."), so
// this only strips the first paragraph when it actually matches known
// revision-note phrasing — not exhaustive, a leading note using different
// wording would still slip through as if it were content.
const REVISION_NOTE_PATTERN = /^(there (was|were|are)\b.*chang|reissued\b|last update\s*:|updated to\b|the (advisory level|health risk indicator|unrest indicator)\b)/i;

function cleanAdvisorySummary(html: unknown): string | null {
  if (typeof html !== "string" || html.trim().length === 0) return null;
  // A literal "Advisory summary" label paragraph is a subheading, never
  // real content — drop wherever it appears, not just at the start.
  let cleaned = html.replace(/<p>\s*<b>\s*advisory summary\s*<\/b>\s*<\/p>/gi, "");
  const firstPara = cleaned.match(/^\s*<p>([\s\S]*?)<\/p>/i);
  if (firstPara) {
    const plainText = firstPara[1].replace(/<[^>]*>/g, "").trim();
    if (REVISION_NOTE_PATTERN.test(plainText)) {
      cleaned = cleaned.slice(firstPara[0].length);
    }
  }
  return stripHtml(cleaned);
}

// Cuts at the last ". " before the cap, so the excerpt ends on a real
// sentence boundary rather than mid-word.
function excerpt(text: string, maxChars: number): string {
  if (text.length <= maxChars) return text;
  const cut = text.lastIndexOf(". ", maxChars);
  const truncated = cut > maxChars * 0.4 ? text.slice(0, cut + 1) : text.slice(0, maxChars);
  return `${truncated.trim()}…`;
}

// "Greece - Level 1: Exercise Normal Precautions" -> {countryName, level, levelLabel}
function parseAdvisoryTitle(title: string) {
  const match = title.match(/^(.+?)\s*-\s*Level\s*(\d+)\s*:\s*(.+)$/i);
  if (!match) return null;
  return {
    countryName: match[1].trim(),
    level: `Level ${match[2]}`,
    levelLabel: match[3].trim(),
  };
}

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
    .select("id, iso_code, name_common");
  if (countriesError) {
    return new Response(JSON.stringify({ error: countriesError.message }), { status: 500 });
  }
  const countryRows = (countries ?? []) as CountryRow[];
  const countryIsoToId = new Map<string, string>(countryRows.map((c) => [c.iso_code, c.id]));
  const countryIdToName = new Map<string, string>(countryRows.map((c) => [c.id, c.name_common]));
  const countryNameToRow = new Map<string, CountryRow>(
    countryRows.map((c) => [normalizeName(c.name_common), c])
  );

  function resolveCountryByName(rawName: string): CountryRow | null {
    const key = normalizeName(rawName);
    return countryNameToRow.get(key) ?? countryNameToRow.get(NAME_ALIASES[key] ?? "") ?? null;
  }

  const log: string[] = [];
  let advisoriesOk = 0, advisoriesSkipped = 0;
  let visasOk = 0, visasSkipped = 0;
  const unmatchedAdvisoryNames = new Set<string>();
  const misroutedVisaCountries = new Set<string>();

  // --- Advisories ---
  // Only on the first visa batch (or an explicit ?skipAdvisories=false) —
  // even bulk-upserted (see below), refetching and rewriting ~200 rows on
  // every batched visa call would be wasted work. Idempotent either way
  // (real unique constraint + upsert, migration 006), so running it again
  // later (a real monthly refresh, or a manual ?visaBatchStart=0 call) is
  // always safe.
  const visaBatchStart = Number(url.searchParams.get("visaBatchStart") ?? 0);
  const skipAdvisories = url.searchParams.get("skipAdvisories") === "true" ||
    (url.searchParams.has("visaBatchStart") && visaBatchStart > 0);

  if (!skipAdvisories) {
    try {
      const all = await fetchJson(`${BASE_URL}/TravelAdvisories`);
      const rows = Array.isArray(all) ? all : (all as any)?.data ?? (all as any)?.results ?? [];
      log.push(`Got ${rows.length} advisory records.`);

      // One bulk upsert instead of N sequential delete+insert round-trips
      // — needs migration 006's unique index on (country_id,
      // issuing_authority) to have an onConflict target at all. Keyed by
      // country_id (a Map, not a plain array) because a handful of
      // countries have more than one raw record (regional carve-outs,
      // reissues) that all resolve to the same country — Postgres's
      // ON CONFLICT DO UPDATE errors ("cannot affect row a second time")
      // if the same key appears twice in one upsert call. Last one in the
      // feed wins; not a meaningful ordering guarantee, just a tie-break.
      const toUpsert = new Map<string, Record<string, unknown>>();
      for (const row of rows as any[]) {
        const parsed = parseAdvisoryTitle(row.Title ?? "");
        if (!parsed) { advisoriesSkipped++; continue; }

        const countryRow = resolveCountryByName(parsed.countryName);
        if (!countryRow) {
          unmatchedAdvisoryNames.add(parsed.countryName);
          advisoriesSkipped++;
          continue;
        }

        const officialUrl = row.Link;
        if (!officialUrl) { advisoriesSkipped++; continue; }

        toUpsert.set(countryRow.id, {
          country_id: countryRow.id,
          issuing_authority: "US State Department",
          level: parsed.level,
          level_label: parsed.levelLabel,
          summary: cleanAdvisorySummary(row.Summary),
          official_url: officialUrl,
          issued_at: row.Published ? new Date(row.Published).toISOString().slice(0, 10) : null,
          last_verified_at: new Date().toISOString(),
        });
      }

      const upsertRows = [...toUpsert.values()];
      if (upsertRows.length > 0) {
        const { error } = await supabase
          .from("travel_advisories")
          .upsert(upsertRows, { onConflict: "country_id,issuing_authority" });
        if (error) {
          log.push(`Advisories upsert failed: ${error.message}`);
        } else {
          advisoriesOk = upsertRows.length;
        }
      }
      if (unmatchedAdvisoryNames.size > 0) {
        log.push(`Unmatched advisory country names (${unmatchedAdvisoryNames.size}): ${[...unmatchedAdvisoryNames].join(", ")}`);
      }
    } catch (err) {
      log.push(`Advisories fetch failed: ${(err as Error).message}`);
    }
  } else {
    log.push("Skipped advisories pass (visaBatchStart > 0).");
  }

  // Country id -> its own advisory Link, reused as the visa row's
  // official_url below (see file header on why there's no better option).
  // Read back from the DB rather than the in-memory map above, since that
  // map is empty when the advisories pass was skipped this call.
  const { data: advisoryLinkRows } = await supabase
    .from("travel_advisories")
    .select("country_id, official_url")
    .eq("issuing_authority", "US State Department");
  const advisoryLinkByCountryId = new Map<string, string>(
    (advisoryLinkRows ?? []).map((r: any) => [r.country_id, r.official_url])
  );

  // --- Visa/entry-exit summaries (US nationality only, per architecture doc) ---
  // Batched — the 1.5s per-country rate-limit delay means a full ~250-
  // country pass exceeds Supabase's 150s Edge Function idle timeout in a
  // single invocation. ?visaBatchStart=N&visaBatchSize=M processes just
  // that slice (visaBatchStart declared above, alongside skipAdvisories).
  const visaBatchSize = Number(url.searchParams.get("visaBatchSize") ?? 9999);
  const visaCountryEntries = [...countryIsoToId.entries()]
    .filter(([code]) => code !== "US")
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(visaBatchStart, visaBatchStart + visaBatchSize);
  log.push(`Visa batch: ${visaBatchStart}-${visaBatchStart + visaCountryEntries.length} of ${countryIsoToId.size - 1}.`);

  const usId = countryIsoToId.get("US");
  if (usId) {
    for (const [code, countryId] of visaCountryEntries) {
      try {
        const data = await fetchJson(`${BASE_URL}/CountryTravelInformation/${code}/entry_exit_requirements`);
        const stripped = stripHtml(data);
        const officialUrl = advisoryLinkByCountryId.get(countryId);

        // No advisory Link for this country means no official source to
        // cite — skip rather than fabricate a URL (see file header).
        if (!stripped || !officialUrl) { visasSkipped++; continue; }

        // This endpoint has been observed returning a *different*
        // country's content for the requested code — reproducibly, not a
        // one-off (confirmed 2026-08-19: BA returned Bahrain's content, BH
        // returned Belize's, ~40% of a 127-country sample was affected).
        // Cheap guard: the response should at least mention the country it
        // claims to be about. Not foolproof (a genuinely correct summary
        // could avoid naming the country; a wrong one could coincidentally
        // name it) but catches the bulk of what the 2026-08-19 audit found
        // by hand. Skip and log rather than store data we can't trust.
        const expectedName = countryIdToName.get(countryId);
        if (expectedName && !stripped.toLowerCase().includes(expectedName.toLowerCase())) {
          misroutedVisaCountries.add(`${expectedName} (${code})`);
          visasSkipped++;
          continue;
        }

        const summary = excerpt(stripped, VISA_SUMMARY_MAX_CHARS);

        // Upsert, not delete-then-insert — one round-trip, needs
        // migration 006's unique index for the onConflict target.
        // application_url deliberately omitted — hand-filled only, the
        // State Dept feed has no equivalent. ON CONFLICT DO UPDATE only
        // touches listed columns, so leaving it out here is what keeps a
        // manually-added value from being wiped on the next refresh. Don't
        // add it "for completeness."
        const { error } = await supabase.from("visa_requirements").upsert({
          destination_country_id: countryId,
          nationality_country_id: usId,
          summary,
          official_url: officialUrl,
          last_verified_at: new Date().toISOString(),
        }, { onConflict: "destination_country_id,nationality_country_id" });
        if (error) { visasSkipped++; continue; }
        visasOk++;
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
