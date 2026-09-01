// Forin: Global Affairs Canada advisories — second issuing authority
// for travel_advisories (Tier A, added 2026-08-26).
//
// Source: data.international.gc.ca/travel-voyage/index-updated.json — a
// clean, keyed-by-ISO-alpha-2 JSON feed, no key, no bot detection (unlike
// the State Dept API). Confirmed live 2026-08-26: 230 countries, each
// shaped like:
//   { "country-iso": "AF", "advisory-state": 3,
//     "date-published": { "date": "2026-07-29 14:31:46" },
//     "eng": { "url-slug": "afghanistan", "advisory-text": "Avoid all travel" } }
//
// `advisory-state` is 0-indexed (confirmed by cross-checking every
// distinct (state, text) pair in the live feed): 0 = normal precautions,
// 1 = high degree of caution, 2 = avoid non-essential travel, 3 = avoid
// all travel. Mapped to `Level ${state + 1}` so it reads consistently
// alongside the State Dept rows already in the same table (both show as
// "Level N" with their own issuer's level_label alongside).
//
// This is the multi-authority case the schema was built for: a country
// can now carry both a "US State Department" and a "Global Affairs
// Canada" row side by side, exactly as forin-data-architecture.md (docs/forin-data-architecture.md from repo root)'s
// travel_advisories section describes ("multiple rows per country are
// expected and desirable").
//
// Country matching is direct ISO-alpha-2 -> countries.id, no name-matching
// mess like the State Dept importer needs — this feed's country-iso
// values line up with our schema's join key already.
//
// Requires Node 18+ (built-in fetch) and @supabase/supabase-js.
// Setup: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.scripts.
//
// Run:
//   node tools/commodity_importer/fetch_global_affairs_canada.mjs
//   node tools/commodity_importer/fetch_global_affairs_canada.mjs --dry-run

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
const FEED_URL = 'https://data.international.gc.ca/travel-voyage/index-updated.json';
const USER_AGENT = 'forin-commodity-importer/0.1 (Global Affairs Canada advisories fetch)';

function toIsoDate(gacDate) {
  // "2026-07-29 14:31:46" -> "2026-07-29"
  if (!gacDate) return null;
  const m = gacDate.match(/^\d{4}-\d{2}-\d{2}/);
  return m ? m[0] : null;
}

async function main() {
  console.error(`Fetching ${FEED_URL} ...`);
  const res = await fetch(FEED_URL, { headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' } });
  if (!res.ok) throw new Error(`Feed fetch failed: HTTP ${res.status}`);
  const feed = await res.json();
  const entries = Object.values(feed.data ?? {});
  console.error(`Feed has ${entries.length} country entries (generated ${feed.metadata?.generated?.date ?? 'unknown time'}).`);

  console.error('Fetching countries...');
  const { data: countries, error } = await supabase.from('countries').select('id');
  if (error) throw error;
  const knownIsoCodes = new Set(countries.map((c) => c.id));

  const rowsToUpsert = [];
  const unmatched = [];
  for (const entry of entries) {
    const iso = entry['country-iso'];
    if (!knownIsoCodes.has(iso)) {
      unmatched.push(`${iso} (${entry.eng?.name ?? '?'})`);
      continue;
    }
    const state = entry['advisory-state'];
    const text = entry.eng?.advisoryText ?? entry.eng?.['advisory-text'];
    const slug = entry.eng?.['url-slug'];
    if (state === undefined || !text || !slug) continue;
    rowsToUpsert.push({
      country_id: iso,
      issuing_authority: 'Global Affairs Canada',
      level: `Level ${state + 1}`,
      level_label: text,
      summary: null, // feed gives no prose beyond the level_label itself
      official_url: `https://travel.gc.ca/destinations/${slug}`,
      issued_at: toIsoDate(entry['date-published']?.date),
      last_verified_at: new Date().toISOString(),
    });
  }

  console.error(`\n--- Summary ---`);
  console.error(`Resolved: ${rowsToUpsert.length}`);
  console.error(`Feed entries with no matching country_id (territories/naming, not yet reconciled): ${unmatched.length}`);
  if (unmatched.length) console.error(`  ${unmatched.join('\n  ')}`);

  if (DRY_RUN) {
    console.error('\n--dry-run: not writing to Supabase. Sample:');
    console.error(JSON.stringify(rowsToUpsert.slice(0, 5), null, 2));
    return;
  }

  console.error(`\nUpserting ${rowsToUpsert.length} rows into travel_advisories...`);
  const { error: upsertError } = await supabase
    .from('travel_advisories')
    .upsert(rowsToUpsert, { onConflict: 'country_id,issuing_authority' });
  if (upsertError) throw upsertError;
  console.error('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
