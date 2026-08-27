// Whereabout: points_of_interest candidates (Tier B, added 2026-08-26 on
// the tier-b-content-candidates branch)
//
// Writes to content_candidates ONLY — never to points_of_interest
// directly. See migration 023 and whereabout-data-architecture.md's
// "Reopened 2026-08-26" subsection.
//
// Source: Wikivoyage's {{see}}/{{do}}/{{eat}}/{{drink}} listing templates
// on city articles — confirmed live 2026-08-26 (Lisbon/Alfama) to be
// genuinely structured: name/address/lat/long/hours/price/wikidata/content
// as named template fields, not prose to scrape. Template parsing is a
// depth-aware brace/bracket scan (see extractListings/splitFields below),
// not a naive regex split — confirmed necessary against real wikitext,
// where same-line fields ("| name=X | alt= | url=") and nested templates
// inside a value (a `directions=` field containing {{rint|bus}}) both
// break a simple split-on-pipe approach.
//
// Scope for this first run: the 12 personally-visited countries (see
// CLAUDE.md's Sequencing section — these are the ones that gate the
// build-start trigger, so real POI candidates for them are the most
// useful thing to have first), top 2 cities per country by
// is_featured-then-population. Pass --countries=ALL to run against every
// country with at least one row in `cities` instead.
//
// Known limitation, not solved this pass: large cities that split into
// district sub-articles (Lisbon/Alfama, Lisbon/Baixa, ...) have thin or
// empty top-level See/Do/Eat/Drink sections, with the real listings one
// level down. Handled with one fallback level — if a city's direct
// sections yield zero listings, the full article is scanned for
// "CityName/Something" sub-page links and up to 3 are fetched the same
// way — but this isn't a general crawler and won't find every district.
//
// Requires Node 18+ (built-in fetch) and @supabase/supabase-js.
// Setup: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.scripts.
//
// Run:
//   node tools/commodity_importer/fetch_poi_candidates.mjs
//   node tools/commodity_importer/fetch_poi_candidates.mjs --dry-run
//   node tools/commodity_importer/fetch_poi_candidates.mjs --countries=ALL

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
const countriesArg = process.argv.find((a) => a.startsWith('--countries='))?.split('=')[1];
const VISITED_COUNTRIES = ['US', 'GR', 'GB', 'IT', 'ES', 'IE', 'GT', 'NZ', 'ID', 'BR', 'DE', 'CA'];
const CITIES_PER_COUNTRY = 2;
const MAX_DISTRICT_FALLBACK = 3;
const API_BASE = 'https://en.wikivoyage.org/w/api.php';
const USER_AGENT = 'whereabout-commodity-importer/0.1 (POI candidates fetch; contact via project owner)';
const REQUEST_DELAY_MS = 800; // polite pacing against a shared public wiki API — raised from 400ms after a live 429 during testing
const SECTION_TO_TYPE = { see: 'landmark', do: 'activity', eat: 'restaurant', drink: 'restaurant' };

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

const MAX_RETRIES = 4;

// Confirmed live 2026-08-26: rapid back-to-back test runs against
// Wikivoyage's API got a real HTTP 429 — this is a shared public wiki, not
// a dedicated data API, so retry-with-backoff (honoring Retry-After when
// given) is the polite response, not just failing the city outright.
async function mwApi(params) {
  const url = `${API_BASE}?${new URLSearchParams({ format: 'json', ...params })}`;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    let res;
    try {
      res = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
    } catch (e) {
      // Transient network-level failures (ECONNRESET, socket closed, ...)
      // confirmed live 2026-08-27 on a long multi-request run — not rate
      // limiting, just an occasional dropped connection. Same retry
      // treatment as a 429 rather than letting the whole run die on one
      // flaky request.
      if (attempt === MAX_RETRIES) throw new Error(`Network error, retries exhausted: ${e.message}`);
      const waitMs = 2000 * (attempt + 1);
      console.error(`  network error (${e.message}), retrying in ${waitMs}ms...`);
      await sleep(waitMs);
      continue;
    }
    if (res.status === 429) {
      if (attempt === MAX_RETRIES) throw new Error('HTTP 429 (rate limited, retries exhausted)');
      const retryAfter = Number(res.headers.get('retry-after'));
      const waitMs = retryAfter > 0 ? retryAfter * 1000 : 3000 * (attempt + 1);
      console.error(`  rate limited, waiting ${waitMs}ms...`);
      await sleep(waitMs);
      continue;
    }
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  }
}

// Depth-aware split on '|' at brace/bracket depth 0 — a '|' inside
// {{...}} or [[...]] belongs to that nested markup, not a field boundary.
function splitFields(inner) {
  const chunks = [];
  let depth = 0;
  let current = '';
  for (let i = 0; i < inner.length; i++) {
    const two = inner.slice(i, i + 2);
    if (two === '{{' || two === '[[') { depth++; current += two; i++; continue; }
    if (two === '}}' || two === ']]') { depth--; current += two; i++; continue; }
    if (inner[i] === '|' && depth === 0) { chunks.push(current); current = ''; continue; }
    current += inner[i];
  }
  if (current) chunks.push(current);
  return chunks;
}

function extractListings(wikitext, templateNames) {
  const results = [];
  const namePattern = templateNames.join('|');
  const startRe = new RegExp(`\\{\\{\\s*(${namePattern})\\b`, 'gi');
  let m;
  while ((m = startRe.exec(wikitext))) {
    const openIdx = m.index;
    const templateType = m[1].toLowerCase();
    let depth = 0, i = openIdx, endIdx = -1;
    while (i < wikitext.length) {
      if (wikitext.startsWith('{{', i)) { depth++; i += 2; continue; }
      if (wikitext.startsWith('}}', i)) { depth--; i += 2; if (depth === 0) { endIdx = i; break; } continue; }
      i++;
    }
    if (endIdx === -1) { startRe.lastIndex = openIdx + 2; continue; }
    const inner = wikitext.slice(openIdx + 2, endIdx - 2);
    const nameEnd = inner.toLowerCase().indexOf(templateType) + templateType.length;
    const fieldChunks = splitFields(inner.slice(nameEnd)).slice(1);
    const fields = {};
    for (const chunk of fieldChunks) {
      const eq = chunk.indexOf('=');
      if (eq === -1) continue;
      const key = chunk.slice(0, eq).trim();
      if (key) fields[key] = chunk.slice(eq + 1).trim();
    }
    if (fields.name) results.push({ type: templateType, fields });
    startRe.lastIndex = endIdx;
  }
  return results;
}

function cleanWikitext(text) {
  if (!text) return null;
  let t = text;
  // Nested templates ({{EUR|15}}, {{rint|bus}}, ...) — drop the template
  // name, keep its raw args as plain text. Good enough for a review draft,
  // not meant to be a full wikitext renderer.
  for (let pass = 0; pass < 2; pass++) {
    t = t.replace(/\{\{([^{}]*)\}\}/g, (_, inner) => {
      const parts = inner.split('|');
      return parts.length > 1 ? parts.slice(1).join(' ') : '';
    });
  }
  t = t.replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, '$2');
  t = t.replace(/\[\[([^\]]+)\]\]/g, '$1');
  t = t.replace(/\[(https?:\/\/\S+)\s+([^\]]+)\]/g, '$2 ($1)');
  t = t.replace(/'''''|'''|''/g, '');
  t = t.replace(/\s+/g, ' ').trim();
  return t || null;
}

async function fetchSections(title) {
  const data = await mwApi({ action: 'parse', page: title, prop: 'sections', redirects: '1' });
  if (data.error) return null;
  return data.parse;
}

async function fetchSectionWikitext(title, sectionIndex) {
  const data = await mwApi({ action: 'parse', page: title, prop: 'wikitext', section: String(sectionIndex), redirects: '1' });
  if (data.error) return null;
  return data.parse.wikitext['*'];
}

async function fetchFullWikitext(title) {
  const data = await mwApi({ action: 'parse', page: title, prop: 'wikitext', redirects: '1' });
  if (data.error) return null;
  return data.parse.wikitext['*'];
}

// Confirmed live 2026-08-26: "New York" (our cities.name value) is a real
// Wikivoyage page, not a redirect, but it's not the city article either —
// the actual article is "New York City". redirects=1 doesn't help since
// there's no redirect involved, just two separate pages with similar
// names. Search's top result is the exact title already tried (itself),
// so this returns the first search result that ISN'T the title already
// attempted, rather than assuming result #1 is ever meaningfully
// different.
async function findAlternateTitle(originalTitle) {
  const data = await mwApi({ action: 'query', list: 'search', srsearch: originalTitle, srlimit: '5' });
  const results = data?.query?.search ?? [];
  const alt = results.find((r) => r.title !== originalTitle);
  return alt?.title ?? null;
}

// Zero direct listings on `resolvedTitle` — look for "ResolvedTitle/Something"
// sub-page links anywhere in the full article (Wikivoyage's convention for
// splitting a large city into districts, e.g. Lisbon/Alfama) and pull
// listings from up to MAX_DISTRICT_FALLBACK of them.
async function districtFallbackListings(resolvedTitle) {
  const fullText = await fetchFullWikitext(resolvedTitle);
  await sleep(REQUEST_DELAY_MS);
  if (!fullText) return [];
  const escaped = resolvedTitle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const linkRe = new RegExp(`\\[\\[(${escaped}/[^\\]|#]+)`, 'g');
  const districts = [...new Set([...fullText.matchAll(linkRe)].map((m) => m[1]))].slice(0, MAX_DISTRICT_FALLBACK);
  const found = [];
  for (const district of districts) {
    console.error(`    trying district ${district}...`);
    const districtResult = await listingsForPage(district);
    if (districtResult) found.push(...districtResult.listings);
  }
  return found;
}

// Collects listings from a city's own See/Do/Eat/Drink sections. Returns
// { listings, pageTitle } or null if the page doesn't exist at all.
async function listingsForPage(title) {
  const parsed = await fetchSections(title);
  await sleep(REQUEST_DELAY_MS);
  if (!parsed) return null;
  const resolvedTitle = parsed.title;
  const wanted = parsed.sections.filter((s) => ['see', 'do', 'eat', 'drink'].includes(s.line.toLowerCase()));
  const listings = [];
  for (const section of wanted) {
    const wikitext = await fetchSectionWikitext(resolvedTitle, section.index);
    await sleep(REQUEST_DELAY_MS);
    if (!wikitext) continue;
    const expectedType = section.line.toLowerCase();
    listings.push(...extractListings(wikitext, [expectedType]));
  }
  return { listings, resolvedTitle };
}

async function main() {
  console.error('Fetching cities...');
  let query = supabase.from('cities').select('country_id,name,population,is_major,is_featured');
  const countryFilter = countriesArg === 'ALL' ? null : countriesArg ? countriesArg.split(',') : VISITED_COUNTRIES;
  if (countryFilter) query = query.in('country_id', countryFilter);
  const { data: cities, error } = await query;
  if (error) throw error;

  const byCountry = {};
  for (const c of cities) (byCountry[c.country_id] ??= []).push(c);

  const rowsToInsert = [];
  const noPageFound = [];
  const zeroListingCities = [];
  let citiesFetched = 0;

  for (const [countryId, countryCities] of Object.entries(byCountry)) {
    const top = [...countryCities]
      .sort((a, b) => (b.is_featured ? 1 : 0) - (a.is_featured ? 1 : 0) || (b.population ?? 0) - (a.population ?? 0))
      .slice(0, CITIES_PER_COUNTRY);

    for (const city of top) {
      citiesFetched++;
      console.error(`Fetching ${city.name} (${countryId})...`);
      let result;
      try {
        result = await listingsForPage(city.name);
      } catch (e) {
        console.error(`  error: ${e.message}`);
        continue;
      }
      if (!result) { noPageFound.push(`${city.name} (${countryId})`); continue; }

      let { listings, resolvedTitle } = result;

      // District-split fallback: zero direct listings on the city's own
      // page — try its district sub-articles (Lisbon/Alfama, etc.).
      if (listings.length === 0) {
        console.error(`  no direct listings on "${resolvedTitle}"...`);
        listings.push(...(await districtFallbackListings(resolvedTitle)));
      }

      // Title-mismatch fallback: still nothing — this isn't a
      // district-split page, it's the wrong title entirely (e.g. "New
      // York" is a real but different page from "New York City"). Search
      // for an alternate title and retry the same direct + district
      // attempt on it.
      if (listings.length === 0) {
        const altTitle = await findAlternateTitle(city.name);
        await sleep(REQUEST_DELAY_MS);
        if (altTitle) {
          console.error(`  trying alternate title "${altTitle}"...`);
          const altResult = await listingsForPage(altTitle);
          if (altResult) {
            listings = altResult.listings;
            resolvedTitle = altResult.resolvedTitle;
            if (listings.length === 0) listings.push(...(await districtFallbackListings(resolvedTitle)));
          }
        }
      }

      if (listings.length === 0) { zeroListingCities.push(`${city.name} (${countryId})`); continue; }

      for (const l of listings) {
        const f = l.fields;
        rowsToInsert.push({
          country_id: countryId,
          candidate_type: 'poi',
          source: 'wikivoyage',
          source_url: `https://en.wikivoyage.org/wiki/${encodeURIComponent(resolvedTitle.replace(/ /g, '_'))}`,
          payload: {
            poi_type: SECTION_TO_TYPE[l.type],
            tags: l.type === 'drink' ? 'bar' : null,
            name: cleanWikitext(f.alt) || f.name,
            city_name: city.name,
            description: cleanWikitext(f.content),
            latitude: f.lat ? Number(f.lat) : null,
            longitude: f.long ? Number(f.long) : null,
            // Reference-only fields for the human reviewer — not
            // points_of_interest columns, don't get promoted verbatim.
            hours_ref: cleanWikitext(f.hours),
            price_ref: cleanWikitext(f.price),
            address_ref: cleanWikitext(f.address),
            url_ref: f.url || null,
            wikidata_ref: f.wikidata || null,
          },
          status: 'pending',
          fetched_at: new Date().toISOString(),
        });
      }
    }
  }

  console.error(`\n--- Summary ---`);
  console.error(`Cities attempted: ${citiesFetched}`);
  console.error(`No Wikivoyage page found: ${noPageFound.length}`);
  if (noPageFound.length) console.error(`  ${noPageFound.join('\n  ')}`);
  console.error(`Page found but zero listings (even after district fallback): ${zeroListingCities.length}`);
  if (zeroListingCities.length) console.error(`  ${zeroListingCities.join('\n  ')}`);
  console.error(`Candidate POIs staged: ${rowsToInsert.length}`);
  const byType = {};
  for (const r of rowsToInsert) byType[r.payload.poi_type] = (byType[r.payload.poi_type] ?? 0) + 1;
  console.error(`  by poi_type: ${JSON.stringify(byType)}`);

  if (DRY_RUN) {
    console.error('\n--dry-run: not writing to Supabase. Sample:');
    console.error(JSON.stringify(rowsToInsert.slice(0, 5), null, 2));
    return;
  }

  console.error(`\nInserting ${rowsToInsert.length} candidate rows...`);
  for (let i = 0; i < rowsToInsert.length; i += 500) {
    const { error: insertError } = await supabase.from('content_candidates').insert(rowsToInsert.slice(i, i + 500));
    if (insertError) throw insertError;
  }
  console.error('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
