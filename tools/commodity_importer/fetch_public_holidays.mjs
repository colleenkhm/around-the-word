// Whereabout: public holidays importer (Tier A, added 2026-08-26)
//
// Source: Nager.Date. CLAUDE.md's original note said "build against v4
// from day one" (v3 EOL 2027-01-31, v4 supposedly shipped 2026-06-30) —
// confirmed live 2026-08-26 that's not accurate: api.nager.at/api/v4/*
// returns 404 across the board, and /api/v3/AvailableCountries responds
// normally with `api-supported-versions: 3.0`. Only v3 actually exists
// right now. Building against v3 for that reason (this importer is easy
// to repoint at v4 later — a base-path change only, since AvailableCountries
// showed no other obvious v3/v4 field differences to plan around yet), but
// the EOL date is real: **re-check this before 2027-01-31.**
//
// Fetches the current calendar year plus the next one (so a holiday late
// in the year doesn't look stale for the first ~11 months of the next),
// for every country Nager.Date covers that also exists in our `countries`
// table (204/250 at last check — mostly independent UN member states;
// most non-covered rows are territories/dependencies Nager.Date doesn't
// track, a real source-coverage gap, not a bug).
//
// `is_national`: Nager's `global` field (true = whole country, false =
// specific subdivisions only, listed in `counties`). Deliberately NOT a
// source for country_guides.festivals — see whereabout-data-architecture.md
// and CLAUDE.md's External Data Sources section for why those stay separate
// concepts (a bank holiday isn't a named event worth planning a trip
// around).
//
// Requires Node 18+ (built-in fetch) and @supabase/supabase-js.
// Setup: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.scripts.
//
// Run:
//   node tools/commodity_importer/fetch_public_holidays.mjs
//   node tools/commodity_importer/fetch_public_holidays.mjs --dry-run
//   node tools/commodity_importer/fetch_public_holidays.mjs --years=2026,2027

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
const yearsArg = process.argv.find((a) => a.startsWith('--years='));
const currentYear = new Date().getFullYear();
const YEARS = yearsArg ? yearsArg.split('=')[1].split(',').map(Number) : [currentYear, currentYear + 1];
const BASE_URL = 'https://date.nager.at/api/v3';
const USER_AGENT = 'whereabout-commodity-importer/0.1 (public holidays fetch)';
const REQUEST_DELAY_MS = 150; // polite pacing; Nager.Date has no documented hard rate limit

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.error('Fetching countries + available Nager.Date countries...');
  const { data: countries, error } = await supabase.from('countries').select('id');
  if (error) throw error;
  const knownIsoCodes = new Set(countries.map((c) => c.id));

  const availRes = await fetch(`${BASE_URL}/AvailableCountries`, { headers: { 'User-Agent': USER_AGENT } });
  if (!availRes.ok) throw new Error(`AvailableCountries failed: HTTP ${availRes.status}`);
  const available = await availRes.json(); // [{countryCode, name}, ...]
  const codesToFetch = available.map((c) => c.countryCode).filter((c) => knownIsoCodes.has(c));
  console.error(`Nager.Date covers ${available.length} countries; ${codesToFetch.length} match our countries table.`);
  const notInOurs = available.map((c) => c.countryCode).filter((c) => !knownIsoCodes.has(c));
  if (notInOurs.length) console.error(`  (covered by Nager but not in our countries table: ${notInOurs.join(', ')})`);

  const rowsToUpsert = [];
  const failedCodes = [];
  for (const code of codesToFetch) {
    for (const year of YEARS) {
      try {
        const res = await fetch(`${BASE_URL}/PublicHolidays/${year}/${code}`, { headers: { 'User-Agent': USER_AGENT } });
        if (res.status === 204) continue; // no content for this country/year
        if (!res.ok) { failedCodes.push(`${code} ${year} (HTTP ${res.status})`); continue; }
        const holidays = await res.json();
        for (const h of holidays) {
          rowsToUpsert.push({
            country_id: code,
            date: h.date,
            local_name: h.localName,
            name: h.name,
            is_national: !!h.global,
            holiday_type: Array.isArray(h.types) ? h.types[0] : null,
            source: 'nager.date',
            last_imported_at: new Date().toISOString(),
          });
        }
      } catch (e) {
        failedCodes.push(`${code} ${year} (${e.message})`);
      }
      await sleep(REQUEST_DELAY_MS);
    }
  }

  console.error(`\n--- Summary ---`);
  console.error(`Countries fetched: ${codesToFetch.length}, years: ${YEARS.join(', ')}`);
  console.error(`Holiday rows resolved: ${rowsToUpsert.length}`);
  console.error(`Failed fetches: ${failedCodes.length}`);
  if (failedCodes.length) console.error(`  ${failedCodes.join('\n  ')}`);

  if (DRY_RUN) {
    console.error('\n--dry-run: not writing to Supabase. Sample:');
    console.error(JSON.stringify(rowsToUpsert.slice(0, 5), null, 2));
    return;
  }

  console.error(`\nUpserting ${rowsToUpsert.length} rows into public_holidays (batches of 500)...`);
  for (let i = 0; i < rowsToUpsert.length; i += 500) {
    const batch = rowsToUpsert.slice(i, i + 500);
    const { error: upsertError } = await supabase
      .from('public_holidays')
      .upsert(batch, { onConflict: 'country_id,date,name' });
    if (upsertError) throw upsertError;
  }
  console.error('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
