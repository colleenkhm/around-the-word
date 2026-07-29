# Handoff Doc — Around the Word (MVP Build)

*Tracks decisions made while implementing the MVP, and why. Companion to [app-design-doc.md](app-design-doc.md), which covers product/design decisions — this one covers what those decisions turned into in code, plus the smaller technical calls made along the way.*

---

## Note on this doc's history

The core idea behind this app — a travel-focused language-learning tool — hasn't actually changed. What's changed is scope and level of ambition, refined over a couple of passes:

- Very early on, English/TEFL was floated as a possible starting angle and got documented as a decision at the time. In hindsight it was never really the app's intended direction, just an idea explored briefly before the real shape of the product took hold — worth knowing so the sections below aren't read as a committed direction that later got abandoned.
- A fuller exploration then worked out what a trip-specific, place-first version could look like in real detail — Costa Rica/Spanish, activity-specific curation, multiple exercise types, a grammar-tagged vocab system, a phrasebook (captured in [app-design-doc.md](app-design-doc.md)).
- [language-app-system-design.md](language-app-system-design.md) (now the authoritative doc) is the realistically-scoped version of that same idea, sized to an actual 5-8 hrs/week budget: a continent/country map for destination selection, checkbox category selection, a cosmetic "personalizing your dictionary" step, and a Learn/Use fork (flip-card flashcards, plus the original category→vocab-list flow). These two aren't contradictory directions — the fuller exploration's ideas (activity-specific curation, richer exercises, the grammar-tagging use case) are flagged in that doc's roadmap as later work, not discarded.

**The vocab grammar-tagging pipeline (spaCy) is back in scope, in a lighter form.** Even though V1's UI only reads `phrase`/`translation`, we're tagging `partOfSpeech`/`gender`/`number` on every entry now rather than backfilling later, since it's cheap (an automated pass, not manual per-word effort) and expensive to redo once exercises come back into scope. Built and tested in `tools/vocab_tagger/` — a one-time/occasional dev tool (Python + spaCy, venv-isolated, not a runtime dependency of the Flutter app). Confirmed working against a sample Spanish batch: correctly tagged `"el agua"` as `gender: feminine` despite the masculine-looking article (a real Spanish exception), and correctly separated `"hervir"` (verb, no gender/number) from noun entries. Mass-vs-countable noun distinction and anything flagged `needsReview` still need a human pass — see `tools/vocab_tagger/README.md`. What's *not* being built yet: any exercise UI/logic that consumes these tags (fill-in-blank, matching) — that's still deferred per the current roadmap.

The codebase has now been rebuilt to match `language-app-system-design.md` — see "Current State" and "Implementation Decisions" immediately below. Everything from "Current State (of the original English MVP build)" onward is kept as history, not current.

## Current State

The five-screen flow from `language-app-system-design.md` is built and wired end to end, backed by placeholder content: a **real interactive world map** (Continent → Country, with search) → Category checkboxes → cosmetic "Personalizing your dictionary" step → Learn/Use fork. Learn opens a shuffled flashcard deck of everything selected; Use goes to a category list → (sub-subjects, if any) → vocab list, with a per-category flashcard option. One country is active (Costa Rica/`cr`), with three inactive placeholders (Mexico, Argentina, France) to exercise the "grayed out" and multi-continent paths. Content is placeholder — a handful of tagged entries under `food-cooking`, `museums`, and `hiking` — not real Costa Rica vocab yet. `flutter analyze` and `flutter test` both pass (32 tests).

## Implementation Decisions

- **State management: `provider`, not `riverpod`.** The doc left this open ("Provider, or Riverpod if a bit more structure is wanted"). Went with `provider` since the actual state shape is one flat `ChangeNotifier` (`TripSelection`) read by every screen — Riverpod's extra structure (providers-of-providers, code-gen) isn't earning its keep at this size. Revisit if state gets meaningfully more complex.

- **The continent/country maps are real** (`countries_world_map` package), not placeholder lists — first proven out in isolation on a dedicated branch (see `lib/map_prototype/`), then wired into `ContinentMapScreen`/`CountryMapScreen` for real once that worked. Chose `countries_world_map` over a newer-looking alternative (`interactive_world_map`) specifically because it had 18 published versions vs. one — a real track record mattered more than a slightly better-fitting description for a dependency this central.

- **A generated country→continent dataset (`assets/data/map/world_map_countries.json`, 219 entries) drives continent resolution**, since the map package only draws individual countries — it has no concept of continents at all. Built once from the package's own path data (which countries it draws) cross-referenced against a standard ISO region dataset, with our own bucketing rule (Central America + Caribbean count as `north-america`, matching how Costa Rica was already categorized) rather than the UN geoscheme, which lumps those with South America. Two politically-sensitive ISO gaps (Taiwan, Kosovo) needed manual resolution — not data errors, those countries' region fields are genuinely blank/absent in the standard dataset.

- **Tap resolution is pure functions (`resolveContinentTap`/`resolveCountryTap` in `lib/data/map_tap_resolution.dart`), not logic embedded in the screens.** This is what makes the selection logic unit-testable without simulating a pixel-precise tap on a specific country's rendered shape (which would be brittle) — `test/data/map_tap_resolution_test.dart` covers unrecognized taps, recognized-but-inactive, and successful resolution entirely without pumping a widget. Both the real screens and `lib/map_prototype/` share these functions, so the two can't quietly drift apart.

- **Continent zoom is one hand-computed bounding box (North America only), not a general system.** Originally started computing this properly (parsing path geometry for a "fit to bounds" transform across all continents) before catching that as more infrastructure than the current scope needs — only one continent is actually reachable today. `lib/data/continent_zoom_bounds.dart` documents how to add more by hand as they come online, rather than building the general case now.

- **`ContinentMapScreen` (the world map) now opens pannable/pinchable via a computed initial `Matrix4`, instead of a bare, un-positioned `InteractiveViewer`** — changed 2026-07-28 at Colleen's request. Went through two intermediate versions before landing here (initial "zoom in past cover-scale" attempt overshot — she asked to walk it back to whole-map-visible), worth knowing in case zoom/position gets revisited again. Landed on: whole map visible (`fitScale`, `min` of viewport width/height ratios vs. map size — also the zoom-out floor via `minScale`), but vertically anchored toward the bottom edge (`_positionMap`, minus a small `_bottomMargin`) rather than dead-centered — phones are much taller/narrower than the map's own wide/short aspect ratio, so fitting the whole map leaves a lot of vertical slack, and centering it splits that evenly above and below; biasing low instead concentrates it above the map, under the app bar. Reused `CountryMapScreen`'s existing `constrained: false` + `TransformationController` pattern rather than inventing a second approach, just centered on the whole map instead of one continent's bounds. `fitScale` is computed from the viewport at runtime, not hardcoded, so it holds up across device sizes. Pulled the map's native pixel size (`Size(2000, 857)`, from the package's embedded "w"/"h") out of `country_map_screen.dart` into a shared `mapSize` constant in `lib/data/continent_zoom_bounds.dart` since both screens' zoom math now depends on it. `lib/map_prototype/continent_tap_screen.dart` was deliberately left as-is (unzoomed, full world, dead-centered) — it already documents itself as a superseded reference copy, not something this needs to stay in sync with.

- **The search field on the country screen owns its own state, separate from the map's.** `SimpleMap` re-parses its ~290KB embedded JSON on every rebuild (no internal caching — confirmed by reading the package source), so if search-query state lived in the same widget as the map, every keystroke would rebuild and re-parse the whole map. Pulled into a private `_CountrySearchField` widget so typing only rebuilds the search subtree, not the map.

- **One recursive `CategoryListScreen` instead of separate parent/child screens.** Use mode needs a category list, and (for categories with sub-subjects) a second screen showing just those sub-subjects. Rather than two widgets, `CategoryListScreen` takes an optional `subjectsToShow`/`title` and pushes itself again for a tapped subject's children when it has any, or a `VocabListScreen` when it doesn't. Same pattern the original English MVP used for the category→subject skip logic, just generalized to arbitrary depth instead of hardcoded to one level.

- **`TripSelection.personalize()` is written as a real `async` step**, even though today it's just a local map filter plus an artificial `Future.delayed(900ms)` for the cosmetic loading screen — per the doc's explicit instruction that this should be a one-line swap to a real backend call later, not a restructure.

- **Content files are looked up as `content/{countryCode.toLowerCase()}.json`** (e.g. `cr.json`) — lowercased so the convention doesn't depend on remembering to match `countries.json`'s casing exactly.

- **Flashcards use tap-to-flip + next/previous, no swipe gesture or flip animation.** The doc only specifies "tap or swipe to flip, swipe or button to advance" — went with the simpler half (tap, buttons) for the scaffold; swipe gestures and a real flip animation are additive, not a rework, if wanted later.

- **Deleted the old English-MVP `lib/` files** (`models/vocab_category.dart`, `data/vocab_data.dart`, the three old screens) rather than keeping them alongside the new structure — they're preserved in git history (commit `bdf23b2`), and keeping unused code around would just be confusing dead weight given the new doc fully supersedes that direction.

- **Data models and JSON loading/parsing have dedicated unit tests, separate from the end-to-end widget test.** `test/models/*_test.dart` covers `Country.fromJson`/`VocabEntry.fromJson`/`Subject.fromJson` plus the `SubjectListX` tree helpers (`topLevel`, `childrenOf`, `idAndDescendantIds` — including a synthetic three-level tree, since the real `subjects.json` is only two levels deep and wouldn't otherwise exercise deeper recursion). `test/data/content_repository_test.dart` loads the real bundled `assets/data/*.json` (catches malformed placeholder JSON directly, not just via the UI flow) and exercises `personalize()`'s filtering rules: a parent id pulls in its children's content but not its own (parents don't carry phrases directly), multiple selected ids merge into one result map, and a selected id with no matching content just yields no entry rather than an error.

## Testing Infrastructure Notes (map integration, 2026-07-27)

Getting `flutter test` reliably green after the map integration surfaced two real, non-obvious issues worth remembering:

- **Real async I/O (asset loading) inside a `testWidgets` body needs `tester.runAsync()`.** Directly `await`-ing a Future backed by `rootBundle.loadString(...)` in a `testWidgets` callback can hang indefinitely — the fake-async zone `testWidgets` runs in doesn't reliably deliver real I/O completions on its own. `tester.runAsync()` is the documented escape hatch: it steps outside the fake-async zone to run genuinely async work, then hands control back. Plain `test()` functions (like `content_repository_test.dart` uses) don't have this problem at all, since they're not wrapped in that zone.

- **`widget_test.dart` was split into `app_boot_test.dart` + `widget_test.dart`.** The original single file mixed a test that needs the map (`AroundTheWordApp`, pulls in `countries_world_map`) with one that doesn't (the category→vocab flow, which starts from a pre-seeded `TripSelection`). Since Flutter compiles per test *file*, the flow test was paying the cost of compiling the map package's ~290KB embedded data despite never using it — and once, that compile got stuck (0% CPU for 8+ minutes, not just slow) after several killed-mid-compile runs left the incremental compiler cache in a bad state, requiring `rm -rf build/test_cache build/unit_test_assets` to clear. Splitting the files means the flow test's dependency graph no longer includes the map at all, so it can't be dragged into that compile cost or that class of failure again.

## Open Questions

- Placeholder content (`food-cooking`, `museums`, `hiking`) needs to become real, reviewed Costa Rica vocab — next step is running actual content through `tools/vocab_tagger/` rather than hand-writing tagged JSON.
- Flashcard visuals (flip animation, swipe gestures) are intentionally minimal right now — worth a pass once the core flow is validated, not before.
- Continent-tap is currently a real geographic tap (see `continent_zoom_bounds.dart`'s discussion) — hand-drawing a simplified/stylized continent picker instead was discussed as a way to keep tap targets large and simple per the design doc's own intent, decoupled from the country-level map's real geography. Not started.

## Explicitly Not Done Yet

- No git commit of this work.
- No accounts, persistence, or backend — matches current V1 scope exactly, not a gap.
- No exercise UI beyond flashcards (fill-in-blank, matching) — deferred per the roadmap, tags are captured but unused.

---

## Current State (of the original English MVP build, historical)

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
