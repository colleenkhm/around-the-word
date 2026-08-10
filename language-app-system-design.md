# Around the Word: System Design & Roadmap

> **⚠️ Superseded as of 2026-08-06.** The no-backend, static-bundled-JSON premise this whole doc is built on is gone — the app pivoted to a Supabase/Postgres backend with a curated travel database as the actual product, per Colleen's explicit instruction to override this doc's direction "even if it means rearchitecture." The three current docs are:
> - [around-the-word-client-design.md](around-the-word-client-design.md) — screens, flows, client state, offline caching (supersedes this doc's sections 1, 2, and most of 4)
> - [around-the-word-data-architecture.md](around-the-word-data-architecture.md) — schema, backend, client data objects (supersedes this doc's section 3, most of 5)
> - [around-the-word-scratch-notes.md](around-the-word-scratch-notes.md) — loose ends, not decisions
>
> Kept below as history, same as [app-design-doc.md](app-design-doc.md) and the pre-pivot parts of [HANDOFF.md](HANDOFF.md) it itself superseded. Nothing below this notice is current.

*Living doc, built section by section as we work through it. This is the current authoritative plan for the app — supersedes the activity/exercise/vocab-tagging direction explored in [app-design-doc.md](app-design-doc.md) and [HANDOFF.md](HANDOFF.md); see the superseded-notice at the top of each for what changed and why.*

---

## Product Vision (End State)

**Name: Around the Word.** A country-prep dashboard for travelers, opened by selecting a destination. Full end-state concept, not all required for V1:

- **Language (the flagship feature, and V1's actual scope)** — the personalized dictionary, learn/use split, flashcards already designed below
- **Weather** — expected conditions for the destination around the time of the trip
- **Friend-sourced travel tips** — real advice from people who've actually been there, sourced from Colleen's own travel network directly rather than an open crowdsourcing system. This solves the content problem differently than language content does: it's not written from scratch, it's collected and curated from people who already have it.
- **Music** — an embedded playlist of music from the destination
- **Word of the Day** — a dashboard widget and lock-screen/notification feature, thematically the app's namesake. Ties directly to the local-notification roadmap idea below.

**Why this section exists:** so V1's scope stays deliberately small without losing sight of where it's going. The country-keyed data pattern already established below is what makes this vision buildable in stages without a redesign each time — but "one JSON file per feature per country" turns out not to be the right shape for all four future features equally; see **Data shape for future dashboard features** in section 3 for the actual per-feature breakdown (curated file, scalar field, live API call, or derived view) and how country-level availability generalizes once there's more than one feature to gate.

---

## Foundational Decisions (made this session)

- **Platform:** Flutter mobile app (matches existing nightglow.studio stack/experience)
- **Content storage, V1:** static JSON bundled with the app — no backend, no database. Content size (a handful of destinations, ~11 categories) fits comfortably in a file you edit directly and rebuild. Revisit only when content needs to update without a rebuild, or once user-generated content (the future social layer) requires a real backend.
- **Accounts, V1:** none. Browse-only. No feature in V1 actually needs a login (no favorites, no social layer yet) — add auth when a real feature requires it, not preemptively.
- **Net effect:** V1 has no backend at all. It's a self-contained Flutter app reading local data. This is what makes the 5-8 hrs/week budget realistic.

---

## 1. Requirements & Scope (revised)

**What V1 does now:** user opens the app to a "Where are you going?" home screen with a simple search field — type or select a country by name, no map. Every country in the searchable list leads somewhere: if it has real content, the user moves into the full flow (category checkboxes → personalizing → learn/use); if it doesn't yet, they land on a **"coming soon" screen** with a short message and a couple of general-purpose resource links, so the app is never a dead end for any destination. From there, for countries with real content: category selection (checkboxes, multi-select), a "personalizing your dictionary" loading screen — cosmetic in V1 (just filtering local bundled data), but architected to be swapped later for real computation without a UX rework — then **Learn** (flashcards, randomized/session-only, no persistence in V1) or **Use** (category list → vocab list, plus a per-category flashcard option on the vocab list screen itself).

**Why search over the map:** broad day-one usefulness — being able to type any country and get *something*, even a placeholder — matters more than a polished visual selector. It also removes the single highest-effort, highest-risk piece of the earlier design (country-boundary hit-testing, continent-then-country map components) in favor of a text field and a filtered list, which is both simpler to build and better suited to the actual goal here.

**Why this over pure vocab lists:** a static, non-interactive list risks being closer to a phrasebook than a learning tool. The learn/use split — already present in the original design doc as a deferred idea — gives the app an actual reason to be an app rather than a PDF.

**What's still explicitly out of scope for V1:** accounts, persistent flashcard progress, real backend-driven personalization, trip/itinerary planning, group features, social layer (liking phrases, place recommendations).

**Country/content scope:** one country of real, curated content to start (Costa Rica, Spanish). Every other country is still visible and selectable through search — they just route to the coming-soon screen instead of the full flow until their own content file is added. This is a meaningfully broader day-one footprint than the earlier "grayed out/inactive" map treatment, without requiring any more content to be curated up front. (See section 3 for why content is organized per country rather than per language.)

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

1. **Home screen ("Where are you going?")** — a search field over a list of countries, filtered as the user types (or a simple scrollable list if not typing). No map, no continents. Every country in the list is tappable — nothing is blocked or grayed out.
2. **Branch on content availability:**
   - **Content exists →** Category selection screen (checkboxes, multi-select — parent categories only; sub-subjects are handled inside whichever mode the user picks next).
   - **Content doesn't exist yet →** Coming-soon screen: a short "we're working on content for [Country], here in the meantime" message plus a couple of general-purpose resource links (see Data Model for how these are sourced). Dead end by design — no further app flow for this country until content ships.
3. **"Personalizing your dictionary" loading screen** (content-exists branch only) — cosmetic in V1, filters the local content down to just the selected categories for the selected country. Built as an async-shaped function even though it's doing synchronous local work, specifically so a real backend call can replace it later without touching the UI.
4. **Learn / Use choice screen** — the fork.
   - **Learn →** flashcards, deck built from *all* selected categories mixed together. Order randomized each session, no progress saved between opens.
   - **Use →** category list (only the categories the user selected in step 2) → tap a category → vocab list (phrase + translation) → **plus a "flashcards for this category" option right on the vocab list screen**, launching the same flashcard component as Learn mode, just scoped to that one category's phrases instead of the full mixed set. Sub-subjects (Cooking vs. Grocery Shopping under Food) still get their own screen here if the selected parent category has them.

**Resolved:** the flashcard component takes a phrase list as input and doesn't care where that list came from — the same widget serves both the all-categories Learn deck and the single-category Use deck. One build, two entry points.

---

## 3. Data Model

**Resolved: V1 ships with one country of real content (Costa Rica)**, and the whole app is organized by country throughout — not by language. This matters beyond naming: two countries that happen to share a language (e.g. Mexico and Argentina, both Spanish-speaking) still get their own separate content files, because the app's organizing unit is the destination, not the language spoken there. This also leaves room for country-specific nuance later (regional slang, country-specific tips, weather, music — all of which are inherently about the country, not the language) without needing a redesign. The country list and its associated "coming soon" fallback are built generically from the start — every country is selectable through search, it just routes differently depending on whether content exists. Adding a second country later means adding a new content file for that country and flipping its `active` flag, nothing else changes.

**File structure:**

`countries.json` — every country the search list should include, with an active flag. `languageCode` is kept as *descriptive metadata only* (useful for display, e.g. showing "Spanish" under Costa Rica) — it is never used to look up content, since content is always looked up by country code. `continent` is likewise kept as optional metadata — no longer required for any UI logic now that the map is gone, but still useful as a hook for reintroducing continent-based browsing later:
```json
[
  { "countryCode": "CR", "name": "Costa Rica", "continent": "north-america", "languageCode": "es", "active": true },
  { "countryCode": "MX", "name": "Mexico", "continent": "north-america", "languageCode": "es", "active": false },
  { "countryCode": "FR", "name": "France", "continent": "europe", "languageCode": "fr", "active": false }
]
```

`resources.json` — the generic links shown on the coming-soon screen. **Recommendation: one shared set of general-purpose links reused across every uncovered country (e.g. a translation tool, a general phrasebook site), rather than curating unique links per country.** Curating per-country resources for "most countries" would be a real content burden that undercuts the whole point of keeping V1 lean — a shared fallback gets the "never a dead end" goal at effectively zero extra content cost:
```json
[
  { "label": "Google Translate", "url": "https://translate.google.com" },
  { "label": "General phrasebook", "url": "..." }
]
```

`subjects.json` — shared across all countries/languages, since the categories themselves (Food, Transportation, etc.) don't change by destination:
```json
[
  { "id": "food", "name": "Food", "parentId": null },
  { "id": "food-cooking", "name": "Cooking", "parentId": "food" },
  { "id": "food-grocery", "name": "Grocery Shopping", "parentId": "food" },
  { "id": "museums", "name": "Museums", "parentId": null }
]
```
A subject with `parentId: null` and no children is a flat category. A subject with children is a parent category with its own sub-subject screen. Same shape as before.

`content/{countryCode}.json` — **one file per country, not per language** (Costa Rica/Mexico/Argentina etc. can each have their own regionally-accurate vocab even though they share a language — see the "Resolved" paragraph above for why). Phrases keyed by subject id:
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

`countries.json`'s `languageCode` field is still useful (it's what would drive e.g. UI copy or any future language-aware logic), but content lookup itself keys off `countryCode`.

**The "personalized dictionary" is not new data — it's a filtered view.** Given a selected country and a set of selected category ids, the "personalizing" step just pulls the matching entries out of that country's content file into an in-memory list. That in-memory list is what both Learn (flashcards) and Use (category list) read from. This keeps V1 fully backend-free — the personalization step is a filter function, not a fetch, even though it's built to look and behave like one.

### Data shape for future dashboard features (planning ahead, not built in V1)

Not every feature in the Product Vision fits the "curated file per country" pattern language uses — forcing all of them into that one shape would be a mismatch for at least two of them. Four different shapes, by feature:

1. **Static curated collections** (Language, and later Friend-sourced tips) — real content someone authors and reviews, naturally a list. Own file per country: `content/{cc}.json` (exists), `tips/{cc}.json` (V3.5). This is the pattern that's actually earning its "own file" treatment.
2. **Simple scalar references** (Music) — a country doesn't need a whole *file* for "here's the playlist URL," it needs one field. This belongs directly on the country record in `countries.json` (e.g. `musicPlaylistUrl`), not a separate `music/{cc}.json`.
3. **Live/dynamic data** (Weather) — not bundled content at all. As section 6 (V1.5) already notes, this is the one piece that breaks the zero-backend rule — it's a runtime API call keyed by the country (likely lat/long or a weather-service city id stored on the country record), not a JSON file in `assets/`.
4. **Derived views** (Word of the Day) — no new data needed at all. It's "pick one entry from that country's existing `content/{cc}.json` today," the same "filtered view, not new data" philosophy already used for the personalizing step above.

**`active` doesn't generalize past one feature.** Right now `active: bool` gates the one feature that exists (language). Once a country can have language content but no tips yet, or tips but no music, a single boolean can't express that — it needs to become per-feature availability. When V1.5+ features actually get built, the plan is to replace the flat `active` flag with a `features` map on the country record:
```json
{
  "countryCode": "CR",
  "name": "Costa Rica",
  "continent": "north-america",
  "languageCode": "es",
  "musicPlaylistUrl": null,
  "features": { "language": true, "tips": false, "music": false }
}
```
`weather` and `wordOfDay` deliberately aren't in `features` — their availability is computed, not flagged: weather from whether the live API call succeeds, word-of-day from whether `features.language` is true. This keeps `countries.json` as the cheap index the destination/dashboard screens check to decide what to show, without needing to touch weather's live API or open every country's content file just to know what's available. **Not built now** — V1 only has language, so the existing single `active` flag is still the right amount of structure; this is here so the migration is a known, deliberate step rather than a surprise refactor when V1.5 starts.

## 4. Architecture & Tech Stack

- **Framework:** Flutter (existing skill, matches nightglow.studio)
- **Content:** static JSON files bundled as Flutter assets (`assets/data/countries.json`, `assets/data/resources.json`, `assets/data/subjects.json`, `assets/data/content/{countryCode}.json` — one file per active country, organized by country code, not language) — no server, no database, no network calls in V1
- **Country search:** a text field + filtered list (filter `countries.json` by name as the user types), no map dependency at all. This is a meaningfully simpler and lower-risk build than the earlier map-based approach — a standard searchable list, not a custom interactive-graphics component. (A real map was in fact prototyped and wired in on a dedicated branch before this call was made — see HANDOFF.md's map-integration notes — kept for the record in case map-based destination picking gets revisited.)
- **State management:** still light — needs to hold selected country, selected categories, and the filtered/"personalized" phrase list across four screens (down from five now that the continent step is gone). `Provider` (or `Riverpod` if a bit more structure is wanted) is a reasonable fit.
- **Navigation:** Flutter's `Navigator`, four screens deep in the main flow (Search → Categories or Coming-soon → Personalizing → Learn/Use) before even reaching the original vocab-list depth
- **Flashcards:** a simple flip-card widget (front/back state, tap or swipe to flip, swipe or button to advance), deck order shuffled once per session. Built to take any phrase list as input, so it serves both entry points without duplication — the mixed-categories Learn deck, and the single-category deck launched from the vocab list screen in Use mode. No spaced-repetition logic in V1 — that's a natural, self-contained addition later once progress-tracking exists.
- **Loading animation:** purely cosmetic in V1 — an animated transition with a short artificial delay, not tied to any real async work yet. Should be built as a real `async`/`await` step in the code (even though it's just `await Future.delayed(...)` for now) so swapping in a real network call later is a one-line change, not a restructure.
- **Persistence:** still none needed in V1 — no accounts, no saved flashcard progress, app resets each launch
- **Hosting/distribution:** none needed for a first real test — sideloaded or shared as a TestFlight/internal build to the handful of real users targeted for the first ship, before ever considering app store distribution

## 5. API / Data-Fetching Design

Still no real backend in V1 — the "personalizing" step is a local filter function shaped to look like an API call, not an actual one. This is worth restating because it's easy to accidentally build a real backend just because the UI implies one exists; the whole point of this design is that V1 stays backend-free while still *feeling* like it's doing something smart.

**When this changes:** the moment real computation is wanted behind "personalizing your dictionary" (the stated eventual goal), or once accounts/persistent flashcard progress are added. At that point, a lightweight backend (Firebase/Supabase are common fits for this scale) is the likely next step — and because the filter function was already built async-shaped, the swap touches one function, not the whole app.

## 6. Roadmap

**V1 (Jan-Aug 2027, per the career/roadmap timeline):** Search → Categories or Coming-soon → Personalizing (cosmetic) → Learn/Use flow. One country of real content (Costa Rica, Spanish); every other country in the searchable list gets the coming-soon screen with shared generic resource links rather than being hidden or blocked. Flashcards (session-only, no persistence) and category-based vocab lists both live in V1. No accounts, no backend. Shipped to a small real group of actual travelers, not an app store launch. **Dropping the map in favor of search meaningfully reduces build risk versus the prior version — worth noting as the scope has both grown (learn/use, flashcards, broad country coverage via coming-soon) and simplified (no map) since the original bare-list plan, so the net effort is genuinely hard to estimate precisely. Check progress against the timeline a few weeks in.**

**V1.1 — second country:** the test of whether the per-country content model holds up — add a new content file (e.g. Mexico or Argentina), flip a second country's `active` flag, confirm that country now shows the full flow instead of coming-soon, with no other changes needed. Since content is already keyed by country rather than language, this also doubles as practice for the eventual second-language case, just without a new `languageCode` yet.

**V1.2 — second language:** first country whose `languageCode` isn't `es` (e.g. France/French). Tests that the coming-soon/full-flow branch genuinely doesn't care which language is behind a country, only this doc's earlier language-agnostic design intent is finally exercised for real.

**V1.5 — weather + music:** the two cheap dashboard additions from the Product Vision above. Weather is the one piece that breaks V1's zero-backend rule (needs a live API call), but it's a single contained integration, not a general backend. Music is just an embedded playlist per country, no real engineering lift. Both slot onto the same country-selection screen the language flow already uses. This is also the point the `active` flag needs to become a `features` map — see "Data shape for future dashboard features" in section 3.

**V2 — real personalization:** replace the cosmetic "personalizing your dictionary" filter with actual computation — this is the point the loading screen's async-shaped placeholder function gets swapped for a real call. Likely also where accounts arrive, since real personalization pairs naturally with saved preferences and persistent flashcard progress.

**V3 — social layer:** liking phrases that came in handy while actually traveling, recommending places tied to location. Builds on the V2 accounts/backend work. This is the point the app starts generating its own usage data — which phrases/subjects are actually most useful per destination — rather than relying on assumptions from the original content curation.

**V3.5 (or parallel to V3) — friend-sourced travel tips:** a `tips.json` per country, same shape as the content files elsewhere in this doc. The sourcing model is deliberately different from the language content though — rather than Colleen curating tips from research the way phrase content gets curated, this is collected directly from her own network of well-traveled friends. No submission UI needed at this stage — could start as simple as a shared doc or form she personally compiles into the JSON file, with an open crowdsourcing submission system (if ever built) as a much later, separate step layered on top of the V3 social/accounts groundwork.

**V4 (or later) — location-aware word of the day:** the app's namesake feature. A lock-screen/notification prompt and dashboard widget showing a relevant word or phrase for whatever country the user is currently traveling to. No new content file — per section 3's data-shape breakdown, this is a derived view that picks one entry from that country's existing `content/{cc}.json`, not new data to author. **Implementation note for when this gets built:** this almost certainly doesn't need true push notifications (server-triggered, requiring a backend and APNs/FCM integration) — Flutter supports *local* notifications, scheduled entirely on-device from already-bundled content, no server required. The simpler version — "which country did the user most recently select in-app" rather than real-time GPS detection — is the natural first cut; GPS-based auto-detection would be a further-later refinement layered on top, and would need location-permission handling this doc hasn't scoped yet.

**Later, master's-dependent:** the "Second Convergence Point" from the career/roadmap doc — personalized, itinerary-aware lesson generation, drawing on real SLA theory across languages. The V2 "real personalization" work is a direct, smaller-scale preview of this — not a separate track, an earlier step on the same path. *(This is also where the trip/activity-specific curation and grammar-aware exercise work explored in [app-design-doc.md](app-design-doc.md) could resurface — it's shelved for V1-V3, not discarded.)*

**Explicitly not on this roadmap:** trip/itinerary planning, group features, the travel-planner-with-social-voting app. Deferred per the earlier decision, revisited only if V1-V3 generate a real reason to.
