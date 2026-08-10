# Working notes for Claude — Around the Word

Directions Colleen has given while building this project, kept here so future
sessions don't need to be re-told. Add to this as new direction comes in;
don't remove entries unless she says they no longer apply.

## Current plan

**Read these three docs first in any new session** — together they're the
authoritative plan, as of the 2026-08-06 pivot:

- [around-the-word-client-design.md](around-the-word-client-design.md) —
  screens, flows, client state, offline caching
- [around-the-word-data-architecture.md](around-the-word-data-architecture.md)
  — schema, backend, client data objects. **This is the one to check first
  for any data-shape question** — the client doc explicitly defers to it if
  they ever disagree.
- [around-the-word-scratch-notes.md](around-the-word-scratch-notes.md) —
  loose ends, not decisions

All three were refined 2026-08-09: a `why_short`/`why` split for best-times
display (a bare list of months isn't acceptable UI output — see the client
design doc's Overview tab), a full External Data Sources audit (condensed
below), and the US State Dept Consular Affairs API resolving the advisory/
visa-import open question. Short version of the pivot: **the app is no longer the product — a
hand-curated travel database is.** Supabase (Postgres) backend, real schema
(countries, cities, leadership, curated guides, points of interest, tips,
language content down to word/phrase/token level, advisories, visas,
contributor/verification pipeline, phase-2 trip schema). The Flutter client
is one reader of that data: search → country page (five tabs: Overview,
Explore, Guide, Travel Info, Language) → language flow (categories →
personalizing → Learn/Use → flashcards) unchanged in shape from before.
Content still organized **per country, not per language** — that decision
survived the pivot unchanged.

**Don't build without being asked, even though schema exists for all of it:**
accounts, trip dashboards, checklists, pinning, word-of-the-day
notifications, anything social, real weather/currency API integration,
actual Supabase project setup. All of these have schema locked in the data
architecture doc specifically so building them later needs no redesign —
that is not the same as them being in scope now. V1 is read-only country
pages, no accounts, no live backend calls except weather/currency (and even
those aren't built yet — see the data architecture doc's Sequencing
section for the actual build order).

This superseded an earlier no-backend, static-JSON-bundled version of the
app (5-8hrs/week budget, checkbox categories, no map) — see the
superseded-notice at the top of
[language-app-system-design.md](language-app-system-design.md) for what
changed and why. That doc, [app-design-doc.md](app-design-doc.md), and the
pre-pivot parts of [HANDOFF.md](HANDOFF.md) are all kept as history, not
current — nothing in them was deleted, ideas that got scoped out are noted
as things that could resurface, not abandoned.

## External data sources (for the commodity importer — not built yet)

Condensed from the data architecture doc's "External Data Sources" section
(refined 2026-08-09) so the endpoints don't need a full doc read each
session. **The commodity/curated split still governs this**: fetch these
aggressively when the importer gets built; never fetch points of interest,
guide content (cuisine/dress/norms/festivals), language content, or social
norms this way — that's hand-curated by design, API or not.

- **Country facts** (capital, currency, calling code, languages, coords,
  flag, native name): **REST Countries** (`restcountries.com/v3.1`, no key)
- **Cities**: **GeoNames** (`api.geonames.org`, free username) — populates
  `is_major` only, never `is_featured`
- **US advisories + entry/exit requirements (visa data)**: **State Dept
  Consular Affairs API** (`cadataapi.state.gov`, no key, but applies bot
  detection — needs a real server-side `User-Agent`, not a browsing tool).
  `entry_exit_requirements` returns HTML embedded in JSON strings; budget
  real sanitizing, not a field-to-field mapping.
- **Canadian advisories**: **Global Affairs Canada**
  (`data.international.gc.ca/travel-voyage/`)
- **Leadership**: **Wikidata** SPARQL — moot until the importer exists
  regardless; leadership isn't shown in V1 (see data architecture doc's Open
  Decisions)
- **Currency conversion**: **ExchangeRate-API** — live, never bundled
- **Public holidays** (a future "what's closed when" fact — explicitly
  *not* a source for `festivals`, which stays hand-curated named events):
  **Nager.Date v4** (`date.nager.at`) — v3 end-of-life is 2027-01-31, build
  against v4 from day one

All of the above runs **server-side in a Supabase Edge Function**, never
from the Flutter client — key security, and the State Dept API's bot
detection specifically requires it.

## External context (why the app is scoped the way it is)

- This ties to Colleen's existing **nightglow.studio** stack/experience.
- Original budget constraint: **5-8 hrs/week**, still real, but the data
  architecture doc explicitly flags that the post-pivot scope has grown well
  past what that budget assumed — "Claude Code compresses the *coding*
  meaningfully — it does not compress data collection or schema judgment."
  Don't assume the old hours estimate still holds; the honest constraint now
  is data-entry time (hers) more than build time (Claude's).
- **Build doesn't start on a calendar date** — it starts once every
  personally-visited country is fully collected in the spreadsheet (the data
  architecture doc's Sequencing section). Data collection currently runs
  ahead of / in parallel with code. Don't treat "let's build X" requests as
  implying the schema or content behind X is ready unless she says so.
- V1 timeline was **Jan-Aug 2027** per a separate career/roadmap document;
  treat that as stale given the scope growth above rather than assuming it
  still holds. Longer-term, itinerary-aware/SLA-theory-driven work is
  described there as **master's-dependent** — gated on her master's program,
  not just app progress.

## Product direction

- MVP content should stay simple relative to the *current* docs' V1 scope —
  don't over-build beyond what they call for. That scope is now
  meaningfully larger than the original static-JSON MVP (see Current plan),
  so "simple" means "matches the docs," not "as small as the original app."
- Alongside topic-based categories (Food, Transportation, etc.), it's fine to
  add core-vocab-style categories that aren't tied to a situation — e.g. "20
  Common Verbs." These don't need special modeling, just another category.

## Docs to keep current

- [around-the-word-client-design.md](around-the-word-client-design.md) and
  [around-the-word-data-architecture.md](around-the-word-data-architecture.md)
  — the two living docs. Update these when scope, architecture, schema, or
  roadmap decisions change; each has its own Open Questions/Open Decisions
  section to append to.
- [around-the-word-scratch-notes.md](around-the-word-scratch-notes.md) —
  loose ends and useful context that don't belong in the two docs above.
- [HANDOFF.md](HANDOFF.md) — implementation-level decisions made while
  building, and why. Update this when a non-obvious technical call gets made
  (data modeling, navigation structure, scope cuts), not for routine code
  changes.
- [language-app-system-design.md](language-app-system-design.md) and
  [app-design-doc.md](app-design-doc.md) — superseded, kept as history only.
  Don't update these except to add a superseded-notice if something *else*
  supersedes the current docs later.

## Working style

- When a newly-provided doc/handoff conflicts with what's already recorded in
  the project, **flag the specific conflicts before proceeding** rather than
  silently picking one or merging them quietly. Confirmed good approach on
  2026-07-27: flagging a conflict between a pasted system-design doc and the
  existing app-design-doc.md got a fast, decisive resolution ("default to the
  new doc, update anything else accordingly") rather than friction — she
  wants the flag, then to make the call herself.
