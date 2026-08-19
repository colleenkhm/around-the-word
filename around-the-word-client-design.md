# Around the Word: Client & UX Design

*Living doc. Covers the Flutter app — screens, flows, navigation, state, and client-side behavior.*

**Scope boundary:** this doc owns everything the user sees and touches. The companion **Data Architecture** doc owns the database, schema, API, and data object shapes. Where they touch (what the app fetches, how it caches), this doc defers to that one. If they ever disagree, the data architecture doc is correct.

---

## Product Vision (End State)

**Around the Word** — a country-prep dashboard for travelers, opened by selecting a destination. Not all of this is MVP:

- **Language** — vocabulary and phrases organized by travel activity, with learn/use modes
- **Weather** — expected conditions around the time of the trip
- **Travel advisories and visa info** — attributed, dated, linked to official sources
- **Practical guidance** — practical basics (tipping, punctuality), dress expectations, best times to visit, points of interest (landmarks, restaurants, neighborhoods), cuisine
- **Friend-verified content** — social norms, taboos, and other interpretive guidance, checked against people who actually went (the kind of content where sources can genuinely disagree, so it waits for verification rather than being asserted from research alone)
- **Word of the Day** — dashboard widget and lock-screen notification; the app's namesake feature
- **Trip dashboards** (phase 2) — days until trip, checklists, pinned content, multi-country itineraries
- **Social layer** (phase 3) — shared trips, group planning, friends' advice
- **Trip diary & photo feed** (phase 3+, not yet scoped) — a diary of photos and notes per trip activity, calendar-style layout floated as one option; entries marked public surface in a scrollable photo feed on that country/city/activity page, for other users still deciding where to go. Builds on trip dashboards (phase 2) and the social layer (phase 3). See Roadmap and Open Questions.

**The differentiator** is not exclusive information — most of it is findable across fifteen browser tabs. It's aggregation plus verification: everything a traveler needs in one place, checked against firsthand experience, framed around an actual trip.

---

## MVP Scope

**V1 is country pages, read-only, no accounts.** A user searches for a country and gets a single page pulling together what they'd otherwise assemble themselves.

**In scope:** country search, country page (facts, guide content, points of interest, advisories, visas, weather), language content with learn/use modes, flashcards, a coming-soon *state* for uncovered countries (see below — no longer a separate screen).

**Out of scope for V1:** accounts, trip dashboards, checklists, pinning, word-of-the-day notifications, anything social. All have schema defined in the data architecture doc so they don't require redesign — they just aren't built.

**Country coverage at launch:** countries with real content are fully browsable; everything else is searchable and routes to the same country page, every section reading "coming soon" — see step 2 below. No country is hidden or blocked.

---

## Platform & Stack (client only)

- **Flutter** — matches existing experience (nightglow.studio)
- **State management:** `Provider` or `Riverpod`. The app holds selected country, selected categories, filtered content, and cached bundles — real but modest state, well short of needing anything heavier.
- **Navigation:** Flutter's `Navigator`. Flow depth is four to five screens; no routing package needed.
- **Local storage:** required for offline caching (see below). **Resolved: a key-value/object store (`hive`, or `hive_ce`/`sembast` if Hive's maintenance status looks shaky at build time), not `sqflite`.** `CountryBundle` is fetched, cached, and read as one denormalized whole — no on-device relational queries in V1 — so a key–blob store matches the access pattern directly, without re-normalizing the API layer's flattened bundle back into SQL tables. Revisit only if a later phase needs on-device queries across bundles (see Open Questions).
- **Backend:** Supabase. See the data architecture doc.

---

## Offline Behavior

**Not optional.** Users are abroad, roaming, frequently without data — precisely when phrases and practical guidance matter most.

**Pattern:** fetch a country's full content bundle once, cache it locally, read from cache thereafter, refresh opportunistically when connected. A user who loads Portugal in an airport has everything on the plane and on the ground.

**Exceptions: weather and currency conversion.** Both fetched live, cached briefly, never bundled — the two genuinely time-sensitive fields, where caching a stale value for weeks would be worse than not showing one at all.

**UI implication:** the app should indicate when content is being served from cache and how old it is, especially for advisories and visa info where staleness matters. The data model carries verification dates for exactly this reason.

---

## Screen Flows

### Primary flow

1. **Home — "Where are you going?"**
   A search field over the country list, filtered as the user types. Scrollable list when not typing. Every country is tappable; nothing is hidden or greyed out.

2. **Every country opens the same country page** (revised 2026-08-18 — see below; previously branched on content availability into a separate coming-soon dead end)
   - **Content exists →** every section shows real content.
   - **No content yet →** the same country page, with every section expanded to "Coming soon" instead of being omitted or dead-ending. Honest rather than empty, same reasoning the old coming-soon screen had — just folded into the page itself instead of a separate screen, so a partially-covered country (some sections real, some "coming soon") isn't an awkward middle case between two different screen types.

   **2026-08-18, per Colleen: "instead of the coming soon page we should just have a country page showing any available data where the expanded categories say 'coming soon.'"** The old dedicated coming-soon screen (short message + generic resource links, `coming_soon_resources` table) is retired from this flow — see HANDOFF.md for the implementation. The generic-resources mechanism itself isn't deleted from the data architecture doc; it's just unused for now. Worth revisiting whether those resource links resurface *inside* an empty section (e.g. a "Coming soon" Language section linking out to Google Translate) rather than being dropped entirely — not decided yet, see Open Questions.

3. **Country page**
   The core V1 screen, organized as **five tabs**, grouped along the trust-tier split that's the spine of the data architecture (commodity / curated / legally-sensitive), rather than as a long scroll:
   - **Overview** — facts (flag, capital, currency, languages), weather, live currency conversion from USD, best times to visit — **a bare list of months is not acceptable output**; every month or window renders with its `why_short` reason in parentheses on mobile (e.g. *September (dry season)*) or in a partner column on desktop, since without it the section is indistinguishable from a weather average anyone could look up — the reason is the curated judgment (see data architecture doc's `why_short`/`why` split) — practical basics (tipping, punctuality, recommended transport app — `tipping_norm`/`punctuality_norm`/`transport_norm`, each its own standalone type, independently filterable/removable; see data architecture doc's `practical_norms`), and a compact **Cities** list — featured/major cities (`Cities.is_featured`/`is_major`) with a short blurb. V1: informational only, not yet linking to a dedicated city page (see below)
   - **Explore** — points of interest: landmarks, restaurants, neighborhoods, filterable by `poi_type`. **Grouped by city** where a POI has a `city_id` (Acropolis under Athens, Christ the Redeemer under Rio); POIs without one — genuinely regional sites like Delphi, Meteora, or Neuschwanstein, which aren't meaningfully "near" any single profiled city — display under a **Regional** heading instead of being forced onto a nearest-city guess that would misrepresent the geography. Split out from Guide once landmark-heavy countries (Greece) made clear that points of interest would outnumber everything else combined — a separate tab rather than a subsection avoids narrative content getting buried under a long list of places
   - **Guide** — dress expectations, cuisine, history, festivals, prep notes. Skip empty subcategories rather than rendering all headers regardless of content — `guide_items` is an aggregate across nine types (best_time and the `*_norm` types display in Overview, the rest here), so a country can clear 'complete' unevenly (e.g. lots of cuisine notes, zero history)
   - **Travel Info** — advisories (multiple governments side by side, each attributed and dated) + visa info (summary + official link + verified date + prohibited items on entry/exit, where known). For countries tagged with a `regional_group` (e.g. Schengen), a shared regional note displays alongside the country-specific visa summary — see data architecture doc's `regional_notes`
   - **Language** — entry point into learn/use

   **Empty tabs are omitted, not shown empty.** If a country has zero content for an entire tab (e.g. no language content at all for a country where that was deliberately never in scope — see data architecture doc's `language_scope_na`), that tab doesn't render rather than showing a blank or "coming soon" state within the page. This is what makes tab-presence a meaningful signal for `content_status` (below) rather than an implementation detail.

   **Resolved over a long scroll:** a 'complete' country (per the `content_status` thresholds) stacks facts, weather, advisories, visa info, several curated categories, and points of interest before reaching the language entry point — too much vertical distance to the actual product in one scroll. Sparse tabs on a 'partial' country are expected, not a flaw — the `content_status` pill already sets that expectation.

   **`content_status` display:** a small, non-modal pill near the top of the page, shown only when `content_status = 'partial'` — `'complete'` gets no badge at all (silence signals trust; a "✓ Complete" label everywhere would train users to treat its absence as a warning, undercutting the honesty goal). Copy: *"Building out [Country] — some sections are further along than others."* Names the unevenness the user will actually hit (a full Guide tab next to a missing Language tab) rather than a vague "still growing" reassurance. `partial` means Overview plus at least one other tab has content (see data architecture doc for the full tab-presence rule) — not a raw field count, so deliberately-scoped content (like a country with no language tab at all) doesn't get miscounted as a gap. Kept as a separate signal from cache-staleness display (which lives closer to advisories/visas specifically, within Travel Info) — depth and freshness are different trust questions and shouldn't be collapsed into one indicator.

4. **Language entry → category selection**
   Checkboxes, multi-select, parent categories only.

5. **"Personalizing your dictionary" loading screen**
   Cosmetic in V1 — filters already-cached content down to the selected categories. Built as a real `async` step (even when the work is synchronous) so a genuine backend call can replace it later without touching the UI.

6. **Learn / Use fork**
   - **Learn →** flashcards, deck built from *all* selected categories mixed together, order randomized each session, no progress saved
   - **Use →** category list (only what the user selected) → tap a category → vocab list (phrase + translation), plus a "flashcards for this category" option right on that screen

### Flashcards

A flip-card widget: front/back state, tap or swipe to flip, swipe or button to advance. Deck order shuffled once per session.

**Takes a phrase list as input and doesn't care where it came from** — the same widget serves the mixed-category Learn deck and the single-category deck launched from a vocab list. One build, two entry points.

No spaced repetition in V1 — a natural, self-contained addition once progress tracking exists (which requires accounts).

---

## Content Structure Notes

These are UX-facing consequences of decisions documented fully in the data architecture doc:

- **Everything is organized by country, not language.** Mexico and Argentina are separate destinations with separate content even though both are Spanish-speaking. Language appears as a display label, never as a navigation axis.
- **Words and phrases are distinct.** A word is a dictionary entry; a phrase is a sentence composed of tokens. This is what makes fill-in-the-blank and word-reordering exercises possible later — a phrase stored as a flat string can only be displayed.
- **Categories are shared across all countries.** Food, Transportation, Museums, etc. don't change by destination; the content within them does.
- **Category hierarchy is two levels.** Parent categories (Food) may contain sub-subjects (Cooking, Grocery Shopping) that get their own screen. Flat categories skip straight to the vocab list.
- **Trees arrive prebuilt.** The client never assembles a category hierarchy from parent pointers — that's server work.

---

## Roadmap

**V1 — country pages.** Search → country page → language flow with learn/use and flashcards. Read-only, no accounts. Countries with content are fully browsable; everything else opens the same page with every section reading "coming soon" (see Screen Flows, step 2). Shipped to a small group of real travelers, not an app store launch. **Build starts once every personally-visited country is fully collected** (see data architecture doc's Sequencing section) — a content trigger, not a calendar date.

**V1.1 — second country.** The test of whether the country-organized model holds up: add content for a new country, confirm it appears fully with no other changes needed.

**Dedicated city pages — natural extension, not yet scoped.** V1's Explore tab groups POIs by city inline; a full city page (its own screen, city-specific facts, maybe its own coming-soon state for under-covered cities) is a reasonable next step once a country has enough cities with real content to make browsing-by-city worth a dedicated screen rather than a grouped list. `Cities.city_id` already threading through `points_of_interest` means this extension doesn't require new schema — just new UI once the content volume justifies it.

**V2 — accounts and real personalization.** The cosmetic "personalizing" filter becomes real computation. Accounts arrive alongside, since personalization pairs naturally with saved preferences and persistent flashcard progress.

**V3 — trip dashboards.** Trip creation flow (when are you going, which cities, other countries from here), then a dashboard: days until trip, expected weather, pre-trip checklists, word of the day, and pinned content from country pages.

**V4 — word of the day notifications.** Lock-screen prompt showing a phrase for the destination. Almost certainly *local* notifications scheduled on-device from cached content rather than server-pushed — no backend push infrastructure needed. First cut keys off the most recently selected country rather than GPS; location-based detection is a later refinement needing permission handling not yet scoped.

**V5 — social layer.** Shared trips, group planning, friends' advice, liking phrases that came in handy. Builds on V2 accounts.

**V5+ — trip diary & photo feed.** Users keep a diary of photos and notes from trip activities (calendar-style layout is one option, not decided). Entries marked public feed into a scrollable photo feed on the relevant country/city/activity page — a browsing tool for travelers still deciding where to go, distinct from the private trip-planning use of V3's dashboards. Builds on V3 trips and V5 social; not yet scoped (data model, photo storage, moderation/privacy all open — see data architecture doc's Open Decisions).

**Later, master's-dependent:** personalized, itinerary-aware lesson generation drawing on real SLA theory. See the career doc.

---

## Open Questions

- ~~**Country page layout**~~ — **resolved: four tabs** (Overview, Guide, Travel Info, Language), grouped by trust tier. See Screen Flows, step 3, for the grouping and the volume reasoning against a long scroll.
- **Cache staleness UI** — how prominently to surface "this was verified in March" without making the app feel unreliable. Matters most for advisories and visas.
- ~~**Local storage package**~~ — **resolved:** key-value/object store (Hive or a Hive-alternative like `hive_ce`/`sembast`), not sqflite. `CountryBundle` is cached and read as a single denormalized whole with no on-device relational queries in V1, so a key–blob store matches the access pattern without redundant re-normalization. Would flip only if a later phase (spaced repetition progress, checklist queries, pinned-content filtering) needs on-device relational queries — sqflite/`drift` becomes the better fit then.
- ~~**Coming-soon resource links**~~ — **resolved:** shared generic set by default, with a `coming_soon_resources` table (see data architecture doc) supporting per-country override at any time — no usage threshold required. Adding a couple of good links for an uncovered country (e.g. Sweden) the moment they surface is enough to override the generic set for that country alone; the fallback stays generic for everything else.
- **Reopened 2026-08-18: do coming-soon resource links resurface, and where?** Now that there's no dedicated coming-soon screen (see Screen Flows, step 2), the `coming_soon_resources` mechanism above is built but unused. Options: drop it (a "Coming soon" section is enough on its own), or surface those links *inside* an empty section's expanded state (e.g. Language's "Coming soon" body linking out to Google Translate) — which would need per-*section*, not just per-*country*, resource sets, a step further than what's built. Not decided; not blocking, since the plain "Coming soon" text is a reasonable state on its own.
- **The "four tabs" line above is stale** — the actual `CountryHeaderPreviewScreen` build (2026-08-18) is a single-page accordion of sections spanning what were meant to be Overview/Travel-Info/Language tab content, with no tab bar at all. Worth a real resolution once Explore/Guide's remaining content (POI landmarks, cuisine, dress, festivals, history) needs a home — until then this doc's tab language and the code have quietly diverged. See HANDOFF.md's 2026-08-18 entries for the accordion decisions themselves.
- **Trip diary / photo feed** (added 2026-08-17) — Colleen wants, in a later iteration, a trip diary where users post photos and notes from the different activities they did on a trip, possibly calendar-style. Anything an entry's author marks public would show up in a photo feed scoped to that country/city/activity, for other users to scroll while deciding where to go. Open before this is buildable: whether the diary is calendar-first or list-first UI, what "activity" ties an entry to (a `trip_pin`? a `points_of_interest` row? freeform?), how the feed is scoped/paginated per country vs. city vs. activity, and moderation/privacy (review before feed-eligible, report/takedown, who can see whose public photos). See data architecture doc's Open Decisions for the schema-side version of this note.
