// Forin: leadership importer (Tier A, added 2026-08-26)
//
// Fills country_leadership from Wikidata, batched to stay well inside
// WDQS's timeout. Two passes, not one — confirmed empirically 2026-08-26:
// joining country -> head of government/state -> ALL their P39 "position
// held" statements in a single query times out WDQS once a batch gets much
// past ~10 countries (the person->positions fan-out is what's expensive,
// not the country->leader lookup). Splitting into (1) a fast batched
// country->leader query and (2) a separate batched leader->positions
// query keyed directly on the resulting QIDs (no country join) keeps each
// pass under ~1s even for 100+ countries/leaders at once.
//
// Approach:
//   - wdt:P297 maps ISO 3166-1 alpha-2 -> Wikidata QID (no crosswalk table
//     needed — sidesteps the "identity/linking mismatch" discrepancy class
//     documented in forin-data-architecture.md (docs/forin-data-architecture.md from repo root)).
//   - Head of government (P6) is primary; head of state (P35) is the
//     fallback for countries with no separate head of government (e.g.
//     absolute monarchies).
//   - Only statements with no end-time qualifier (pq:P582) are considered
//     — keeps results to the *current* office holder, not every past one.
//   - `title` (the country-specific term: "Prime Minister", "President",
//     "Chancellor", ...) doesn't come cleanly out of a single property: a
//     leader's P39 includes every position they hold (party leader,
//     parliament seat, etc.), not just the head-of-government one. Pass 2
//     fetches all of them; TITLE_KEYWORDS below picks the best match.
//     Countries where nothing matches confidently are flagged in the run
//     summary for manual review rather than written with a guessed title —
//     per the doc: dropping the field beats showing a wrong one.
//
// Requires Node 18+ (built-in fetch) and @supabase/supabase-js.
//
// Setup: same as import-commodity-data.mjs — SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY in .env.scripts.
//
// Run:
//   node tools/commodity_importer/fetch_leadership.mjs             // writes to Supabase
//   node tools/commodity_importer/fetch_leadership.mjs --dry-run   // preview only

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
const LEADER_CHUNK_SIZE = 80; // country->leader pass, empirically ~1s at this size
const POSITION_CHUNK_SIZE = 80; // leader->positions pass, keyed on QIDs directly
const USER_AGENT = 'forin-commodity-importer/0.1 (leadership fetch; contact via project owner)';
const FETCH_TIMEOUT_MS = 30_000;
const MAX_RETRIES = 2;

// Checked top to bottom, first match wins. Generic government-leader
// titles, not party/parliament/ceremonial roles that also show up in P39.
const TITLE_KEYWORDS = [
  'President of the Pontifical Commission', // Vatican-specific, before generic 'President'
  'Federal Chancellor', 'Chancellor',
  'Prime Minister', 'Premier', 'Taoiseach', 'First Minister', 'Chief Minister',
  'President',
  'King', 'Queen', 'Emir', 'Sultan', 'Emperor', 'Empress',
  'Grand Duke', 'Grand Duchess', 'Prince', 'Princess',
  'Chairman of the', 'Governor-General', 'Captain Regent', 'Governor',
  'Head of Government', // late, generic fallback (e.g. Liechtenstein)
];

// A handful of English-label mismatches between a country entity's own
// Wikidata label and the label used inside position titles for the same
// country (both are independently-curated English labels, so they drift).
// Checked both directions in titleAnchorsToCountry below.
const COUNTRY_NAME_ALIASES = {
  'cape verde': 'cabo verde',
  'czech republic': 'czechia',
  'turkey': 'turkiye',
  'swaziland': 'eswatini',
  'macedonia': 'north macedonia',
  'ivory coast': "cote d'ivoire",
};

// Requires the position to genuinely be "<title> of <this country>", not
// just a title that happens to mention the country in passing. Confirmed
// necessary 2026-08-26: a loose "label includes countryName" check picked
// "President of La Libertad Avanza (Argentina)" (a party title) over the
// real "President of Argentina" for Argentina's leader, because both
// technically contain the string "Argentina". Taking the text after the
// LAST " of " (rather than the first) and requiring equality — not just a
// substring match — is what tells those two apart, and also correctly
// resolves multi-"of" titles like "Chairman of the Council of Ministers of
// Bosnia and Herzegovina" (the country is always the final segment).
function titleAnchorsToCountry(label, countryName) {
  if (!countryName) return false;
  const withoutParens = label.replace(/\([^)]*\)/g, ' ');
  const idx = withoutParens.toLowerCase().lastIndexOf(' of ');
  if (idx === -1) return false;
  const norm = (s) => {
    const base = s.toLowerCase().replace(/^\s*the\s+/, '').replace(/[.,'’]/g, '').trim();
    return COUNTRY_NAME_ALIASES[base] ?? base;
  };
  const tail = norm(withoutParens.slice(idx + 4));
  const country = norm(countryName);
  return tail === country || (COUNTRY_NAME_ALIASES[country] ?? country) === tail;
}

function pickTitle(positionLabels, countryName) {
  const anchored = positionLabels.filter((l) => titleAnchorsToCountry(l, countryName));
  for (const kw of TITLE_KEYWORDS) {
    const hit = anchored.find((l) => l.startsWith(kw) || l.includes(kw));
    if (hit) return { title: hit, confident: true };
  }
  return { title: null, confident: false };
}

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
      if (!res.ok) {
        const text = await res.text();
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 200)}`);
      }
      const json = await res.json();
      return json.results.bindings;
    } catch (e) {
      clearTimeout(timer);
      if (attempt === MAX_RETRIES) throw e;
      console.error(`  retrying after error: ${e.message}`);
      await new Promise((r) => setTimeout(r, 2000 * (attempt + 1)));
    }
  }
}

function buildLeaderQuery(isoCodes) {
  const values = isoCodes.map((c) => `"${c}"`).join(' ');
  return `
    SELECT ?iso ?countryLabel ?hog ?hogLabel ?hogStart ?hos ?hosLabel ?hosStart WHERE {
      VALUES ?iso { ${values} }
      OPTIONAL {
        ?country wdt:P297 ?iso .
        ?country p:P6 ?stmt .
        ?stmt ps:P6 ?hog .
        FILTER NOT EXISTS { ?stmt pq:P582 ?end }
        OPTIONAL { ?stmt pq:P580 ?hogStart }
      }
      OPTIONAL {
        ?country2 wdt:P297 ?iso .
        ?country2 p:P35 ?stmt2 .
        ?stmt2 ps:P35 ?hos .
        FILTER NOT EXISTS { ?stmt2 pq:P582 ?end2 }
        OPTIONAL { ?stmt2 pq:P580 ?hosStart }
      }
      BIND(COALESCE(?country, ?country2) AS ?ctry)
      SERVICE wikibase:label {
        bd:serviceParam wikibase:language "en".
        ?ctry rdfs:label ?countryLabel.
        ?hog rdfs:label ?hogLabel.
        ?hos rdfs:label ?hosLabel.
      }
    }`;
}

function buildPositionQuery(qids) {
  const values = qids.map((q) => `wd:${q}`).join(' ');
  return `
    SELECT ?leader ?positionLabel WHERE {
      VALUES ?leader { ${values} }
      ?leader p:P39 ?posstmt .
      ?posstmt ps:P39 ?position .
      FILTER NOT EXISTS { ?posstmt pq:P582 ?posend }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }`;
}

async function main() {
  console.error('Fetching countries...');
  const { data: countries, error } = await supabase.from('countries').select('id,name_common');
  if (error) throw error;
  console.error(`${countries.length} countries.`);

  // Pass 1: country -> leader (name, QID, start date, whether via head-of-state fallback)
  const byIso = {};
  for (const [idx, isoChunk] of chunk(countries.map((c) => c.id), LEADER_CHUNK_SIZE).entries()) {
    console.error(`Leader pass, chunk ${idx + 1}...`);
    let rows;
    try {
      rows = await sparql(buildLeaderQuery(isoChunk));
    } catch (e) {
      console.error(`  chunk ${idx + 1} failed after retries: ${e.message}`);
      continue;
    }
    for (const r of rows) {
      const iso = r.iso?.value;
      if (!iso) continue;
      const usingHog = !!r.hog;
      const leaderUri = usingHog ? r.hog?.value : r.hos?.value;
      const leaderLabel = usingHog ? r.hogLabel?.value : r.hosLabel?.value;
      const start = (usingHog ? r.hogStart?.value : r.hosStart?.value)?.slice(0, 10) ?? null;
      if (!leaderUri || !leaderLabel) continue;
      // Prefer head-of-government if we've already found one; don't let a
      // later head-of-state-only row overwrite it.
      if (byIso[iso] && byIso[iso].viaHog && !usingHog) continue;
      byIso[iso] = {
        countryName: r.countryLabel?.value ?? '',
        leaderName: leaderLabel,
        leaderQid: leaderUri.split('/').pop(),
        viaHog: usingHog,
        start,
      };
    }
  }

  const resolvedIsos = Object.keys(byIso);
  console.error(`Leader pass done: ${resolvedIsos.length}/${countries.length} countries have a current leader on Wikidata.`);

  // Pass 2: leader QID -> all currently-held positions (for title resolution)
  const allQids = [...new Set(resolvedIsos.map((iso) => byIso[iso].leaderQid))];
  const positionsByQid = {};
  for (const [idx, qidChunk] of chunk(allQids, POSITION_CHUNK_SIZE).entries()) {
    console.error(`Position pass, chunk ${idx + 1}...`);
    let rows;
    try {
      rows = await sparql(buildPositionQuery(qidChunk));
    } catch (e) {
      console.error(`  chunk ${idx + 1} failed after retries: ${e.message}`);
      continue;
    }
    for (const r of rows) {
      const qid = r.leader.value.split('/').pop();
      (positionsByQid[qid] ??= new Set()).add(r.positionLabel.value);
    }
  }

  const rowsToUpsert = [];
  const noLeaderFound = [];
  const lowConfidenceTitle = [];

  for (const c of countries) {
    const e = byIso[c.id];
    if (!e) {
      noLeaderFound.push(`${c.id} (${c.name_common})`);
      continue;
    }
    const positions = [...(positionsByQid[e.leaderQid] ?? [])];
    const { title, confident } = pickTitle(positions, e.countryName || c.name_common);
    if (!confident) {
      lowConfidenceTitle.push(`${c.id} (${c.name_common}) — leader: ${e.leaderName}, candidate positions: ${positions.join(' / ') || '(none)'}`);
      continue; // don't write a guessed title
    }
    rowsToUpsert.push({
      country_id: c.id,
      title,
      name: e.leaderName,
      since: e.start,
      source_url: `https://www.wikidata.org/wiki/${e.leaderQid}`,
      last_verified_at: new Date().toISOString(),
    });
  }

  console.error(`\n--- Summary ---`);
  console.error(`Resolved with confident title: ${rowsToUpsert.length}`);
  console.error(`No head of government/state found at all: ${noLeaderFound.length}`);
  console.error(`Leader found but title unresolved (needs manual review): ${lowConfidenceTitle.length}`);

  if (noLeaderFound.length) console.error(`\nNo leader found:\n  ${noLeaderFound.join('\n  ')}`);
  if (lowConfidenceTitle.length) console.error(`\nTitle unresolved (manual review needed):\n  ${lowConfidenceTitle.join('\n  ')}`);

  if (DRY_RUN) {
    console.error('\n--dry-run: not writing to Supabase. Sample of resolved rows:');
    console.error(JSON.stringify(rowsToUpsert.slice(0, 8), null, 2));
    return;
  }

  console.error(`\nUpserting ${rowsToUpsert.length} rows into country_leadership...`);
  const { error: upsertError } = await supabase
    .from('country_leadership')
    .upsert(rowsToUpsert, { onConflict: 'country_id' });
  if (upsertError) {
    console.error(`Upsert failed (${upsertError.message}), falling back to delete+insert...`);
    const isoList = rowsToUpsert.map((r) => r.country_id);
    const { error: delError } = await supabase.from('country_leadership').delete().in('country_id', isoList);
    if (delError) throw delError;
    const { error: insError } = await supabase.from('country_leadership').insert(rowsToUpsert);
    if (insError) throw insError;
  }
  console.error('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
