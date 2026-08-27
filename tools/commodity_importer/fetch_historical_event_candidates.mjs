// Whereabout: historical_events candidates (Tier B, added 2026-08-26 on
// the tier-b-content-candidates branch)
//
// Writes to content_candidates, NEVER to country_guides.historical_events
// directly — this is a draft queue, not a publish path. See migration 023
// and whereabout-data-architecture.md's "Reopened 2026-08-26" subsection.
//
// Source: Wikidata wdt:P793 ("significant event"), direct country->event
// statements — no expensive per-person fan-out like the leadership
// importer's P39 join hit, confirmed fast even in large batches (~0.4s for
// 38 countries live-tested 2026-08-26). One query per chunk is enough;
// no need for fetch_leadership.mjs's two-pass split.
//
// Each row's payload is {year, title} only — `why_it_matters` is exactly
// the judgment call this staging step exists for; it is never fetched,
// and a person writes it when promoting a candidate to a real
// country_guides.historical_events entry. No pruning of "is this
// traveler-relevant" happens here either — a raw query surfaces plenty of
// noise (the "Great Recession" turning up for both the US and Germany is
// the example already on record), and that filtering is exactly what
// review is for. This script only dedupes identical (country, event QID)
// pairs and sorts by date.
//
// Requires Node 18+ (built-in fetch) and @supabase/supabase-js.
// Setup: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.scripts.
//
// Run:
//   node tools/commodity_importer/fetch_historical_event_candidates.mjs
//   node tools/commodity_importer/fetch_historical_event_candidates.mjs --dry-run

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

config({ path: '.env.scripts', quiet: true });

const SUPABASE_URL = (process.env.SUPABASE_URL ?? '').replace(/\/+$/, '');
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.');
  process.exit(1);
}
const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

const DRY_RUN = process.argv.includes('--dry-run');
const CHUNK_SIZE = 100;
const USER_AGENT = 'whereabout-commodity-importer/0.1 (historical event candidates fetch)';
const FETCH_TIMEOUT_MS = 30_000;
const MAX_RETRIES = 2;
// Per-country cap so one heavily-documented country (the US, say) doesn't
// flood the review queue relative to everyone else — a person triaging
// candidates country by country shouldn't hit 80 rows for one and 2 for
// the next. Earliest-dated events first is an arbitrary but defensible
// cut; review can always pull more from Wikidata directly if wanted.
const MAX_EVENTS_PER_COUNTRY = 15;

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function sparql(query) {
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    try {
      const res = await fetch('https://query.wikidata.org/sparql?' + new URLSearchParams({ query, format: 'json' }), {
        headers: { Accept: 'application/sparql-results+json', 'User-Agent': USER_AGENT },
        signal: controller.signal,
      });
      clearTimeout(timer);
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
      return (await res.json()).results.bindings;
    } catch (e) {
      clearTimeout(timer);
      if (attempt === MAX_RETRIES) throw e;
      console.error(`  retrying after error: ${e.message}`);
      await new Promise((r) => setTimeout(r, 2000 * (attempt + 1)));
    }
  }
}

function buildQuery(isoCodes) {
  const values = isoCodes.map((c) => `"${c}"`).join(' ');
  return `
    SELECT ?iso ?event ?eventLabel ?date WHERE {
      VALUES ?iso { ${values} }
      ?country wdt:P297 ?iso .
      ?country wdt:P793 ?event .
      OPTIONAL { ?event wdt:P585 ?date }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }`;
}

async function main() {
  console.error('Fetching countries...');
  const { data: countries, error } = await supabase.from('countries').select('id');
  if (error) throw error;
  console.error(`${countries.length} countries.`);

  const byIso = {}; // iso -> Map(eventQid -> {title, year})
  for (const [idx, isoChunk] of chunk(countries.map((c) => c.id), CHUNK_SIZE).entries()) {
    console.error(`Chunk ${idx + 1}...`);
    let rows;
    try {
      rows = await sparql(buildQuery(isoChunk));
    } catch (e) {
      console.error(`  chunk ${idx + 1} failed after retries: ${e.message}`);
      continue;
    }
    for (const r of rows) {
      const iso = r.iso?.value;
      const qid = r.event?.value?.split('/').pop();
      const title = r.eventLabel?.value;
      // The label service falls back to the bare QID string when an event
      // has no English (or any) label — useless as a candidate title, so
      // skip rather than stage "Q18407458" for a person to puzzle over.
      if (!iso || !qid || !title || /^Q\d+$/.test(title)) continue;
      const year = r.date?.value ? Number(r.date.value.slice(0, 4)) : null;
      (byIso[iso] ??= new Map()).set(qid, { title, year, qid });
    }
  }

  const rowsToInsert = [];
  let totalBeforeCap = 0;
  for (const [iso, events] of Object.entries(byIso)) {
    const all = [...events.values()];
    totalBeforeCap += all.length;
    // Earliest first, undated events last (nulls sort after real years).
    all.sort((a, b) => (a.year ?? Infinity) - (b.year ?? Infinity));
    for (const e of all.slice(0, MAX_EVENTS_PER_COUNTRY)) {
      rowsToInsert.push({
        country_id: iso,
        candidate_type: 'historical_event',
        source: 'wikidata',
        source_url: `https://www.wikidata.org/wiki/${e.qid}`,
        payload: { year: e.year, title: e.title },
        status: 'pending',
        fetched_at: new Date().toISOString(),
      });
    }
  }

  console.error(`\n--- Summary ---`);
  console.error(`Countries with at least one candidate event: ${Object.keys(byIso).length}/${countries.length}`);
  console.error(`Total candidate events found: ${totalBeforeCap} (before per-country cap of ${MAX_EVENTS_PER_COUNTRY})`);
  console.error(`Rows to stage: ${rowsToInsert.length}`);

  if (DRY_RUN) {
    console.error('\n--dry-run: not writing to Supabase. Sample:');
    console.error(JSON.stringify(rowsToInsert.slice(0, 8), null, 2));
    return;
  }

  console.error(`\nInserting ${rowsToInsert.length} candidate rows (batches of 500)...`);
  // Plain insert, not upsert — content_candidates has no natural unique
  // key across runs (a candidate can legitimately be re-fetched and
  // re-reviewed). Re-running this without clearing old pending rows first
  // will duplicate; that's a deliberate simplicity trade-off for a
  // human-reviewed queue, not an oversight — clear old 'pending' rows for
  // a country manually before re-running if that's ever a problem.
  for (let i = 0; i < rowsToInsert.length; i += 500) {
    const batch = rowsToInsert.slice(i, i + 500);
    const { error: insertError } = await supabase.from('content_candidates').insert(batch);
    if (insertError) throw insertError;
  }
  console.error('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
