// Whereabout: on-demand State Dept refresh for one country (2026-10-26)
//
// The client calls this when a country page's advisory or visa
// last_verified_at is older than STALE_AFTER_DAYS. Refreshes only what's
// stale, then the client re-reads the tables. Replaces scheduled refreshes
// — at current traffic, page views alone cost the API less than a cron.
//
// Guards against overworking cadataapi.state.gov:
//   - re-checks staleness here, so a client can't force a fetch
//   - COOLDOWN_MINUTES per country between attempts, success or not —
//     a country with no State Dept data would otherwise fetch every view
//
// last_verified_at only moves when a fetch succeeds (see
// ../_shared/state-dept-refresh.ts); a failed refresh leaves the old date.
//
// Call it like:
//   GET https://<project-ref>.functions.supabase.co/refresh-country-state-dept?iso=JP

import { createClient } from "npm:@supabase/supabase-js@2";
import { DEFAULT_REQUEST_DELAY_MS, sleep } from "../_shared/state-dept.ts";
import { type CountryRow, ISSUING_AUTHORITY, refreshAdvisories, refreshUsVisa } from "../_shared/state-dept-refresh.ts";

// Keep in sync with stateDeptStaleAfter in supabase_country_repository.dart.
const STALE_AFTER_DAYS = 30;
const COOLDOWN_MINUTES = 60;

// Same as convert-currency — browser clients need these on every response.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

const respond = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: corsHeaders });

function olderThan(timestamp: string | null | undefined, ms: number): boolean {
  return !timestamp || Date.now() - new Date(timestamp).getTime() > ms;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const iso = new URL(req.url).searchParams.get("iso")?.toUpperCase();
  if (!iso) return respond({ error: "Missing required query param: iso (e.g. ?iso=JP)" }, 400);

  // Every country, not just the target — name matching needs the full list.
  const { data: countries, error: countriesError } = await supabase
    .from("countries")
    .select("id, iso_code, name_common, state_dept_entry_exit_code");
  if (countriesError) return respond({ error: countriesError.message }, 500);
  const countryRows = (countries ?? []) as CountryRow[];
  const country = countryRows.find((c) => c.iso_code === iso);
  const usId = countryRows.find((c) => c.iso_code === "US")?.id;
  if (!country) return respond({ error: `Unknown country: ${iso}` }, 404);

  const { data: attempt } = await supabase
    .from("state_dept_refresh_attempts")
    .select("attempted_at")
    .eq("country_id", country.id)
    .maybeSingle();
  if (!olderThan(attempt?.attempted_at, COOLDOWN_MINUTES * 60_000)) {
    return respond({ refreshed: false, reason: "cooldown" });
  }

  const staleMs = STALE_AFTER_DAYS * 24 * 60 * 60_000;
  const { data: advisory } = await supabase
    .from("travel_advisories")
    .select("last_verified_at")
    .eq("country_id", country.id)
    .eq("issuing_authority", ISSUING_AUTHORITY)
    .maybeSingle();
  const needsAdvisory = olderThan(advisory?.last_verified_at, staleMs);

  let needsVisa = false;
  if (usId && country.id !== usId) {
    const { data: visa } = await supabase
      .from("visa_requirements")
      .select("last_verified_at")
      .eq("destination_country_id", country.id)
      .eq("nationality_country_id", usId)
      .maybeSingle();
    needsVisa = olderThan(visa?.last_verified_at, staleMs);
  }

  if (!needsAdvisory && !needsVisa) return respond({ refreshed: false, reason: "fresh" });

  // Stamped before fetching so concurrent visits don't double-fetch.
  await supabase
    .from("state_dept_refresh_attempts")
    .upsert({ country_id: country.id, attempted_at: new Date().toISOString() });

  const log: string[] = [];
  let advisoryResult: string | null = null;
  let visaResult: string | null = null;

  // The advisories feed covers every country in one request, so this
  // also refreshes every other country's advisory as a side effect.
  if (needsAdvisory) {
    try {
      const { ok } = await refreshAdvisories(supabase, countryRows, log);
      advisoryResult = ok > 0 ? "ok" : "noRows";
    } catch (err) {
      advisoryResult = `fetchFailed: ${(err as Error).message}`;
    }
  }

  if (needsVisa && usId) {
    if (needsAdvisory) await sleep(DEFAULT_REQUEST_DELAY_MS);
    // The visa row cites the advisory's Link, read after any refresh above.
    const { data: link } = await supabase
      .from("travel_advisories")
      .select("official_url")
      .eq("country_id", country.id)
      .eq("issuing_authority", ISSUING_AUTHORITY)
      .maybeSingle();
    try {
      visaResult = await refreshUsVisa(supabase, country, usId, link?.official_url, countryRows);
    } catch (err) {
      visaResult = `fetchFailed: ${(err as Error).message}`;
    }
  }

  return respond({ refreshed: true, advisory: advisoryResult, visa: visaResult, log });
});
