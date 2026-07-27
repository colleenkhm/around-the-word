# Language App: System Design & Roadmap

*Living doc, built section by section as we work through it. This is the current authoritative plan for the app — supersedes the activity/exercise/vocab-tagging direction explored in [app-design-doc.md](app-design-doc.md) and [HANDOFF.md](HANDOFF.md); see the superseded-notice at the top of each for what changed and why.*

---

## Foundational Decisions (made this session)

- **Platform:** Flutter mobile app (matches existing nightglow.studio stack/experience)
- **Content storage, V1:** static JSON bundled with the app — no backend, no database. Content size (a handful of destinations, ~11 categories) fits comfortably in a file you edit directly and rebuild. Revisit only when content needs to update without a rebuild, or once user-generated content (the future social layer) requires a real backend.
- **Accounts, V1:** none. Browse-only. No feature in V1 actually needs a login (no favorites, no social layer yet) — add auth when a real feature requires it, not preemptively.
- **Net effect:** V1 has no backend at all. It's a self-contained Flutter app reading local data. This is what makes the 5-8 hrs/week budget realistic.

---

## 1. Requirements & Scope (revised)

**What V1 does now:** user opens the app to a "Where are you going?" home screen with a simplified world map divided by continent. Tapping a continent opens a zoomed-in map of just that continent, with individual countries tappable or searchable by name. If the selected country's language has content, they select which categories they want (checkboxes, multi-select). A "personalizing your dictionary" loading screen plays — cosmetic in V1 (just filtering local bundled data), but architected to be swapped later for real computation without a UX rework. From there, the user chooses **Learn** (flashcards, randomized/session-only, no persistence in V1) or **Use** (category list → vocab list, the original fast-reference flow, plus a per-category flashcard option on the vocab list screen itself).

**Why this over pure vocab lists:** a static, non-interactive list risks being closer to a phrasebook than a learning tool. The learn/use split — already present in the original design doc as a deferred idea — gives the app an actual reason to be an app rather than a PDF.

**What's still explicitly out of scope for V1:** accounts, persistent flashcard progress, real backend-driven personalization, trip/itinerary planning, group features, social layer (liking phrases, place recommendations).

**Language scope:** Spanish is the first language. Content is scoped **per country, not per language** — regional food names, customs, and slang genuinely differ between, say, Mexico, Costa Rica, and Argentina even though the language is the same, so a single shared "Spanish" content file would flatten exactly the kind of place-specific detail that makes the vocab feel real. The map/category UI doesn't change for this — it's a change to how content is looked up, not how it's browsed (see the Data Model section below for the file-structure update this implies). The country map can still show all countries, with ones lacking content grayed out/unselectable; unsupported (non-Spanish) countries stay grayed out until a second language is added.

**Subject list (v1 draft, unchanged, 11 categories, several with sub-groups):**
- Food (cooking, grocery shopping)
- Shopping (malls, souvenirs)
- Hiking / the outdoors
- Talking about family
- Talking about aesthetics
- Transportation (airports/flying, bus stations, taxis)
- Talking about houses
- Museums
- Music
- Occupations
- Speaking casually
- Celebrations (wedding, graduation, birthday, holiday)
- TV shows / movies
- Going to a party

---

## 2. User Flows (revised)

**Confirmed screen flow for V1:**

1. **Home screen ("Where are you going?")** — simplified world map divided by continent, not individual countries. Only a handful of large tappable regions (7 continents), which keeps this level genuinely easy on a small screen. Continents with no active content anywhere in them (Asia, Africa, Australia, at least at first) are grayed out/inactive from the start — same treatment as inactive countries elsewhere in this doc, just one level up.
2. **Continent map screen** — a zoomed-in map of just the tapped continent, individual countries now tappable, plus a text search field as a fallback for finding a country by name rather than relying on precise taps. Countries with content are selectable; others are grayed out/inactive.
3. **Category selection screen** — checkboxes for the subject categories, multi-select (Food, Shopping, Hiking, etc. — parent categories only; sub-subjects are handled inside whichever mode the user picks next, see below).
4. **"Personalizing your dictionary" loading screen** — cosmetic in V1, filters the local content down to just the selected categories for the selected country. Built as an async-shaped function even though it's doing synchronous local work, specifically so a real backend call can replace it later without touching the UI.
5. **Learn / Use choice screen** — the fork.
   - **Learn →** flashcards, deck built from *all* selected categories mixed together. Order randomized each session, no progress saved between opens.
   - **Use →** category list (only the categories the user selected in step 2) → tap a category → vocab list (phrase + translation) → **plus a "flashcards for this category" option right on the vocab list screen**, launching the same flashcard component as Learn mode, just scoped to that one category's phrases instead of the full mixed set. Sub-subjects (Cooking vs. Grocery Shopping under Food) still get their own screen here if the selected parent category has them.

**Resolved:** the flashcard component takes a phrase list as input and doesn't care where that list came from — the same widget serves both the all-categories Learn deck and the single-category Use deck. One build, two entry points.

---

## 3. Data Model

**Resolved: V1 ships with one language of real content (Spanish)**, but the map/category UI is built generically from the start — countries without content simply aren't selectable yet. Adding a second country means adding a new content file and marking that country active on the map; adding a second language later means the same, plus a new `languageCode` showing up in `countries.json`.

**File structure:**

`countries.json` — maps countries to a continent and a language code, and marks which ones are active:
```json
[
  { "countryCode": "CR", "name": "Costa Rica", "continent": "north-america", "languageCode": "es", "active": true },
  { "countryCode": "MX", "name": "Mexico", "continent": "north-america", "languageCode": "es", "active": false },
  { "countryCode": "FR", "name": "France", "continent": "europe", "languageCode": "fr", "active": false }
]
```
A continent is treated as active on the home screen if at least one of its countries has `active: true` — no separate continent-level flag needed, it's derived from the country list. This keeps "block out Asia, Africa, Australia at the start" a simple consequence of which countries have content, not a separate thing to maintain.

`subjects.json` — shared across all countries/languages, since the categories themselves (Food, Transportation, etc.) don't change by destination:
```json
[
  { "id": "food", "name": "Food", "parentId": null },
  { "id": "food-cooking", "name": "Cooking", "parentId": "food" },
  { "id": "food-grocery", "name": "Grocery Shopping", "parentId": "food" },
  { "id": "museums", "name": "Museums", "parentId": null }
]
```
A subject with `parentId: null` and no children is a flat category. A subject with children is a parent category with its own sub-subject screen. Same shape as before — the map/category layer sits on top without changing this.

`content/{countryCode}.json` — **one file per country, not per language** (this is the amendment from this session — content used to be keyed by language code, e.g. one shared `es.json` for every Spanish-speaking country; it's now keyed by country so Costa Rica, Mexico, Argentina, etc. can each have their own regionally-accurate vocab even though they share a language). Phrases keyed by subject id:
```json
{
  "food-cooking": [
    {
      "phrase": "la sartén",
      "translation": "the frying pan",
      "partOfSpeech": "noun",
      "gender": "feminine",
      "number": "singular"
    },
    {
      "phrase": "hervir",
      "translation": "to boil",
      "partOfSpeech": "verb"
    }
  ],
  "museums": [
    {
      "phrase": "la entrada",
      "translation": "the entrance ticket",
      "partOfSpeech": "noun",
      "gender": "feminine",
      "number": "singular"
    }
  ]
}
```
Each entry also carries **grammatical tagging** — `partOfSpeech` (noun/verb/adjective/adverb/expression), and for nouns/adjectives, `gender` (masculine/feminine) and `number` (singular/plural/mass). None of this is read by V1's UI (flashcards and vocab lists just show `phrase`/`translation`) — it's captured now because it's cheap to generate (see the tagging pipeline below) and expensive to backfill later once the fill-in-blank/matching exercises from the earlier pivot come back into scope. `partOfSpeech: "expression"` marks multi-word chunks (e.g. `"¿Dónde está...?"`) that aren't meant to be grammatically decomposed — no `gender`/`number` on those. `number: "mass"` (uncountable nouns, e.g. `"el agua"`) is a manual call, not something a tagger can infer from the word's spelling alone.

**Tagging pipeline:** `partOfSpeech`, `gender`, and grammatical `number` (singular/plural, before any manual mass-noun override) are auto-generated by a one-time/occasional Python script (spaCy, `es_core_news_sm`) run over each `phrase`, reviewed and corrected by hand before content ships — not a runtime dependency of the app. Activity/category tagging stays implicit via which key in the file a phrase is grouped under, rather than a separate many-to-many tag list — that richer tagging only becomes necessary if/when trip-specific activity curation comes back into scope.

`countries.json`'s `languageCode` field is still useful (it's what would drive e.g. UI copy or any future language-aware logic), but content lookup itself now keys off `countryCode`.

**The "personalized dictionary" is not new data — it's a filtered view.** Given a selected country and a set of selected category ids, the "personalizing" step just pulls the matching entries out of that country's content file into an in-memory list. That in-memory list is what both Learn (flashcards) and Use (category list) read from. This keeps V1 fully backend-free — the personalization step is a filter function, not a fetch, even though it's built to look and behave like one.

## 4. Architecture & Tech Stack

- **Framework:** Flutter (existing skill, matches nightglow.studio)
- **Content:** static JSON files bundled as Flutter assets (`assets/data/countries.json`, `assets/data/subjects.json`, `assets/data/content/{countryCode}.json` — one file per active country) — no server, no database, no network calls in V1
- **Interactive map:** now two smaller components instead of one large one — a continent-level map (just 7 large tappable regions, genuinely simple) and a country-level map scoped to whichever continent was tapped (fewer countries, larger on-screen targets, plus a text-search fallback for precision). This split actually reduces the original single-world-map complexity concern — still worth an early session evaluating 1-2 Flutter map/SVG packages, but the country-level maps only need to render one continent's worth of shapes at a time, not all 195 countries at once.
- **State management:** still light, but needs to hold selected continent, selected country, selected categories, and the filtered/"personalized" phrase list across five screens. `Provider` (or `Riverpod` if a bit more structure is wanted) is a reasonable fit; still well short of needing anything heavier.
- **Navigation:** Flutter's `Navigator`, now five screens deep in the main flow (Continent map → Country map → Categories → Personalizing → Learn/Use) before even reaching the original vocab-list depth
- **Flashcards:** a simple flip-card widget (front/back state, tap or swipe to flip, swipe or button to advance), deck order shuffled once per session. Built to take any phrase list as input, so it serves both entry points without duplication — the mixed-categories Learn deck, and the single-category deck launched from the vocab list screen in Use mode. No spaced-repetition logic in V1 — that's a natural, self-contained addition later once progress-tracking exists.
- **Loading animation:** purely cosmetic in V1 — an animated transition with a short artificial delay, not tied to any real async work yet. Should be built as a real `async`/`await` step in the code (even though it's just `await Future.delayed(...)` for now) so swapping in a real network call later is a one-line change, not a restructure.
- **Persistence:** still none needed in V1 — no accounts, no saved flashcard progress, app resets each launch
- **Hosting/distribution:** none needed for a first real test — sideloaded or shared as a TestFlight/internal build to the handful of real users targeted for the first ship, before ever considering app store distribution

## 5. API / Data-Fetching Design

Still no real backend in V1 — the "personalizing" step is a local filter function shaped to look like an API call, not an actual one. This is worth restating because it's easy to accidentally build a real backend just because the UI implies one exists; the whole point of this design is that V1 stays backend-free while still *feeling* like it's doing something smart.

**When this changes:** the moment real computation is wanted behind "personalizing your dictionary" (the stated eventual goal), or once accounts/persistent flashcard progress are added. At that point, a lightweight backend (Firebase/Supabase are common fits for this scale) is the likely next step — and because the filter function was already built async-shaped, the swap touches one function, not the whole app.

## 6. Roadmap

**V1 (Jan-Aug 2027, per the career/roadmap timeline):** Continent map → Country map (with search) → Categories → Personalizing (cosmetic) → Learn/Use flow. One language of real content (Spanish), starting with Costa Rica marked active, its continent therefore active too, everything else grayed out. Flashcards (session-only, no persistence) and category-based vocab lists both live in V1 now. No accounts, no backend. Shipped to a small real group of actual travelers, not an app store launch. **Given the added scope (two-level map, checkboxes, flashcards) vs. the original bare-list version, this is a noticeably bigger build than first scoped — worth checking progress against the timeline a few weeks in, rather than assuming the original hours estimate still holds.**

**V1.1 — second country:** the test of whether the per-country content model holds up — add a new content file (e.g. Mexico or Argentina), mark a second country active, confirm nothing else needs to change. Since content is already keyed by country rather than language, this also doubles as practice for the eventual second-language case, just without a new `languageCode` yet.

**V1.2 — second language:** first country whose `languageCode` isn't `es` (e.g. France/French). Tests that the map/category UI genuinely doesn't care which language is behind a country, only this doc's earlier language-agnostic design intent is finally exercised for real.

**V2 — real personalization:** replace the cosmetic "personalizing your dictionary" filter with actual computation — this is the point the loading screen's async-shaped placeholder function gets swapped for a real call. Likely also where accounts arrive, since real personalization pairs naturally with saved preferences and persistent flashcard progress.

**V3 — social layer:** liking phrases that came in handy while actually traveling, recommending places tied to location. Builds on the V2 accounts/backend work. This is the point the app starts generating its own usage data — which phrases/subjects are actually most useful per destination — rather than relying on assumptions from the original content curation.

**Later, master's-dependent:** the "Second Convergence Point" from the career/roadmap doc — personalized, itinerary-aware lesson generation, drawing on real SLA theory across languages. The V2 "real personalization" work is a direct, smaller-scale preview of this — not a separate track, an earlier step on the same path. *(This is also where the trip/activity-specific curation and grammar-aware exercise work explored in [app-design-doc.md](app-design-doc.md) could resurface — it's shelved for V1-V3, not discarded.)*

**Explicitly not on this roadmap:** trip/itinerary planning, group features, the travel-planner-with-social-voting app. Deferred per the earlier decision, revisited only if V1-V3 generate a real reason to.
