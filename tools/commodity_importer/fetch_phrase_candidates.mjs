// Whereabout: phrase candidates (Tier B, added 2026-08-26 on the
// tier-b-content-candidates branch)
//
// Writes to content_candidates ONLY — never to phrases directly. See
// migration 023 and whereabout-data-architecture.md's "Reopened
// 2026-08-26" subsection.
//
// Source: Wikivoyage phrasebook pages ("Greek phrasebook", "Portuguese
// phrasebook", ...). Confirmed live 2026-08-26: entries use MediaWiki
// definition-list syntax, one line each —
//   ; English prompt (''context''): Foreign translation (''pronunciation'', /IPA/)
// — parseable with a per-line regex, not a template scan like the POI
// fetcher needed. Real (not hypothetical) edge case found during testing:
// a translation with its own parenthetical aside before the pronunciation
// group (Greek's "Fine, thank you. (And you?)" entry) can make the
// pronunciation/IPA extraction miss — left as a known gap for human review
// to catch rather than over-fitting the regex to one observed case.
//
// A phrasebook page is per-LANGUAGE; `phrases` is per-COUNTRY (see the
// data architecture doc's "Curated: language content" section — Mexico
// and Argentina both get Spanish content, separately, because usage
// differs). This script is run once per (country, language) pair even
// when the language is shared (Spain and Guatemala both fetch the
// generic "Spanish phrasebook" source, staged under their own
// country_id) — a person still checks regional fit per country, same as
// any other Tier B candidate.
//
// Country -> phrasebook title mapping is explicit below, not derived from
// country_languages automatically — Wikivoyage has real per-country
// phrasebook variants for some languages (a "Brazilian Portuguese
// phrasebook" distinct from generic "Portuguese phrasebook", confirmed
// live) that a generic "<language name> phrasebook" guess would miss.
//
// Requires Node 18+ (built-in fetch) and @supabase/supabase-js.
// Setup: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.scripts.
//
// Run:
//   node tools/commodity_importer/fetch_phrase_candidates.mjs
//   node tools/commodity_importer/fetch_phrase_candidates.mjs --dry-run
//   node tools/commodity_importer/fetch_phrase_candidates.mjs --countries=GR,DE

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

// country_id -> { languageIso, phrasebookTitle }. Explicit, not derived —
// see file header on why (per-country phrasebook variants exist).
const COUNTRY_PHRASEBOOKS = {
  GR: { languageIso: 'el', title: 'Greek phrasebook' },
  IT: { languageIso: 'it', title: 'Italian phrasebook' },
  ES: { languageIso: 'es', title: 'Spanish phrasebook' },
  GT: { languageIso: 'es', title: 'Spanish phrasebook' },
  IE: { languageIso: 'ga', title: 'Irish phrasebook' },
  NZ: { languageIso: 'mi', title: 'Māori phrasebook' },
  ID: { languageIso: 'id', title: 'Indonesian phrasebook' },
  BR: { languageIso: 'pt', title: 'Brazilian Portuguese phrasebook' },
  DE: { languageIso: 'de', title: 'German phrasebook' },
};

const API_BASE = 'https://en.wikivoyage.org/w/api.php';
const USER_AGENT = 'whereabout-commodity-importer/0.1 (phrase candidates fetch; contact via project owner)';
const REQUEST_DELAY_MS = 800;
const MAX_RETRIES = 4;

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function mwApi(params) {
  const url = `${API_BASE}?${new URLSearchParams({ format: 'json', ...params })}`;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    let res;
    try {
      res = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
    } catch (e) {
      // Transient network-level failures (ECONNRESET, socket closed, ...)
      // confirmed live 2026-08-27 on a long multi-request run (German
      // phrasebook, ~20 subsection fetches) — not rate limiting, just an
      // occasional dropped connection. Same retry treatment as a 429
      // rather than letting the whole run die on one flaky request.
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

function cleanInline(t) {
  if (!t) return null;
  t = t.replace(/'''''|'''|''/g, '');
  t = t.replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, '$2').replace(/\[\[([^\]]+)\]\]/g, '$1');
  t = t.replace(/\{\{[^{}]*\}\}/g, '');
  return t.trim() || null;
}

// Pulls (pronunciation) and /ipa/ out of a definition string's first
// parenthetical group; everything before that paren is the translation.
// Known gap (see file header): a translation with its own parenthetical
// aside before the real pronunciation group can be missed.
function parseDefinition(def) {
  const parenStart = def.indexOf('(');
  const translation = cleanInline(parenStart === -1 ? def : def.slice(0, parenStart));
  const rest = parenStart === -1 ? '' : def.slice(parenStart);
  let pronunciation = null, ipa = null;
  const parenMatch = rest.match(/\(([^()]*(?:\([^()]*\)[^()]*)*)\)/);
  if (parenMatch) {
    const inside = parenMatch[1];
    const ipaMatch = inside.match(/\/([^/]+)\//);
    if (ipaMatch) ipa = ipaMatch[1].trim();
    const pronMatch = inside.match(/''([^']+)''/);
    if (pronMatch) pronunciation = pronMatch[1].trim();
  }
  return { translation, pronunciation, ipa };
}

function parsePhrasebookSection(wikitext, categoryHint) {
  const entries = [];
  const lineRe = /^;\s*([^:]+?)\s*:\s*(.+)$/gm;
  let m;
  while ((m = lineRe.exec(wikitext))) {
    const rawTerm = m[1];
    const rawDef = m[2];
    const termParenMatch = rawTerm.match(/\((.+)\)\s*$/);
    const context = termParenMatch ? cleanInline(termParenMatch[1]) : null;
    const term = cleanInline(termParenMatch ? rawTerm.slice(0, termParenMatch.index) : rawTerm);
    const { translation, pronunciation, ipa } = parseDefinition(rawDef);
    if (!term || !translation) continue;
    entries.push({ term, context, translation, pronunciation, ipa, categoryHint });
  }
  return entries;
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

async function main() {
  const targets = countriesArg
    ? countriesArg.split(',').map((c) => [c, COUNTRY_PHRASEBOOKS[c]]).filter(([, v]) => v)
    : Object.entries(COUNTRY_PHRASEBOOKS);

  const rowsToInsert = [];
  const failures = [];

  for (const [countryId, { languageIso, title }] of targets) {
    console.error(`Fetching "${title}" for ${countryId}...`);
    const parsed = await fetchSections(title);
    await sleep(REQUEST_DELAY_MS);
    if (!parsed) { failures.push(`${countryId}: page "${title}" not found`); continue; }

    // "Phrase list" is the top-level section whose sub-sections
    // (Basics, Numbers, Problems, ...) hold the actual entries — grab
    // every sub-section between it and the next top-level heading,
    // rather than hardcoding sub-section names (they vary by language).
    const phraseListIdx = parsed.sections.findIndex((s) => s.line === 'Phrase list' && s.toclevel === 1);
    if (phraseListIdx === -1) { failures.push(`${countryId}: no "Phrase list" section on "${title}"`); continue; }
    const afterPhraseList = parsed.sections.slice(phraseListIdx + 1);
    const nextTopLevel = afterPhraseList.findIndex((s) => s.toclevel === 1);
    const subsections = nextTopLevel === -1 ? afterPhraseList : afterPhraseList.slice(0, nextTopLevel);

    let entryCount = 0;
    for (const section of subsections) {
      const wikitext = await fetchSectionWikitext(parsed.title, section.index);
      await sleep(REQUEST_DELAY_MS);
      if (!wikitext) continue;
      const entries = parsePhrasebookSection(wikitext, section.line);
      entryCount += entries.length;
      for (const e of entries) {
        rowsToInsert.push({
          country_id: countryId,
          candidate_type: 'phrase',
          source: 'wikivoyage',
          source_url: `https://en.wikivoyage.org/wiki/${encodeURIComponent(parsed.title.replace(/ /g, '_'))}`,
          payload: {
            language_iso: languageIso,
            text: e.translation,
            translation: e.term,
            pronunciation: e.pronunciation,
            ipa: e.ipa,
            formality_hint: e.context,
            category_hint: e.categoryHint,
          },
          status: 'pending',
          fetched_at: new Date().toISOString(),
        });
      }
    }
    console.error(`  ${entryCount} entries across ${subsections.length} subsections.`);
  }

  console.error(`\n--- Summary ---`);
  console.error(`Countries attempted: ${targets.length}`);
  console.error(`Failures: ${failures.length}`);
  if (failures.length) console.error(`  ${failures.join('\n  ')}`);
  console.error(`Candidate phrases staged: ${rowsToInsert.length}`);
  const byCountry = {};
  for (const r of rowsToInsert) byCountry[r.country_id] = (byCountry[r.country_id] ?? 0) + 1;
  console.error(`  by country: ${JSON.stringify(byCountry)}`);

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
