# Handoff Doc — Around the Word (MVP Build)

*Tracks decisions made while implementing the MVP, and why. Companion to [app-design-doc.md](app-design-doc.md), which covers product/design decisions — this one covers what those decisions turned into in code, plus the smaller technical calls made along the way.*

---

## ⚠️ Product direction has pivoted three times since this code was built

Everything below this note describes the **English/TEFL-framed MVP** — subject list → phrase list, no exercises, no place/language concept. Since then the product direction has moved on three times:

1. First to a **trip-specific, place-first app** (Costa Rica/Spanish, activities → bilingual phrases + exercises + a grammar-tagged vocab system + a phrasebook) — captured in [app-design-doc.md](app-design-doc.md).
2. Then, per [language-app-system-design.md](language-app-system-design.md), **scoped down and restructured** to: a continent/country map for destination selection, checkbox category selection (back to the original generic subject list, not the Costa-Rica activity list), a cosmetic "personalizing your dictionary" step, and a **Learn/Use fork** — Learn is flip-card flashcards, Use is the original category→vocab-list flow with a flashcard option bolted on. No fill-in-blank exercises, no grammar tagging, no phrasebook, no accounts/persistence in V1. This is the version most of "Implementation Decisions" below describes, and it's itself now superseded.
3. **2026-08-06 — the current pivot, and now the authoritative direction:** the app inverts from "static JSON bundled in the Flutter app" to "a hand-curated Supabase/Postgres travel database, with the Flutter app as one read client onto it." Country pages replace the old flat vocab flow as the core screen — five tabs (Overview, Explore, Guide, Travel Info, Language), with the old checkbox-categories → personalizing → Learn/Use flow surviving intact as just the Language tab's sub-flow. Real schema now exists for weather, advisories, visas, points of interest, tips, leadership, and a friend-verification pipeline, alongside a much deeper language model (words/phrases/tokens, not just phrase/translation pairs). Captured in three new docs: [around-the-word-client-design.md](around-the-word-client-design.md), [around-the-word-data-architecture.md](around-the-word-data-architecture.md), [around-the-word-scratch-notes.md](around-the-word-scratch-notes.md) — see `CLAUDE.md`'s Current Plan section for the condensed version. Colleen's own framing: "override whatever I've told you so far with whatever is in these sheets even if it means rearchitecture."

**The vocab grammar-tagging pipeline (spaCy) work described below is still relevant groundwork** — even though V1's UI only reads `phrase`/`translation`-equivalent fields today, the new schema's `words`/`phrases` split (dictionary form vs. surface form, tokens, `is_maskable`) is a direct continuation of the same "capture grammatical structure now, cheap; backfill later, expensive" reasoning that motivated tagging `partOfSpeech`/`gender`/`number` in the first place. `tools/vocab_tagger/` (Python + spaCy, venv-isolated, not a Flutter runtime dependency) is still the right tool for generating that tagging, it just now feeds a richer schema than the flat per-country JSON files it originally targeted.

The codebase itself (the actual Flutter app, `lib/`) has **not yet been rebuilt** for pivot 3 as of this note — the mock-data work below is the first step of that, not a completed migration. Everything from "Current State" through the end of "Implementation Decisions" describes pivot 2's build, which is itself now historical, kept for reference (data-modeling reasoning, testing gotchas, etc. that may still transfer) rather than as a description of what's currently in `lib/`.

**2026-08-09 — the three pivot docs were refined, not re-pivoted.** A `why_short`/`why` split for best-times display, a full External Data Sources audit (condensed into `CLAUDE.md`), and the US State Dept Consular Affairs API resolving the advisory/visa-import open question. Nothing here changes the pivot-3 direction described above — see `CLAUDE.md`'s "External data sources" section for the condensed version, or the data architecture doc for the full one.

**Note on the previous paragraph's "not yet been rebuilt for pivot 3" line, below:** stale as of 2026-08-17 — `lib/` now has a real country-page build (`CountryHeader`, `SiteHeader`, the Overview-tab sections) underway against Costa Rica mock data. Left as-is rather than rewritten; this note exists so a future session doesn't take that line at face value.

### Gotcha: `flutter clean` needs a follow-up `flutter pub get`

Surfaced 2026-08-17 mid-way through the `CountryHeader`/ticket-page restyle: running `flutter clean` to rule out a stale-build explanation for a UI change not appearing deletes `.dart_tool/package_config.json` along with the build cache. Without that file, the IDE/analyzer can't resolve *any* import (package or relative) and throws errors across effectively every file in `lib/` and `test/` — reads exactly like widespread source breakage, but nothing in `lib/` actually changed. Fix is `flutter pub get` (regenerates `.dart_tool/`), then `flutter analyze` to confirm clean. Worth trying *before* recommending `flutter clean` as a troubleshooting step, not after.

### 2026-08-18: country page rebuilt as a collapsible-sections accordion, scoped to just that screen

Colleen sent `trip-dashboard-v5.html` — two frames (default-collapsed, all-expanded) of the country page redrawn as six independently-collapsible sections instead of the always-expanded flat stack the 2026-08-15 restyle built, with instructions to "override any existing design decisions with what you see here." Flagged the conflicts before building (per the Working Style note in `CLAUDE.md`) since this reverses two very recent, explicit calls:

- **The palette is cool-toned** (sky blue, lavender, sage) — exactly the family `design-preferences.md` rejected the day before ("stay in the warm/cream family... cool or blue-leaning tones don't fit this page"). Kept as a flagged, deliberate exception — see that doc's note on it, added the same day as this entry.
- **Visa & Entry and Travel Advisory split back into two independent sections**, reversing the 2026-08-11 "one shared source, not two" call. Each now cites its own source line even where (Costa Rica) it's really the same State-Dept page twice — simpler than connecting a shared footer across two cards a reader might collapse independently.
- Typography swapped Cormorant Garamond/Libre Baskerville/Public Sans/Courier Prime for **Fraunces/DM Sans/DM Mono** (fonts pulled from the `google/fonts` GitHub repo's `ofl/` source TTFs, bundled locally per the existing offline-first font policy — see `pubspec.yaml`'s `fonts:` section).

**Scoped to the country page only, confirmed with Colleen first** — `CountryTheme` already drives the app's global `MaterialApp` theme, `DestinationScreen`, and the shared `SiteHeader`, none of which this mockup shows. Rather than repoint `CountryTheme` itself, the new tokens live in a parallel `lib/theme/accordion_theme.dart` (`AccordionTheme`), consumed only by `CountryHeaderPreviewScreen` and the section widgets exclusive to it (confirmed via grep before editing: `CitiesSection`/`LanguagePairSection`/`BestTimesSection`/`PracticalNormsSection`/the old `TravelInfoSection`/`CountryHeader` have no other consumers). `SiteHeader` gained optional color-override params (default unchanged, so `DestinationScreen`'s instance is untouched) so this screen's instance can go ink-themed without a site-wide repoint. `CountryTheme` itself is untouched.

**New `AccordionSection` widget** (`lib/widgets/country_page/accordion_section.dart`) wraps every section: collapsed shows title + a one-line meta subheading derived from real bundle fields (never invented — e.g. Visa's meta is a truncated `VisaInfo.summary`, not a fabricated "visa required: yes/no"); expanded hides the subheading and shows the section's content, or a "Coming soon" placeholder when the underlying list/field is empty. **Every section always renders as a row regardless of data** — confirmed directly with Colleen, a deliberate difference from the rest of the app's "omit an empty tab" rule (client design doc), which is about whole tabs, not sub-sections within an already-shown page.

`TravelInfoSection` (the old combined widget) is deleted; `VisaSection` and `TravelAdvisorySection` replace it. `test/widgets/travel_info_section_test.dart` (covered the old desktop side-by-side/shared-source behavior, both gone) was replaced with `test/widgets/visa_and_advisory_sections_test.dart`. `test/widget_test.dart`'s smoke test updated to expand the Cities section before asserting a city name is present, since content only mounts once its section is open.

**Verification**: `flutter analyze`/`flutter test` both pass. Visually spot-checked via a temporary widget test that rendered `CountryHeaderPreviewScreen` to PNG (`RepaintBoundary.toImage`, with fonts explicitly loaded via `FontLoader` since `flutter_test` doesn't load custom fonts by default) rather than a live simulator — caught and fixed a real `RenderFlex` overflow in `CitiesSection`'s row (`city.name` needed `Flexible`+ellipsis, not an unconstrained `Row` inside `Expanded`) before it would have hit a device. The screenshot test file itself was temporary and deleted after use, not committed.

**Not addressed by this pass**: the five-tab IA (Overview/Explore/Guide/Travel Info/Language) the client design doc still documents as "resolved" is increasingly out of step with what `CountryHeaderPreviewScreen` actually is now (a flattened accordion spanning what were Overview/Travel-Info/Language content). Worth a real doc pass once Explore/Guide's remaining content (POI landmarks, cuisine, dress, festivals, history) actually needs a home — not blocking today's work since none of that is built yet either way.

## Current State (of the pivot-2 build — historical, not current; see the pivot note above)

The four-screen flow from `language-app-system-design.md` is built and wired end to end, backed by placeholder content: Destination search → (Category checkboxes, or Coming-soon if inactive) → cosmetic "Personalizing your dictionary" step → Learn/Use fork. Learn opens a shuffled flashcard deck of everything selected; Use goes to a category list → (sub-subjects, if any) → vocab list, with a per-category flashcard option. One country has real content (Costa Rica/`cr`) out of all 219 in `countries.json` — every country is selectable from search, but only `active` ones reach the real flow; the rest dead-end at `ComingSoonScreen` (see Implementation Decisions). Content is placeholder — a handful of tagged entries under `food-cooking`, `museums`, and `hiking` — not real Costa Rica vocab yet. `flutter analyze` and `flutter test` both pass.

(This used to be a five-screen flow with a continent list → country list step; that was dropped 2026-07-30 in favor of a single search screen — see the Implementation Decisions entry below.)

## Implementation Decisions

- **State management: `provider`, not `riverpod`.** The doc left this open ("Provider, or Riverpod if a bit more structure is wanted"). Went with `provider` since the actual state shape is one flat `ChangeNotifier` (`TripSelection`) read by every screen — Riverpod's extra structure (providers-of-providers, code-gen) isn't earning its keep at this size. Revisit if state gets meaningfully more complex.

- **The continent/country maps were placeholder lists, not real maps** *(superseded — see the destination-screen entry below; `ContinentMapScreen`/`CountryMapScreen` no longer exist)*. The design doc originally called out evaluating a Flutter map/SVG package as separate follow-up work — building that now would have blocked the whole flow on a UI/rendering decision unrelated to data model or navigation. A real map (`countries_world_map` package) was in fact prototyped and wired in later on a dedicated branch, but that work was ultimately dropped in favor of a single search screen — kept for the record in case map-based destination picking gets revisited.

- **Destination picking collapsed from two screens (continent map → country map) into one search screen** — changed 2026-07-30 at Colleen's request: "Where are you going?" heading, a search field that filters the full country list directly (no continent grouping), and a decorative globe icon (`Icons.public`, no image asset added) filling the space below the search field when there's no query yet. This is a genuine product-direction change, not just an implementation swap — flagged the conflict with `language-app-system-design.md`'s documented two-screen map flow before building, and updated that doc's Requirements/User Flows/Architecture/Roadmap sections to match, per her call to keep the doc authoritative. New screen is `lib/screens/destination_screen.dart` (`DestinationScreen`), replacing the deleted `continent_map_screen.dart`/`country_map_screen.dart`. `TripSelection` lost `selectedContinent`/`selectContinent`/`countriesInContinent`/`isContinentActive` since nothing reads continent groupings anymore — `Country.continent` itself stays in the data model as informational/future-hook data (per the design doc). The map flow (real `countries_world_map` widget, pinch/zoom, tap-to-country-resolution, etc.) had actually been built and proven out on the `feature/map` branch earlier — that work isn't merged into `main` and isn't touched by this change, just no longer the plan going forward.

- **`countries.json` now lists all 219 real-world countries/territories, not just the 4 placeholders (Costa Rica, Mexico, Argentina, France)** — changed 2026-07-30 at Colleen's request ("all countries in the dropdown"). Sourced from the same 219-entry `id`/`name`/`continent` dataset built on the `feature/map` branch (`world_map_countries.json`, itself cross-referenced against a standard ISO region dataset — see that branch's history for how it was built), not hand-typed. Only `cr` is `active: true` — see the next entry for what `active` actually gates now. Two fields needed filling in that the source dataset didn't have: `languageCode` (a best-effort primary/official language per country, ISO 639-1 — **not independently verified**, low-stakes since no code path actually reads this field yet, but worth a real pass before it is) and `name` (a handful of ISO formal names swapped for common ones better suited to a search field — e.g. "Russian Federation" → "Russia", "Korea, Republic of" → "South Korea", "United States of America" → "United States" — full list of overrides is in this commit's diff).

- **Every country is selectable on the destination screen, but only `active` ones reach the real flow — the rest dead-end at a "coming soon" screen** — the tap-through-to-empty-flow version shipped 2026-07-30 ("for now let's have all countries be selectable... even if we don't have language info available yet") was itself superseded the same day once Colleen sent over a full rewrite of `language-app-system-design.md` calling for an explicit coming-soon screen instead ("Dead end by design — no further app flow for this country until content ships"). Flagged that reversal plus a second, bigger one in the same doc (content per-language vs. per-country) before touching anything; she confirmed keep-per-country and build-the-coming-soon-screen. `DestinationScreen._selectCountry` now branches on `country.active`: `true` proceeds to `CategorySelectionScreen` as before, `false` pushes the new `ComingSoonScreen` (`lib/screens/coming_soon_screen.dart`) instead. That screen reads a new `TripSelection.resources` (`List<Resource>`, loaded via `ContentRepository.loadResources()` from a new `assets/data/resources.json` — one shared set of generic links reused for every uncovered country, per the doc's explicit reasoning against curating per-country resources) and opens them with the new `url_launcher` dependency. `ContentRepository.loadContent`'s try/catch around the missing-asset case (added for the now-superseded empty-flow version) was kept rather than removed — `loadContent` is unreachable for inactive countries in the normal flow now, but it's a harmless safety net if `active` is ever flipped true ahead of its content file actually existing.
  - Regression test for this lives in its own file, `test/no_content_country_test.dart` (rewritten from testing the empty-flow behavior to testing the coming-soon screen), not appended to `widget_test.dart` — pumping a second full `AroundTheWordApp` in the same test file makes `pumpAndSettle` hang (confirmed with a two-line minimal repro, nothing specific to this scenario; a pre-existing `flutter_test` quirk, not a bug in the app). One full-app-boot test per file going forward avoids it.

- **One recursive `CategoryListScreen` instead of separate parent/child screens.** Use mode needs a category list, and (for categories with sub-subjects) a second screen showing just those sub-subjects. Rather than two widgets, `CategoryListScreen` takes an optional `subjectsToShow`/`title` and pushes itself again for a tapped subject's children when it has any, or a `VocabListScreen` when it doesn't. Same pattern the original English MVP used for the category→subject skip logic, just generalized to arbitrary depth instead of hardcoded to one level.

- **`TripSelection.personalize()` is written as a real `async` step**, even though today it's just a local map filter plus an artificial `Future.delayed(900ms)` for the cosmetic loading screen — per the doc's explicit instruction that this should be a one-line swap to a real backend call later, not a restructure.

- **Content files are looked up as `content/{countryCode.toLowerCase()}.json`** (e.g. `cr.json`) — lowercased so the convention doesn't depend on remembering to match `countries.json`'s casing exactly.

- **Flashcards use tap-to-flip + next/previous, no swipe gesture or flip animation.** The doc only specifies "tap or swipe to flip, swipe or button to advance" — went with the simpler half (tap, buttons) for the scaffold; swipe gestures and a real flip animation are additive, not a rework, if wanted later.

- **Deleted the old English-MVP `lib/` files** (`models/vocab_category.dart`, `data/vocab_data.dart`, the three old screens) rather than keeping them alongside the new structure — they're preserved in git history (commit `bdf23b2`), and keeping unused code around would just be confusing dead weight given the new doc fully supersedes that direction.

## Open Questions

- Real map rendering for the continent/country screens — which package, and how much of a scope item that is on its own, is still unevaluated.
- Placeholder content (`food-cooking`, `museums`, `hiking`) needs to become real, reviewed Costa Rica vocab — next step is running actual content through `tools/vocab_tagger/` rather than hand-writing tagged JSON.
- Flashcard visuals (flip animation, swipe gestures) are intentionally minimal right now — worth a pass once the core flow is validated, not before.

## Explicitly Not Done Yet

- No git commit of this scaffold.
- No real continent/country map rendering (see Open Questions).
- No accounts, persistence, or backend — matches current V1 scope exactly, not a gap.
- No exercise UI beyond flashcards (fill-in-blank, matching) — deferred per the roadmap, tags are captured but unused.

---

## Current State (of the original English MVP build — pre-pivot, historical)

A working Flutter prototype: launch the app → see a list of categories → tap one → see either a subject list (if the category has niche sub-subjects) or the phrase list directly (if it doesn't) → see the vocab words/phrases. All content is hardcoded in Dart, no backend, no persistence, nothing committed to git yet.

## Implementation Decisions (historical)

- **Three-level data model: `Category` → `Subject` → `Phrase`.**
  **Why:** the design doc's subject list already distinguishes broad groups (Food, Transportation) from niche sub-subjects within them (Cooking, Grocery Shopping) and explicitly flags this as "structure to keep in mind for how subjects are organized." Modeling it as two list levels (rather than a flat list with a category string) keeps that hierarchy real instead of implicit.

- **Categories with only one subject skip the subject-list screen and go straight to the phrase list.**
  **Why:** roughly half the v1 subject list (Hiking, Museums, Music, Occupations, etc.) has no sub-items. Forcing a tap through an intermediate screen with a single row would add friction the MVP's "pick a subject, see the words" framing doesn't call for. Categories that do have sub-items (Food, Shopping, Transportation, Celebrations) still show the intermediate list.

- **Added "20 Common Verbs" as a new category**, per direction to include one alongside the existing subject list. Structured the same way as any single-subject category (no special-casing in the model) — it's just a `Category` with one `Subject` holding 20 `Phrase`s.

- **Phrases are plain English text only — no translations, audio, or example sentences.** Matches "English only for the prototype" and keeps scope inside what the design doc's MVP section actually asked for (word/phrase lists, nothing more). The design doc's open question about what a subject should contain beyond a word list is still open — see below.

- **No new dependencies added** beyond the default Flutter scaffold (`cupertino_icons`, `flutter_lints`). Kept deliberately lean since this is a prototype and the data is static.

- **Rewrote the default counter widget test** to instead drive the real navigation flow (category list → subject list → phrase list, and the single-subject skip path) since the scaffold's test exercised the counter demo that no longer exists.

## Open Questions (historical, carried over + new)

- Still open from the design doc: what a subject contains beyond a word list (example sentences? audio?), and whether sub-subjects should be separately selectable or grouped. Now that real content exists, worth revisiting concretely rather than in the abstract.
- "20 Common Verbs" is structurally a category like any other, but conceptually different — it's a core-vocab list rather than a situational/topic list. Worth deciding whether that distinction should show up in the UI (e.g. a separate section) as more non-topic lists get added.
- Category and subject names in code are close to the design doc's wording but not identical in a few spots (e.g. "Hiking / The Outdoors") — worth a pass to make sure display names match what's wanted before this goes further.

## Explicitly Not Done Yet (historical)

- No git commit.
- No "learn vs. use" mode, personalization, or multi-language support (per MVP scope).
- No social/community layer (liking phrases, recommending places) — flagged in the design doc as post-MVP, data model wasn't specifically shaped around it yet.
- No persistence layer — content is a static Dart file, not a database or CMS.
