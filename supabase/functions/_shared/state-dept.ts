// Whereabout: shared helpers for cadataapi.state.gov-fetching Edge
// Functions (`refresh-state-dept-data`, `discover-state-dept-codes`).
// Factored out 2026-08-25 so the two functions can't drift apart on how a
// response gets cleaned or a country name gets matched — see CLAUDE.md's
// "don't duplicate a shared widget's styling across call sites" rule,
// same reasoning applied to fetch/parse logic instead of a widget.

export const BASE_URL = "https://cadataapi.state.gov/api";

export const HEADERS = {
  "User-Agent": "Mozilla/5.0 (compatible; WhereaboutApp/1.0; personal travel app data refresh)",
  "Accept": "application/json",
};

export const sleep = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));

// Per-request pacing for both refresh-state-dept-data and
// discover-state-dept-codes — one shared constant so a future pacing
// change doesn't need updating in two places and drifting. Raised from
// 1500ms 2026-08-25: this exact investigation tripped a real 429 three
// separate times in one session (the initial full-space sweep, a 42-
// country diagnose pass, and even a single extra verification request
// minutes after the previous block had just cleared) — the earlier value
// was tuned against a single sweep's worth of traffic, not the sustained,
// repeated use a genuinely reusable tool gets. Each individual block also
// took several minutes to clear regardless of backoff, which points at a
// cumulative/rolling window rather than a per-request limit — slower
// steady pacing reduces how fast that window fills, though it can't
// undo a block that's already tripped.
export const DEFAULT_REQUEST_DELAY_MS = 2_200;

const FETCH_TIMEOUT_MS = 8_000;

export async function fetchJson(url: string): Promise<unknown> {
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

// Same request, but a real HTTP 429 gets a genuine backoff-and-retry
// instead of being treated the same as any other failure. Added
// 2026-08-24 after the full-code-space discovery sweep tripped a real
// Cloudflare rate-limit challenge (`cf-mitigated: challenge`) on
// cadataapi.state.gov mid-run — that's the site itself pushing back, not
// our own bug, and immediately retrying without waiting just re-triggers
// it. Escalating delays, 2 retries max, then give up on this one code — a
// single code isn't worth stalling an entire batch for. Raised from
// [5s, 15s] 2026-08-25 after a real block was observed still active a
// full 3+ minutes in — the original values were sized for a brief
// per-request challenge, not the longer window this API actually enforces.
const RATE_LIMIT_BACKOFF_MS = [10_000, 45_000];

export async function fetchJsonWithBackoff(url: string): Promise<unknown> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await fetchJson(url);
    } catch (err) {
      const isRateLimited = (err as Error).message === "HTTP 429";
      if (!isRateLimited || attempt >= RATE_LIMIT_BACKOFF_MS.length) throw err;
      await sleep(RATE_LIMIT_BACKOFF_MS[attempt]);
    }
  }
}

export function stripHtml(value: unknown): string | null {
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

// Lowercases, strips accents (Côte -> Cote), and drops punctuation and
// lone single-letter tokens (handles French elision either written as
// "d'Ivoire" or, as the State Dept's own feed inconsistently does,
// "d Ivoire" with the apostrophe just gone) — added 2026-08-19 after
// "Côte d'Ivoire" and "Cote d Ivoire" showed up as two different
// unmatched names across two separate real API calls, minutes apart, for
// the same country. Reduces (doesn't eliminate) the need for literal
// aliases — genuinely different names (Burma/Myanmar) still need one.
const COMBINING_DIACRITICS = new RegExp("[\\u0300-\\u036f]", "g");

export function normalizeName(name: string): string {
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
//
// Originally built for TravelAdvisories' Title field only. Extended
// 2026-08-25 to double as the source of truth for entry_exit_requirements
// content matching too (see textMentionsCountry below) — found live that
// the visa-summary guard's plain `stripped.includes(name_common)` check
// was silently discarding genuinely correct content whenever the State
// Dept's own text uses an official/alternate name instead of name_common
// (confirmed for Kyrgyzstan, whose real content — same as its advisory
// Title already handled here — says "Kyrgyz Republic", never
// "Kyrgyzstan"). One alias table instead of two so a name-form learned
// from one endpoint automatically helps the other, rather than needing
// rediscovery twice.
export const NAME_ALIASES: Record<string, string> = {
  "czech republic": normalizeName("Czechia"),
  "burma": normalizeName("Myanmar"),
  "the bahamas": normalizeName("Bahamas"),
  "the gambia": normalizeName("Gambia"),
  "cabo verde": normalizeName("Cape Verde"),
  "korea south": normalizeName("South Korea"),
  "korea north": normalizeName("North Korea"),
  "cote ivoire": normalizeName("Ivory Coast"),
  "federated states of micronesia": normalizeName("Micronesia"),
  "the kyrgyz republic": normalizeName("Kyrgyzstan"),
  "kingdom of denmark": normalizeName("Denmark"),
  "democratic republic of the congo": normalizeName("DR Congo"),
  "republic of the congo": normalizeName("Congo"),
  // Added 2026-08-25 as a proactive fix (cadataapi.state.gov rate-limited
  // that investigation before GB/TR's own content could be read directly)
  // — both since confirmed live the same day: Türkiye's real advisory
  // Title is "Turkey - Level 2: ...", and "UK" content was found and
  // verified as genuinely the United Kingdom's own entry_exit_
  // requirements (see HANDOFF.md).
  "turkey": normalizeName("Türkiye"),
  "uk": normalizeName("United Kingdom"),
  // Found 2026-08-25 reading Turks and Caicos' real content directly: it
  // never actually writes the "Islands" suffix that's in name_common, so
  // the plain name_common match scored zero against it while "Bahamas"
  // (mentioned twice, for the nearest emergency passport office) won by
  // default — a real false negative, not a genuine misroute.
  "turks and caicos": normalizeName("Turks and Caicos Islands"),
  // Found 2026-08-25 reading South Korea's real content directly: it only
  // ever says bare "Korea" (K-ETA, "Mission Korea", "Embassy of Korea"),
  // never "South Korea" — scored zero and got rejected by both the
  // discovery matcher and the production guard, even after full-text
  // verification confirmed it's genuinely South Korea (K-ETA is
  // specifically South Korea's travel-authorization program; no DPRK/
  // travel-ban language, which is what North Korea's real content
  // actually reads like). Deliberately NOT symmetric with North Korea —
  // bare "Korea" defaulting to South Korea only, not aliased for North
  // Korea too, since North Korea's real content already names itself
  // explicitly and doesn't need this crutch, and aliasing "korea" toward
  // *both* would reintroduce the exact ambiguity this entry exists to
  // resolve one specific, verified way.
  "korea": normalizeName("South Korea"),
};

// Every raw phrase in NAME_ALIASES that resolves to a given canonical
// name, plus the canonical name itself — e.g. Kyrgyzstan ->
// ["kyrgyzstan", "the kyrgyz republic"]. Built once from NAME_ALIASES so
// there's a single source of truth for "what counts as this country's
// name" instead of a second hand-maintained list that could drift.
const VARIANTS_BY_CANONICAL: Record<string, string[]> = {};
for (const [alias, canonical] of Object.entries(NAME_ALIASES)) {
  (VARIANTS_BY_CANONICAL[canonical] ??= []).push(alias);
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export interface CountryMatch {
  nameCommon: string;
  isoCode: string;
  count: number;
}

// Counts every country's mentions in `text` at once, longest name first,
// *masking* each match out of the working text before moving to the next
// (shorter) name — so "South Sudan" being mentioned can't also inflate
// "Sudan"'s count just because "Sudan" is a whole word inside "South
// Sudan". Found live 2026-08-25: an early version counted each country
// independently against the untouched text, and a genuine South Sudan
// page scored 10 for bare "Sudan" (9 of those from within "South Sudan"
// itself) vs. 9 for "South Sudan" — nearly stealing the win from the
// country the page was actually about. Same containment shape recurs for
// Guinea/Guinea-Bissau/Equatorial Guinea/Papua New Guinea and Congo/DR
// Congo, not just Sudan — this is a general fix, not a Sudan-specific
// patch. `\bNiger\b` not matching inside "Nigeria" already handled the
// no-space-boundary case (word-boundary regex); this handles the
// space-separated case the same trick can't catch on its own.
function countAllMentions(
  text: string,
  countries: Array<{ iso_code: string; name_common: string }>
): Map<string, number> {
  const candidates: Array<{ normalized: string; isoCode: string }> = [];
  for (const country of countries) {
    const variants = [country.name_common, ...(VARIANTS_BY_CANONICAL[normalizeName(country.name_common)] ?? [])];
    for (const variant of variants) {
      const normalized = normalizeName(variant);
      if (normalized) candidates.push({ normalized, isoCode: country.iso_code });
    }
  }
  // Longest normalized phrase first, so a containing name (e.g. "south
  // sudan") gets counted and masked before the shorter name it contains
  // ("sudan") ever gets a chance to match the same span.
  candidates.sort((a, b) => b.normalized.length - a.normalized.length);

  let workingText = ` ${normalizeName(text)} `;
  const counts = new Map<string, number>();
  for (const { normalized, isoCode } of candidates) {
    const pattern = new RegExp(`\\s${escapeRegExp(normalized)}\\s`, "g");
    const matchCount = (workingText.match(pattern) ?? []).length;
    if (matchCount === 0) continue;
    counts.set(isoCode, (counts.get(isoCode) ?? 0) + matchCount);
    // Mask so a shorter name-as-substring of this one can't double-count
    // the same text. Replaces each match with an equal-length run of a
    // character normalizeName's own alphabet never produces, preserving
    // the surrounding single spaces the next pattern's \s...\s expects.
    workingText = workingText.replace(pattern, (m) => ` ${"#".repeat(m.length - 2)} `);
  }
  return counts;
}

// How many times `name` (or any known alias of it) appears in `text`,
// masking-aware — see countAllMentions. `otherCountries` should be every
// country whose name might *contain* `name` as a whole word (South Sudan
// containing Sudan, etc.); omit it only when that's genuinely not a
// concern for the call site.
export function countMentions(
  text: string,
  name: string,
  otherCountries: Array<{ iso_code: string; name_common: string }> = []
): number {
  const counts = countAllMentions(text, [{ iso_code: "__target__", name_common: name }, ...otherCountries]);
  return counts.get("__target__") ?? 0;
}

// Whole-text, alias-aware, containment-safe replacement for the old
// `stripped.toLowerCase().includes(name.toLowerCase())` guard — same
// purpose (does this response actually appear to be about the country we
// requested it for), but checks known alternate names too instead of
// just the literal name_common string, and (via allCountries) won't be
// fooled by a response that's really about a country whose name contains
// this one (e.g. accepting "Sudan" when the text is really about South
// Sudan). Pass the full countries list from the caller's own query.
export function textMentionsCountry(
  text: string,
  nameCommon: string,
  allCountries: Array<{ iso_code: string; name_common: string }> = []
): boolean {
  return countMentions(text, nameCommon, allCountries) > 0;
}

// Which country a chunk of entry_exit_requirements text is actually
// *about* — the count-race replacement for discover-state-dept-codes'
// old "does the target's name appear in the first 250 characters, or as
// an exact 'Embassy of X' phrase" bar. That bar was precise (avoided the
// Switzerland/Iran false positive from the 2026-08-21 round) but not
// sensitive — it missed Portugal's real content because Portugal wasn't
// named prominently up front. Counting mentions across every country at
// once instead gets both properties without a hand-tuned threshold: a
// genuine "about Iran" page mentions Iran many times and Switzerland (its
// protecting power) only once or twice, so Iran wins the count outright —
// the same signal that made the false positive obvious on manual review
// now decides it automatically, while a real match still wins even if
// the country's name only shows up once, deep in the text (Portugal).
// Returns both the winner and runner-up so a human reviewer can see how
// close the race was, same "read the actual text" discipline as always —
// this narrows what needs manual review, it doesn't replace it.
export function findBestCountryMatch(
  text: string,
  countries: Array<{ iso_code: string; name_common: string }>
): { winner: CountryMatch; runnerUp: CountryMatch | null } | null {
  const counts = countAllMentions(text, countries);
  const byIso = new Map(countries.map((c) => [c.iso_code, c]));
  let winner: CountryMatch | null = null;
  let runnerUp: CountryMatch | null = null;
  for (const [isoCode, count] of counts) {
    const country = byIso.get(isoCode);
    if (!country) continue;
    if (!winner || count > winner.count) {
      runnerUp = winner;
      winner = { nameCommon: country.name_common, isoCode, count };
    } else if (!runnerUp || count > runnerUp.count) {
      runnerUp = { nameCommon: country.name_common, isoCode, count };
    }
  }
  return winner ? { winner, runnerUp } : null;
}
