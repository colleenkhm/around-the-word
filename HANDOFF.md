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

The five-screen flow from `language-app-system-design.md` is built and wired end to end, backed by placeholder content: Continent list → Country list (with search) → Category checkboxes → cosmetic "Personalizing your dictionary" step → Learn/Use fork. Learn opens a shuffled flashcard deck of everything selected; Use goes to a category list → (sub-subjects, if any) → vocab list, with a per-category flashcard option. One country is active (Costa Rica/`cr`), with three inactive placeholders (Mexico, Argentina, France) to exercise the "grayed out" and multi-continent paths. Content is placeholder — a handful of tagged entries under `food-cooking`, `museums`, and `hiking` — not real Costa Rica vocab yet. `flutter analyze` and `flutter test` both pass.

## Implementation Decisions

- **State management: `provider`, not `riverpod`.** The doc left this open ("Provider, or Riverpod if a bit more structure is wanted"). Went with `provider` since the actual state shape is one flat `ChangeNotifier` (`TripSelection`) read by every screen — Riverpod's extra structure (providers-of-providers, code-gen) isn't earning its keep at this size. Revisit if state gets meaningfully more complex.

- **The continent/country maps are placeholder lists, not real maps.** The design doc explicitly calls out evaluating a Flutter map/SVG package as separate follow-up work — building that now would have blocked the whole flow on a UI/rendering decision unrelated to data model or navigation. `ContinentMapScreen`/`CountryMapScreen` are drop-in replaceable: they read the same `TripSelection` data a real map would.

- **One recursive `CategoryListScreen` instead of separate parent/child screens.** Use mode needs a category list, and (for categories with sub-subjects) a second screen showing just those sub-subjects. Rather than two widgets, `CategoryListScreen` takes an optional `subjectsToShow`/`title` and pushes itself again for a tapped subject's children when it has any, or a `VocabListScreen` when it doesn't. Same pattern the original English MVP used for the category→subject skip logic, just generalized to arbitrary depth instead of hardcoded to one level.

- **`TripSelection.personalize()` is written as a real `async` step**, even though today it's just a local map filter plus an artificial `Future.delayed(900ms)` for the cosmetic loading screen — per the doc's explicit instruction that this should be a one-line swap to a real backend call later, not a restructure.

- **Content files are looked up as `content/{countryCode.toLowerCase()}.json`** (e.g. `cr.json`) — lowercased so the convention doesn't depend on remembering to match `countries.json`'s casing exactly.

- **Flashcards use tap-to-flip + next/previous, no swipe gesture or flip animation.** The doc only specifies "tap or swipe to flip, swipe or button to advance" — went with the simpler half (tap, buttons) for the scaffold; swipe gestures and a real flip animation are additive, not a rework, if wanted later.

- **Deleted the old English-MVP `lib/` files** (`models/vocab_category.dart`, `data/vocab_data.dart`, the three old screens) rather than keeping them alongside the new structure — they're preserved in git history (commit `bdf23b2`), and keeping unused code around would just be confusing dead weight given the new doc fully supersedes that direction.

- **Data models and JSON loading/parsing have dedicated unit tests, separate from the end-to-end widget test.** `test/models/*_test.dart` covers `Country.fromJson`/`VocabEntry.fromJson`/`Subject.fromJson` plus the `SubjectListX` tree helpers (`topLevel`, `childrenOf`, `idAndDescendantIds` — including a synthetic three-level tree, since the real `subjects.json` is only two levels deep and wouldn't otherwise exercise deeper recursion). `test/data/content_repository_test.dart` loads the real bundled `assets/data/*.json` (catches malformed placeholder JSON directly, not just via the UI flow) and exercises `personalize()`'s filtering rules: a parent id pulls in its children's content but not its own (parents don't carry phrases directly), multiple selected ids merge into one result map, and a selected id with no matching content just yields no entry rather than an error. 23 tests total, all passing alongside the original end-to-end widget test.

## Open Questions

- Real map rendering for the continent/country screens — which package, and how much of a scope item that is on its own, is still unevaluated. **Approach decided (2026-07-27):** prototype the continent-tap and country-tap-with-search interactions in isolation, standalone, before wiring either into the real screens/navigation — and do that work on its own branch, not on top of the current scaffold.
- Placeholder content (`food-cooking`, `museums`, `hiking`) needs to become real, reviewed Costa Rica vocab — next step is running actual content through `tools/vocab_tagger/` rather than hand-writing tagged JSON.
- Flashcard visuals (flip animation, swipe gestures) are intentionally minimal right now — worth a pass once the core flow is validated, not before.

## Explicitly Not Done Yet

- No git commit of this scaffold.
- No real continent/country map rendering (see Open Questions).
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
