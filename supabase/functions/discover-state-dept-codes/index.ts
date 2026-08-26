// Whereabout: state_dept_entry_exit_code discovery — Edge Function
//
// Run this when a common, common-as-Japan-common destination has no visa
// summary — it means cadataapi.state.gov's entry_exit_requirements
// endpoint uses a code for that country other than its ISO alpha-2 (that
// endpoint is keyed closer to FIPS 10-4; see countries.state_dept_entry_
// exit_code's column comment and HANDOFF.md 2026-08-21/2026-08-24 for the
// full history). This is the reusable, server-side version of what used
// to be a throwaway local Node script written fresh each session
// (discover-visa-country-codes.mjs, discover-visa-codes-fullspace.mjs,
// both deleted after use, per the project's one-off-script convention) —
// rebuilding that from scratch each time this gap needed closing was the
// actual inefficiency this function exists to remove.
//
// What it does NOT do: write anything. countries.state_dept_entry_exit_
// code and visa_requirements only ever get written by a human reading
// this function's output and (a) adding a verified pair to a new
// migration file, same pattern as migrations 008/009/011/012, then (b)
// letting refresh-state-dept-data's normal upsert path pick it up. That
// split is deliberate, not a missing feature: this project has hit real,
// concrete false positives from trusting a name-match without a human
// actually reading the returned text (Switzerland matched to Iran's
// content because Switzerland is the U.S.'s protecting power there;
// Armenia matched under a code meant for Azerbaijan because of their
// adversarial relationship) — automating the write step would automate
// past that safety check, not around a limitation of it.
//
// Efficiency, concretely, vs. the one-off-script approach it replaces:
//   - "Already tried" codes (iso_code ∪ existing state_dept_entry_exit_
//     code overrides) are computed fresh from the DB every call, never
//     hardcoded — a script written today doesn't know about overrides
//     found tomorrow, this does automatically.
//   - Only checks countries actually missing a visa summary by default
//     (visa_requirements.summary is null), not the full country list —
//     narrows what has to match, not just what gets requested.
//   - A real HTTP 429 gets a genuine backoff-and-retry (see
//     fetchJsonWithBackoff in ../_shared/state-dept.ts) instead of just
//     failing — added after the 2026-08-24 sweep tripped a real
//     Cloudflare rate-limit challenge mid-run and had to be manually
//     noticed and paused.
//   - Batched (?batchStart=&batchSize=) over a stable, alphabetically-
//     sorted candidate list, the same idle-timeout-driven pattern
//     refresh-state-dept-data already uses for its visa batches, so a
//     full sweep is a few scripted calls instead of a bespoke run.
//
// Call it like (all query params optional):
//   POST .../discover-state-dept-codes
//   POST .../discover-state-dept-codes?batchStart=0&batchSize=40
//   POST .../discover-state-dept-codes?countries=JP,MX,RU   (targeted, skips the "missing" query)
//   POST .../discover-state-dept-codes?includeAll=true      (check every country, not just missing ones — a full re-verification, not the normal case)
//   POST .../discover-state-dept-codes?codes=UK,SP,SW       (test specific candidate codes instead of sweeping the alphabet — see the codes/allCodes comment below)
//
// Response: { alreadyTriedCount, targetCount, candidateCount, batch:
// {start,end}, results: [{code, isoCode, destination, mentionCount,
// runnerUp, preview}], log }, results sorted strongest-match first.
// Matching (see findBestCountryMatch in ../_shared/state-dept.ts): every
// country's name is raced for mention count against each fetched
// response, and a result is only surfaced if one of our *target*
// countries wins that race outright — replaced an earlier "target name
// in the first 250 characters, or an exact 'Embassy of X' phrase" bar
// 2026-08-25 after it missed Portugal (real content, just doesn't name
// Portugal up front) while still needing to reject the same kind of
// false positive that bar was built to catch (Switzerland losing badly
// to Iran on Iran's own real page). `results` is still candidates for a
// human to verify by reading `preview` in full (not just trust
// mentionCount) before writing a migration — same bar as every prior
// discovery round.
//
// ?mode=diagnose — a second, separate mode added 2026-08-25 after a
// manual investigation (Mexico, Portugal, Kyrgyzstan) turned out to be
// three genuinely different root causes, not one: a missing
// travel_advisories row (no official_url to cite at all — Mexico), a
// working code whose response the matcher was too strict to recognize
// (Kyrgyzstan's real content says "Kyrgyz Republic" — fixed permanently
// by textMentionsCountry, not something a rerun of THIS discovery mode
// would ever have caught since it only searches for *new* codes), and a
// genuine FIPS-style wrong/empty code (Portugal). Sweep mode (above)
// only ever answers "is there some other code that works" — it can't
// tell you *why* a country is missing, which is what made the manual
// classification necessary in the first place. Diagnose mode answers
// that directly, one fetch per target (its own current code only, not
// the alpha space), and sorts every target into exactly one bucket:
//   - no_advisory_link: blocked before any fetch — no travel_advisories.
//     official_url to cite. Not a code problem; needs an advisories fix.
//   - code_returns_empty: own code (override ?? iso_code) returns no
//     usable content at all. A real FIPS-style gap — needs sweep mode.
//   - code_misrouted: own code returns real content, but for a
//     *different* country (the misroutedTo field says which). Also
//     needs sweep mode to find the right code.
//   - fixable_by_matcher: own code already returns genuinely correct
//     content — refresh-state-dept-data's normal upsert should succeed
//     next time it runs for this country. No further discovery needed,
//     just a normal refresh.
//   - unclear: content exists but no country wins the mention race
//     clearly (very short/generic response) — needs a human to read it.
// Call it like: POST .../discover-state-dept-codes?mode=diagnose
//   (same ?countries=/?includeAll=/?batchStart=/?batchSize= params apply,
//   batching over targets instead of codes in this mode)

import { createClient } from "npm:@supabase/supabase-js@2";
import { BASE_URL, DEFAULT_REQUEST_DELAY_MS, fetchJsonWithBackoff, findBestCountryMatch, sleep, stripHtml } from "../_shared/state-dept.ts";

interface CountryRow {
  id: string;
  iso_code: string;
  name_common: string;
  state_dept_entry_exit_code: string | null;
}

const REQUEST_DELAY_MS = DEFAULT_REQUEST_DELAY_MS;
// Lower default batch than refresh-state-dept-data's visa batches — most
// codes probed here return nothing usable for any missing country, and a
// 429 backoff can now burn up to ~55s on a single code (see
// RATE_LIMIT_BACKOFF_MS in ../_shared/state-dept.ts), so a smaller batch
// keeps a worst-case run safely under Supabase's 150s Edge Function idle
// limit rather than assuming the happy path. Lowered from 40 to 25
// 2026-08-25 alongside the pacing changes above, same reasoning.
const DEFAULT_BATCH_SIZE = 25;
// Cap on the preview text handed back for review — enough to judge intent
// (the false positives found so far, e.g. Switzerland/Iran, are visible
// well within this) without the response ballooning across a 40-code batch.
const PREVIEW_MAX_CHARS = 400;

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const batchStart = Number(url.searchParams.get("batchStart") ?? 0);
  const batchSize = Number(url.searchParams.get("batchSize") ?? DEFAULT_BATCH_SIZE);
  const requestedCodes = url.searchParams.get("countries");
  const includeAll = url.searchParams.get("includeAll") === "true";

  const log: string[] = [];

  const { data: countries, error: countriesError } = await supabase
    .from("countries")
    .select("id, iso_code, name_common, state_dept_entry_exit_code");
  if (countriesError) {
    return new Response(JSON.stringify({ error: countriesError.message }), { status: 500 });
  }
  const countryRows = (countries ?? []) as CountryRow[];
  // Excluded from the mention-count race specifically (not from anything
  // else countryRows is used for) — found live 2026-08-25: every
  // entry_exit_requirements page is inherently written about "U.S.
  // citizens" traveling FROM the United States, so "United States"
  // mentions are structural boilerplate on nearly every response, not a
  // signal of which destination the page is actually about. Without this,
  // a generic/low-content response can spuriously "win" for the US
  // itself over the real destination (or over nothing at all).
  const raceableCountries = countryRows.filter((c) => c.iso_code !== "US");

  // Target set: which destinations we're trying to find a code for.
  let targets: CountryRow[];
  if (requestedCodes) {
    const wanted = new Set(requestedCodes.split(",").map((c) => c.trim().toUpperCase()));
    targets = countryRows.filter((c) => wanted.has(c.iso_code));
  } else if (includeAll) {
    targets = countryRows.filter((c) => c.iso_code !== "US");
  } else {
    const { data: visaRows, error: visaError } = await supabase
      .from("visa_requirements")
      .select("destination_country_id, summary")
      .eq("nationality_country_id", "US");
    if (visaError) {
      return new Response(JSON.stringify({ error: visaError.message }), { status: 500 });
    }
    const summaryByCountry = new Map((visaRows ?? []).map((r) => [r.destination_country_id, r.summary]));
    targets = countryRows.filter((c) => c.iso_code !== "US" && !summaryByCountry.get(c.id));
  }

  // ---------------------------------------------------------------
  // Diagnose mode — see file header. One fetch per target (its own
  // current code only), classifying *why* it has no visa data instead of
  // searching for a new code. Returns early; sweep mode below never runs.
  // ---------------------------------------------------------------
  if (url.searchParams.get("mode") === "diagnose") {
    const { data: advisoryRows, error: advisoryError } = await supabase
      .from("travel_advisories")
      .select("country_id, official_url")
      .eq("issuing_authority", "US State Department");
    if (advisoryError) {
      return new Response(JSON.stringify({ error: advisoryError.message }), { status: 500 });
    }
    const officialUrlByCountry = new Map(
      (advisoryRows ?? []).filter((r) => r.official_url).map((r) => [r.country_id, r.official_url as string])
    );

    const diagnoseBatch = targets.slice(batchStart, batchStart + batchSize);
    log.push(`Diagnosing ${diagnoseBatch.length} of ${targets.length} target(s) (batch ${batchStart}-${batchStart + diagnoseBatch.length}).`);

    type Diagnosis = {
      isoCode: string;
      destination: string;
      category: "no_advisory_link" | "code_returns_empty" | "code_misrouted" | "fixable_by_matcher" | "unclear";
      requestCode: string;
      misroutedTo: string | null;
      preview: string | null;
    };
    const diagnoses: Diagnosis[] = [];

    for (const country of diagnoseBatch) {
      if (!officialUrlByCountry.has(country.id)) {
        diagnoses.push({ isoCode: country.iso_code, destination: country.name_common, category: "no_advisory_link", requestCode: "", misroutedTo: null, preview: null });
        continue;
      }
      const requestCode = country.state_dept_entry_exit_code ?? country.iso_code;
      try {
        const data = await fetchJsonWithBackoff(`${BASE_URL}/CountryTravelInformation/${requestCode}/entry_exit_requirements`);
        const stripped = stripHtml(data);
        if (!stripped) {
          diagnoses.push({ isoCode: country.iso_code, destination: country.name_common, category: "code_returns_empty", requestCode, misroutedTo: null, preview: null });
        } else {
          const match = findBestCountryMatch(stripped, raceableCountries);
          if (!match) {
            diagnoses.push({ isoCode: country.iso_code, destination: country.name_common, category: "unclear", requestCode, misroutedTo: null, preview: stripped.slice(0, PREVIEW_MAX_CHARS) });
          } else if (match.winner.isoCode === country.iso_code) {
            diagnoses.push({ isoCode: country.iso_code, destination: country.name_common, category: "fixable_by_matcher", requestCode, misroutedTo: null, preview: stripped.slice(0, PREVIEW_MAX_CHARS) });
          } else {
            diagnoses.push({
              isoCode: country.iso_code,
              destination: country.name_common,
              category: "code_misrouted",
              requestCode,
              misroutedTo: `${match.winner.nameCommon} (${match.winner.isoCode}) x${match.winner.count}`,
              preview: stripped.slice(0, PREVIEW_MAX_CHARS),
            });
          }
        }
      } catch (err) {
        log.push(`${country.iso_code} (${requestCode}): ${(err as Error).message}`);
      }
      await sleep(REQUEST_DELAY_MS);
    }

    const byCategory: Record<string, number> = {};
    for (const d of diagnoses) byCategory[d.category] = (byCategory[d.category] ?? 0) + 1;

    return new Response(
      JSON.stringify(
        {
          targetCount: targets.length,
          batch: { start: batchStart, end: batchStart + diagnoseBatch.length },
          byCategory,
          diagnoses,
          log,
          ranAt: new Date().toISOString(),
        },
        null,
        2
      ),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  // Candidate codes: normally the full two-letter alpha space, minus
  // every code already known to resolve to *something* (every country's
  // own ISO code, plus every verified override already on file) —
  // re-probing those would just rediscover what migrations 008/009/011/
  // 012 (and whatever comes after) already settled. A blind alphabetical
  // sweep through all ~400 untried codes converges slowly, though (found
  // live 2026-08-25: ~75 codes checked for 4 real matches) — most of the
  // space belongs to nobody. `?codes=UK,SP,SW` skips the sweep and
  // checks exactly those codes instead, for testing a specific hypothesis
  // (e.g. a remembered FIPS 10-4 code for a specific still-missing
  // country) without paying for the whole alphabet — same verification
  // bar either way (still just returns candidates, still requires a human
  // to read `preview` before trusting), just a smarter search order than
  // A-Z when there's a real reason to expect a particular code.
  const requestedTestCodes = url.searchParams.get("codes");
  const alreadyTried = new Set<string>();
  for (const c of countryRows) {
    alreadyTried.add(c.iso_code);
    if (c.state_dept_entry_exit_code) alreadyTried.add(c.state_dept_entry_exit_code);
  }
  let allCodes: string[];
  if (requestedTestCodes) {
    allCodes = requestedTestCodes.split(",").map((c) => c.trim().toUpperCase()).filter(Boolean);
  } else {
    allCodes = [];
    for (let a = 65; a <= 90; a++) {
      for (let b = 65; b <= 90; b++) {
        const code = String.fromCharCode(a) + String.fromCharCode(b);
        if (!alreadyTried.has(code)) allCodes.push(code);
      }
    }
  }
  const batch = allCodes.slice(batchStart, batchStart + batchSize);
  log.push(
    `${targets.length} target destination(s), ${alreadyTried.size} codes already known, ` +
      `probing batch ${batchStart}-${batchStart + batch.length} of ${allCodes.length} ` +
      `${requestedTestCodes ? "requested" : "untried"} codes.`
  );

  const targetIsoCodes = new Set(targets.map((t) => t.iso_code));

  const results: Array<{
    code: string;
    isoCode: string;
    destination: string;
    mentionCount: number;
    runnerUp: string | null;
    preview: string;
  }> = [];

  for (const code of batch) {
    try {
      const data = await fetchJsonWithBackoff(`${BASE_URL}/CountryTravelInformation/${code}/entry_exit_requirements`);
      const stripped = stripHtml(data);
      if (stripped) {
        // findBestCountryMatch races EVERY country's name (not just the
        // targets) for mention count and returns whichever wins — see its
        // doc comment in ../_shared/state-dept.ts for why this replaces
        // the old "target's name in the first 250 chars, or an exact
        // 'Embassy of X' phrase" bar: that bar missed real matches
        // (Portugal's real content doesn't name Portugal up front) while
        // this one both catches those AND still rejects the false
        // positives found earlier (Switzerland losing the count race to
        // Iran on Iran's own real page). Only surfaced if the winner is
        // one of our targets — a code that clearly belongs to some
        // *other*, already-solved country isn't interesting here.
        const match = findBestCountryMatch(stripped, raceableCountries);
        if (match && targetIsoCodes.has(match.winner.isoCode)) {
          results.push({
            code,
            isoCode: match.winner.isoCode,
            destination: match.winner.nameCommon,
            mentionCount: match.winner.count,
            runnerUp: match.runnerUp ? `${match.runnerUp.nameCommon} (${match.runnerUp.isoCode}) x${match.runnerUp.count}` : null,
            preview: stripped.slice(0, PREVIEW_MAX_CHARS),
          });
        }
      }
    } catch (err) {
      log.push(`${code}: ${(err as Error).message}`);
    }
    await sleep(REQUEST_DELAY_MS);
  }
  // Strongest signal first — a big margin over the runner-up (or no
  // runner-up at all) is the easiest kind of result to trust on read;
  // anything with only 1-2 mentions or a close runner-up is still
  // included, just worth reading more carefully.
  results.sort((a, b) => b.mentionCount - a.mentionCount);

  return new Response(
    JSON.stringify(
      {
        alreadyTriedCount: alreadyTried.size,
        targetCount: targets.length,
        candidateCount: allCodes.length,
        batch: { start: batchStart, end: batchStart + batch.length },
        results,
        log,
        ranAt: new Date().toISOString(),
      },
      null,
      2
    ),
    { headers: { "Content-Type": "application/json" } }
  );
});
