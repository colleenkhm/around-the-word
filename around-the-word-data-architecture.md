# Around the Word: Data Architecture & Schema

*Living doc. Companion to the system design doc — which describes the Flutter client and its screen flows. That doc's "V1 has no backend" premise is superseded by this one: the curated travel database is now the core product, and the app is a client onto it.*

---

## The Pivot, Named

Earlier versions of this project treated the app as the product and content as something bundled into it. That's inverted now. **The differentiated asset is a hand-curated, trip-focused travel database** — the kind of information a genuinely experienced traveler knows and generic sources don't have. The Flutter app is one client onto that data. This is a pivot, not a scope change, and it changes the architecture from the ground up.

**Why the moat is real:** commodity travel data (population, flags, capitals) is free and everywhere. Activity-specific phrases, real social-norm nuance, dress expectations at specific sites, and honest best-time-to-visit judgment are not in any dataset. That's the part worth years of effort.

---

## The Central Principle: Two Kinds of Data

Every field here is either **commodity** (freely available in machine-readable form, should be imported and refreshed automatically) or **curated** (researched and written by Colleen, then verified against real traveler experience). They get different pipelines, different update cadences, and different trust levels. Conflating them is the most expensive mistake available — it means burning scarce hours hand-entering data that goes stale and was free to begin with.

**The line is not objective-vs-subjective.** Nearly everything in this app is researchable from public sources, including social norms, dress codes, and phrases. The real distinction is *how the data arrives and how much verification it needs before it's trustworthy*.

| | Commodity | Curated |
|---|---|---|
| Examples | Flag, capital, population, currency, official languages, biggest cities, current leadership, coordinates | Practical basics (tipping, punctuality), dress codes, best-time-to-visit judgment, activity-specific phrases, cuisine notes, prep advice, landmark visit notes |
| Source | REST Countries, GeoNames, Wikidata, weather APIs | Colleen's research across many sources, then verified against friends' actual experience |
| Update model | Scheduled re-import, overwrites | Manual edit, versioned, never overwritten by import |
| If it's wrong | Fix the importer | Fix the entry, ideally prompted by a contributor flagging it |
| Competitive value | None — everyone has it | This is the product |

**A third category sits apart: legally sensitive.** Visas and travel advisories are researchable but consequential enough that they get their own discipline — always linked to the authoritative source, always stamped with a verification date, never restated as the app's own assessment. See those sections below.

**Where the actual differentiation lives:** not in exclusive knowledge — most of this is findable if you're willing to open fifteen tabs. It's in *aggregation plus verification*: everything a traveler needs in one place, checked against people who actually went. That's a real and defensible claim, but it depends on the verification layer being genuine rather than decorative.

**Schema implication:** commodity and curated fields live in *separate tables* so an automated refresh can never clobber hand-written work.

---

## External Data Sources

An audit of every schema field against "does an API already give me this," so hand entry is spent only where it actually buys something. **The organizing rule is the commodity/curated split**: fetch commodity aggressively, and refuse to fetch curated content even where an API exists, because that content *is* the product. This section is written to be build-ready — a condensed version belongs in `CLAUDE.md` at the project root so Claude Code has the endpoints without loading the full doc.

Everything below runs **server-side in a Supabase Edge Function**, never from the Flutter client — partly for key security where keys exist, partly because at least one source applies bot detection.

### Fetch — pure commodity, no judgment lost

| Data | Source | Notes |
|---|---|---|
| Country facts (capital, currency, calling code, languages, coords, flag, bordering countries) | **REST Countries** (`api.restcountries.com/countries/v5/codes.alpha_2/{iso2}`, `Authorization: Bearer {key}`) | **⚠️ Confirmed 2026-08-09: v3.1 is deprecated, no-key access no longer works.** v5 requires a free API key (sign up at restcountries.com/sign-up) — the `rc_live_demo` key runs but always echoes one fixed sample record regardless of the country requested, so it's only useful for verifying a script doesn't crash, not for real data. Response shape changed too: `capital`→`capitals[0].name`, `currencies`/`languages` are now lists not dicts, `latlng`→`coordinates.{lat,lng}`, `flags.svg`→`flag.url_svg`, native name lives at `names.native`. `tools/commodity_importer/fetch_country_facts.py` implements the current shape. **Bordering countries (`borderingCountryCodes`, added 2026-08-19)**: REST Countries' `borders` field returns CCA3 codes ("PAN", "NIC"), not the alpha-2 codes this schema's `iso_code`/`country_id` joins use everywhere else — the importer needs a CCA3→alpha-2 conversion step, not a field-to-field copy. Hand-set in mock bundles only until then, same as every other commodity field before the importer exists. |
| Cities (name, population, coordinates) | **GeoNames** (`api.geonames.org`, free username registration) | Populates `is_major` only; must never touch `is_featured` |
| Travel advisories | **State Dept CA API** + **Global Affairs Canada** | See "Automated refresh" below. Two of three issuing authorities automatable |
| Visa / entry-exit requirements | **State Dept CA API** (`entry_exit_requirements` field) | US-nationality-scoped, which matches V1 exactly |
| Leadership | **Wikidata** (`query.wikidata.org/sparql`, no key) | Query by country — head of government. Already deferred to post-importer for staleness reasons |
| Currency conversion | **ExchangeRate-API** (free tier, key required) | Live, never bundled |
| Weather | Provider TBD | Live, never bundled |
| Timezone / current local time | REST Countries timezone field, or a timezone API | Needed for the MVP's "current time" widget |
| Embassy/consulate contacts | State Dept CA API; Wikivoyage also publishes an embassies CSV | Genuinely useful in an emergency, pure commodity, no field yet |

### Fetch with care — useful, but not a drop-in for the curated field

**Public holidays — Nager.Date** (`date.nager.at`, free, no key, no rate limits, CORS, 100+ countries, returns both `localName` and English `name`).

**⚠️ Version timing matters for this project specifically.** v3 has a published **end-of-life of 2027-01-31**, and v4 shipped 2026-06-30. Since the build-start trigger lands around then, **build against v4 from day one** rather than writing v3 code that needs migrating within weeks. Confirm the v4 response shape at build time — field names appear to have changed (`global`→`nationalHoliday`, `counties`→`subdivisionCodes`, `types`→`holidayTypes`).

Do **not** auto-populate `festivals` from this. The two are different concepts: `festivals` means *a named recurring event worth planning a trip around* (Lavagem do Bonfim, Oktoberfest, Carnaval), while a public-holiday feed returns things like New Year's Day and bank holidays. Auto-importing would bury a handful of genuinely curated entries under dozens of generic ones. What it's actually good for is a **different and unclaimed fact: what's closed when.** "Most businesses shut on this date" is practical, checkable, commodity-shaped, and currently missing from the schema — arguably its own `closure`/`public_holiday` guide type rather than a `festival`, not yet added.

### Do NOT fetch — this is the product

**Points of interest.** OpenTripMap (10M+ POIs from OSM/Wikidata/Wikipedia), Geoapify (3k free credits/day), Overpass, and a curated Wikivoyage dataset (~313k travel-selected POIs with addresses, hours, phone) all exist and would technically fill `points_of_interest` overnight.

**That would gut the moat.** The Explore entries that matter read like firsthand, opinionated visit notes — no POI API produces that. Importing millions of generic pins would bury a few dozen firsthand entries under noise and turn the differentiated asset into a worse version of Google Maps.

**The legitimate use is enrichment, not discovery**: once a POI has been *chosen* by hand, an API is a fine way to fill in coordinates, address, and opening hours. Human picks the place; API fills the boring fields. Never the reverse. Same logic applies to `guide_items` (cuisine, dress, practical norms), all language content, and social norms — no API, by design. **This is an explicit instruction for Claude Code**, since an importer script that "helpfully" also pulls POIs would quietly undermine the whole premise of the app.

---

## Recommended Stack

**Supabase (Postgres) + Flutter client.**

- **Postgres** because this data is genuinely relational — countries have cities, phrases belong to categories and countries, tips have contributors. Document stores fight this shape.
- **Supabase specifically** because it ships a usable admin table editor. Given that data entry will consume far more hours than app code, having a working CMS on day zero matters more than almost any other technical consideration. Building a custom admin panel would be its own project.
- **Auth included** — needed for trip dashboards (phase 2) and social features (phase 3). Not something to bolt on later.
- **API layer:** Supabase auto-generates a REST API supporting nested selects, which delivers most of GraphQL's "one round trip, many related fields" benefit with zero setup. `pg_graphql` is available if GraphQL is preferred later. **This means the REST-vs-GraphQL decision does not need to be made now** — the same Postgres schema serves either.
- **Edge Functions** for proxying third-party APIs (see below).

**Alternative worth knowing:** Directus or Payload — stronger content-management UX over the same Postgres. Worth switching to only if data entry becomes the actual bottleneck. Start with Supabase.

### Correcting one assumption

GraphQL does not help consume existing weather/third-party REST APIs. Wrapping them means writing resolvers that call them anyway. The real reason a server sits in front of third-party APIs is **key security** — any API key shipped inside a Flutter binary is extractable. Weather and similar calls must route through an Edge Function regardless of query language.

---

## Schema

Naming: `snake_case`, plural tables, `id` as UUID primary key throughout, `created_at` / `updated_at` on everything.

### Core: countries

```
countries
  id                uuid pk
  iso_code          text unique      -- "MX", ISO 3166-1 alpha-2, the join key everywhere
  name_common       text
  name_official     text
  is_published      boolean          -- controls whether app shows full page or "coming soon"
  content_status    text             -- 'none' | 'partial' | 'complete' (drives UI honesty)
  language_scope_na boolean          -- TRUE when full-country language content isn't the point (see below)
  regional_group    text nullable    -- 'schengen', extensible — see regional_notes below
```

`is_published` is what powers the coming-soon fallback from the system design doc. `content_status` lets the app tell users the truth about depth rather than implying every published country is equally covered.

### Regional notes (shared facts across a tagged group of countries)

```
regional_notes
  group_slug        text             -- matches countries.regional_group, e.g. 'schengen'
  note_type         text             -- 'visa' for now, extensible (e.g. 'advisory' if a shared risk pattern emerges)
  summary           text
  official_url      text
  last_verified_at  timestamptz
```

**Resolved: a shared-facts table, not just a tag.** A `regional_group` tag alone doesn't stop duplication — without somewhere for the shared fact to actually live, every tagged country's `Visa` row still restates the same rule in its own words, and updating it (e.g. when ETIAS actually launches) means editing every one of them individually. `regional_notes` holds the fact once; country-level `Visas` rows keep only what's genuinely country-specific (passport page requirements, currency declaration thresholds) and the app displays the matching regional note alongside it. One row to update when Schengen-wide rules change, not N.

**`content_status` thresholds — tab presence, not raw field counts:**

- **`none`** — no tab has meaningful content.
- **`partial`** — the Overview tab has content (facts + at least one of best_times/practical_norms) **and** at least one of the other four tabs (Explore, Guide, Travel Info, Language) has *any* content. Deliberately coarse: a tab either has something worth showing or it doesn't render (see client design doc — empty tabs are omitted, not shown empty). This is a display-honesty check, not a depth check.
- **`complete`** — every one of the five tabs individually clears its own bar: Explore (3+ points of interest, any `poi_type` mix), Guide (5+ guide items combined across types), Travel Info (1+ visa, 1+ advisory), Language (25+ words, 15+ phrases), Overview (always trivially met once published).

This replaced an earlier "lowest-scoring category" numeric floor rule, which penalized deliberately-scoped content as if it were a gap. Canada is the case that surfaced it: its language content is intentionally Quebec-French-only (see Open Decisions), so Words/Phrases sit at 0 by design — under the old floor rule that pinned the whole country at `'none'` regardless of how developed everything else was. Tab presence fixes this: Canada clears `'partial'` once Overview and Guide have content, with Language simply omitted from display until (if ever) Quebec content gets added, rather than counted as a missing requirement.

**`language_scope_na`** marks a country where full language coverage was never the goal (mostly English-speaking, phrase content limited to a specific region). When `TRUE`, the Coverage sheet's "ready?" check (which gates the build-start trigger) also skips the words/phrases minimums for that country — otherwise a deliberately-partial country would permanently block "every visited country is ready," since it could never hit a threshold that was never meant to apply to it.

Distinct from the Coverage sheet's "ready?" column, which gates `is_published` (publish at all) rather than `content_status` (how thorough to claim once published). A country can be `is_published = TRUE` with `content_status = 'partial'` — publish what's real, label it honestly.

### Coming-soon resources (fallback with per-country override)

```
coming_soon_resources
  id                uuid pk
  country_id        uuid fk nullable  -- null = generic default set
  title             text
  url               text
  sort_order        integer
```

**Lookup logic:** if any rows exist for the requested `country_id`, show those; otherwise fall back to rows where `country_id IS NULL`. Overriding a specific country requires no code change and no threshold — adding a row the moment a couple of good links surface for, say, Sweden is enough to override the generic set for Sweden alone. This is deliberately not gated behind usage analytics or a "worth it" bar; it's cheap enough to add opportunistically, same as any other row in the admin UI.

```
country_facts
  country_id        uuid fk -> countries
  flag_svg_url      text
  capital           text
  population        integer
  currency_code     text
  currency_name     text
  calling_code      text
  official_languages jsonb           -- from source dataset
  bordering_country_codes jsonb      -- alpha-2 codes, converted from REST Countries' CCA3 `borders` field
  latitude          numeric
  longitude         numeric
  region            text
  subregion         text
  source            text             -- 'restcountries' | 'geonames' | 'wikidata'
  last_imported_at  timestamptz
```

Entire table is rebuildable from a script. Nothing here is hand-edited — if a value is wrong, fix the importer.

### Commodity: cities

```
cities
  id                uuid pk
  country_id        uuid fk
  name              text
  population        integer
  latitude          numeric
  longitude         numeric
  is_major          boolean          -- imported: top N by population
  is_featured       boolean          -- CURATED: Colleen's judgment, survives re-import
```

Note the deliberate split: `is_major` is mechanical, `is_featured` is editorial. An importer may only touch `is_major`.

### Commodity but volatile: leadership

```
country_leadership
  country_id        uuid fk
  title             text             -- the actual title used in that country: 'Prime Minister', 'President', etc.
  name              text
  since             date
  source_url        text
  last_verified_at  timestamptz
```

**One row per country — the true top leader, in that country's own terms.** Earlier this held two rows (`head_of_state` and `head_of_government`), which is constitutionally accurate for a country like Canada but not what a traveler actually wants to see: nobody asking "who runs Canada" is looking for the King. `title` holds the country-specific term for whoever actually holds the position most people mean by "the leader" — Prime Minister for Canada/UK, President for the US — rather than a fixed `head_of_state`/`head_of_government` enum that forces every country into the same two slots regardless of what's actually true to the eye of a traveler.

**Kept separate specifically because it goes stale fastest.** Any leadership shown in-app should display its `last_verified_at`. If keeping this current becomes a burden, dropping the feature is better than showing confidently wrong information.

**Not shown in V1** (see Open Decisions) — schema and table exist now, but population and display wait for the commodity auto-importer, so freshness comes from a scheduled refresh rather than manual upkeep.

### Curated: the actual product

```
country_guides
  country_id        uuid fk
  best_times        jsonb            -- [{months, why_short, why, crowd_level, weather_note}]
  practical_norms   jsonb            -- [{type, title, body, severity}] — type: tipping_norm | punctuality_norm | transport_norm | ...
  dress_expectations jsonb           -- [{context, expectation, applies_to}]
  cuisine_notes     jsonb            -- [{dish, description, where, dietary_flags}]
  historical_events jsonb            -- [{year, title, why_it_matters}]
  festivals         jsonb            -- [{title, body, months}] — named recurring cultural/religious events
  prep_notes        jsonb            -- [{title, body, urgency}]
  author_notes      text
  last_reviewed_at  timestamptz
```

**`why_short` is the display field; `why` is the detail.** Every month or window shown to a user is rendered with its reason in parentheses — *September (dry season)*, *December (Christmas markets)*, *October (end of tourist season, still warm)*. A bare list of months makes the reader do the work of asking "why that month?", which is exactly the judgment this field exists to supply. `why_short` is 2–6 words, lowercase unless a proper noun, no terminal punctuation, and must read naturally inside parentheses. `why` keeps the fuller prose for anywhere the longer form is wanted. The two are separate fields rather than one truncated at display time, because a good short reason is a written judgment ("mildest, driest stretch") rather than the first clause of a longer sentence.

**`festivals` is distinct from `best_times`.** `best_times` is generic weather/crowd-driven date-range judgment ("May and September are pleasant"); `festivals` is a specific named recurring event worth planning a trip around (Lavagem do Bonfim, Oktoberfest-type things) — different enough in shape (a proper name, not just a date range) and purpose (plan around this specific thing, not just "go during this window") to earn its own field rather than being folded into `best_times` or treated as an unnamed `points_of_interest` entry.

**`practical_norms` replaces `social_norms`/`taboos` in V1.** Each entry is a concrete, checkable-as-true-or-false question asked identically for every country — tipping, punctuality, which rideshare/taxi app is actually recommended for a tourist to use. That last one is deliberately about *what a tourist should download*, not raw local market share — the two can diverge (Indonesia's ride-hailing market is close to an even split between Grab and Gojek, but Grab is the better recommendation for a US traveler specifically because it reliably accepts foreign credit cards, which is a tourist-specific need a market-share number wouldn't surface). Each one is its own standalone `type` (`tipping_norm`, `punctuality_norm`, `transport_norm`, more added the same way over time) rather than sub-categories nested under one generic bucket — so any single type can be filtered and deleted across every country independently (e.g. drop `tipping_norm` everywhere without touching `punctuality_norm`) without a migration or a bucket-wide decision.

Genuine social norms and taboos — the interpretive, "this is generally considered rude" kind of content, where reasonable people and different sources can disagree — are deliberately **not collected in V1**. That content is deferred to the V5 friend-verification social layer, where disagreement between contributors is something the system is built to handle (multiple responses, recency weighting) rather than a single asserted fact from one round of research. Collecting it now, single-sourced and unverified, would mean shipping exactly the kind of confidently-wrong content the friend-verification layer exists to prevent.

JSONB rather than separate tables for each: these are read as whole blocks, rarely queried across countries, and the shapes will change as the content matures. Any of these can be promoted to its own table later if it starts needing cross-country queries (e.g. "show me all countries with strict dress codes").

```
points_of_interest
  id                uuid pk
  country_id        uuid fk
  city_id           uuid fk nullable
  poi_type          text             -- 'landmark' | 'restaurant' | 'neighborhood' | extensible, same pattern as guide_items' *_norm types
  tags              text nullable    -- comma-separated: 'breakfast' | 'lunch' | 'dinner' | 'coffee' | 'bar', restaurant-type POIs only
  name              text
  description       text
  dress_code        text nullable    -- site-specific; the genuinely useful detail (restaurants can have one too)
  visit_notes       text             -- crowds, timing, booking, honest assessment
  latitude          numeric
  longitude         numeric
```

**Generalized from a landmarks-only table.** Landmarks, restaurants, and neighborhoods are structurally identical — a specific named place with coordinates, an optional city tag, a description, and practical visit notes — so this is one table with a `poi_type` discriminator rather than three near-duplicate tables, the same reasoning that kept `guide_items` as one flexible table instead of splitting by type. New POI types (a market, a viewpoint, whatever comes up) get added the same way, filterable and independently manageable without a schema change.

**`tags` exists specifically so "bar" doesn't need to be its own `poi_type`.** Many venues genuinely serve multiple functions across the day (a cafe that becomes a bar at night) — splitting that into separate rows or a rigid bar/restaurant binary would misrepresent the place. One `restaurant` POI can carry `coffee,bar` or `breakfast,lunch,dinner` as needed.

```
tips                                 -- Colleen-written, synthesized from research + friend input
  id                uuid pk
  country_id        uuid fk
  city_id           uuid fk nullable
  category_id       uuid fk nullable
  title             text
  body              text
  sort_order        integer
  published_at      timestamptz
```

### Curated: language content

Country-organized, per the earlier decision — Mexico and Argentina get separate rows even though both are Spanish-speaking, because regional usage differs and the app's unit is the destination.

```
languages
  id                uuid pk
  iso_code          text unique      -- "es"
  name              text

country_languages
  country_id        uuid fk
  language_id       uuid fk
  is_primary        boolean
  usage_note        text             -- "Spanish, but Quechua widely spoken in the highlands"

categories
  id                uuid pk
  slug              text unique      -- "food-cooking"
  name              text
  parent_id         uuid fk nullable -- self-referential, gives the sub-subject structure
  sort_order        integer

words                                -- individual lexical items: the dictionary layer
  id                uuid pk
  country_id        uuid fk          -- country-organized, per the earlier decision
  language_id       uuid fk
  lemma             text             -- dictionary form: "hervir", "sartén"
  translation       text
  part_of_speech    text nullable    -- 'noun' | 'verb' | 'adj' | ...
  gender            text nullable    -- 'm' | 'f' | 'n'; null where not applicable
  pronunciation     text nullable    -- informal respelling: "bohn-ZHOOR"
  ipa               text nullable    -- formal IPA: "bɔ̃.ʒuʁ"
  audio_url         text nullable
  usage_note        text nullable
  difficulty        integer nullable -- for later game/level sequencing

word_categories                      -- a word can belong to several categories
  word_id           uuid fk
  category_id       uuid fk

phrases
  id                uuid pk
  country_id        uuid fk          -- country, not language: the organizing decision
  language_id       uuid fk          -- which language this is in (display/filtering)
  category_id       uuid fk
  text              text             -- full phrase; display form and source of truth
  translation       text
  literal_translation text nullable  -- where idiom differs from meaning; useful for teaching
  pronunciation     text nullable
  audio_url         text nullable
  formality         text nullable    -- 'formal' | 'informal' | 'either'
  usage_note        text nullable    -- regional/contextual nuance; part of the moat
  sort_order        integer

phrase_tokens                        -- ordered pieces of a phrase; what makes games possible
  id                uuid pk
  phrase_id         uuid fk
  position          integer          -- 0-based order within the phrase
  surface_form      text             -- as it actually appears: "hierve"
  word_id           uuid fk nullable -- canonical word, when there is one -> "hervir"
  is_maskable       boolean          -- can this token be blanked in an exercise?
  token_type        text             -- 'word' | 'punctuation' | 'particle'
```

**Words and phrases are separate entities, joined positionally.** A phrase stored as a flat string can only be displayed; a phrase stored as an ordered sequence of tokens can be taken apart — which is what fill-in-the-blank, word reordering, and matching exercises all require.

**Why `surface_form` is separate from the word it points to:** the conjugated or declined form appearing in a phrase usually differs from the dictionary form. Storing only `word_id` would render exercises with the wrong form; storing only `surface_form` would sever the link to the vocabulary entry (and fill the word list with near-duplicate conjugations). Both are needed, and adding the second later would mean re-tokenizing every phrase by hand.

**Why `is_maskable` is explicit rather than inferred:** blanking an article makes a trivial exercise, blanking the content word makes a useful one. Recording that judgment once, when the content is written, beats having every future game type guess at it — and it cleanly excludes punctuation.

**`phrases.text` is retained in full** even though it's derivable from tokens. It's what gets edited, what gets displayed, and reassembling from tokens on every read invites subtle spacing and punctuation bugs. Tokens are an index over the phrase, not a replacement for it.

**Authoring note:** hand-tokenizing every phrase is real work. Reasonable path is auto-splitting on whitespace at import to generate draft tokens, then correcting `word_id` links and `is_maskable` flags in the admin UI — most tokens will be right on the first pass.

**Minimum baseline: every country gets hello, goodbye, please, thank you.** Independent of the 25+/15+ words/phrases thresholds for `content_status = 'complete'`, and independent of `language_scope_na` — even Canada's Quebec-scoped language content includes these four, since basic courtesy words are cheap to add and useful regardless of how deep the rest of the vocabulary goes. Filed under the `greetings` category. This is a floor, not a target; it doesn't move the needle on `content_status` tiers, which stay keyed to the fuller thresholds above.

`pronunciation` and `audio_url` are nullable and unused at first — costs nothing now, avoids a migration later.

### Legally sensitive: travel advisories

```
travel_advisories
  id                uuid pk
  country_id        uuid fk
  issuing_authority text NOT NULL    -- 'US State Department' | 'UK FCDO' | 'Global Affairs Canada'
  level             text             -- as the issuer labels it, e.g. "Level 2"
  level_label       text             -- issuer's own wording, e.g. "Exercise Increased Caution"
  summary           text             -- brief, non-authoritative
  official_url      text NOT NULL
  issued_at         date nullable
  last_verified_at  timestamptz NOT NULL
```

**Same discipline as visas, plus one addition: always attribute to the issuing government.** Advisory levels are not neutral facts — the US, UK, and Canadian governments frequently rate the same country differently, and the ratings carry political weight. Presenting "Level 2" without naming who issued it would both misrepresent the data and imply an editorial judgment the app isn't making. The UI should always render the issuing authority alongside the level.

Multiple rows per country are expected and desirable — showing two or three governments' assessments side by side is more honest and more useful than picking one.

### Legally sensitive: visas and entry

```
visa_requirements
  id                uuid pk
  destination_country_id uuid fk
  nationality_country_id uuid fk     -- requirements are pairwise, not per-country
  summary           text             -- brief, non-authoritative
  official_url      text NOT NULL    -- the authoritative government source (informational)
  application_url    text nullable    -- where to actually apply, if a visa is required and this differs from official_url
  last_verified_at  timestamptz NOT NULL
  prohibited_on_entry text nullable  -- banned/restricted items, currency declaration thresholds
  prohibited_on_exit  text nullable
```

**`application_url` is deliberately separate from `official_url`.** They're often different pages with different jobs — `official_url` is where you read about the requirement (e.g. a government or embassy page explaining it), `application_url` is where you actually submit the application (e.g. a third-party processor like VFS Global). Brazil's e-visa is the case that surfaced this: the informational source and the application portal (brazil.vfsevisa.com) are genuinely different URLs, and conflating them would either bury the action link inside a summary or force a workaround. Nullable because most countries in V1 don't require an application at all — no visa needed is the common case.

**`prohibited_on_entry`/`prohibited_on_exit` live here, not on `advisories`.** Customs restrictions aren't a safety-risk rating (which is what `advisories.level` is built around) — they're a legal requirement, the same category of fact as visa rules, and in practice they come from the same government source page (Germany's State Department advisory page lists currency declaration thresholds and prohibited items under "Travel requirements," right next to the visa section, not folded into the advisory summary). One caveat worth naming honestly: unlike the visa summary, customs restrictions generally aren't nationality-dependent — a currency declaration threshold applies to what's being carried, not who's carrying it — so storing them on a nationality-paired table is a minor structural mismatch. It's dormant and harmless in V1 (US-only nationality scope means there's no duplication happening yet), but would be worth revisiting if the nationality scope ever expands past one.

**Design decision, deliberate:** visa and entry requirements are legally consequential and change often. Someone acting on stale information here can be denied boarding — a real harm. This table stores a *brief summary plus a required link to the authoritative source*, and the app must display `last_verified_at` and drive users to `official_url` rather than presenting the summary as sufficient. `official_url` and `last_verified_at` are `NOT NULL` to make the safe pattern structurally enforced rather than a matter of discipline.

Note the pairwise structure: requirements depend on the traveler's nationality, not just the destination. Modeling this as a per-country field would be wrong and would need a painful migration once anyone outside one nationality uses the app.

### Contributed research: friends as verification, not content

**Pipeline shape, narrowed:** friends are not a content source. They're a **verification and steering layer** over information Colleen researches from public sources. The failure mode this addresses is real — published travel information is frequently outdated, over-cautious, or written by people who never went. Someone who actually spent three weeks in Portugal can say "that's technically true but nobody does it," or "the thing you should actually warn people about isn't on that list."

Practically, this means asking things like: does this best-time-to-visit match your experience? Is this advisory language over- or under-stated relative to what you saw? What did you wish you'd known that isn't in any of this?

**Schema implication:** submissions attach to *the thing being verified*, not just to a country. That's what makes the input actionable rather than a pile of general impressions.

```
contributors
  id                uuid pk
  display_name      text             -- contributor's choice: first name, handle, whatever
  relationship      text nullable
  wants_credit      boolean
  created_at        timestamptz

country_contributors                 -- country-level credit
  country_id        uuid fk
  contributor_id    uuid fk

research_submissions                 -- verification input. Read by Colleen, never by the app.
  id                uuid pk
  country_id        uuid fk
  contributor_id    uuid fk nullable
  submitted_at      timestamptz
  form_version      text
  subject_type      text nullable    -- 'best_time' | 'advisory' | 'visa' | 'general'
  subject_id        uuid nullable    -- the specific record being verified, if any
  agrees            boolean nullable -- simple confirm/dispute signal
  structured        jsonb            -- ratings, multi-selects, true/false
  free_text         jsonb            -- short prompts: corrections, what's missing
  visited_when      text nullable    -- recency matters: 2019 advice ages differently than 2025
  notes             text nullable    -- Colleen's annotations while using it
```

`visited_when` is the field that earns its place fastest — a friend's assessment of a country they saw in 2016 carries different weight than one from last year, and without it every submission looks equally current.

**Copyright and permissions:** since responses are short factual observations and confirmations used as research input rather than republished prose, this is ordinary research rather than content licensing. The form should still ask for responses "in your own words, briefly," to avoid pasted text of unknown provenance entering the pile. A plain sentence noting responses will be used in a travel app that may become a paid product is proportionate.

**Credit model: country-level, not per-item.** Published content is Colleen's synthesis, so per-item attribution would be inaccurate as well as awkward.

### User corrections: staleness reports

Since V1's data is hand-researched and static, the correction path is the main defense against silent staleness. Two channels: Colleen's own monitoring and network, plus a lightweight in-app report.

```
correction_reports
  id                uuid pk
  country_id        uuid fk
  subject_type      text nullable    -- 'leadership' | 'advisory' | 'visa' | 'best_time' | 'phrase' | 'general'
  subject_id        uuid nullable    -- the specific record, when reported in context
  report_text       text
  reporter_contact  text nullable    -- optional, for follow-up
  source_url        text nullable    -- "here's where I saw it changed"
  status            text             -- 'new' | 'checking' | 'actioned' | 'dismissed'
  created_at        timestamptz
  resolved_at       timestamptz nullable
```

**Contextual reporting is the important detail.** A report button on the leadership card should pre-fill `country_id`, `subject_type`, and `subject_id` — the reporter just says what changed. A single general "something's wrong" form produces vague reports that cost more to interpret than to fix.

`source_url` is worth asking for. "Leadership changed" requires Colleen to go verify from scratch; "leadership changed, here's the announcement" is a two-minute update.

**Actioning a report should bump `last_verified_at`** on the underlying record even when nothing needed changing — a report that turns out to be wrong still confirms the data was checked on that date, which is exactly what the staleness display is communicating.

### Phase 2: trips (schema now, build later)

Included so the shape is decided before data exists — not built in the first phase.

```
profiles                             -- extends Supabase auth.users
  id                uuid pk          -- matches auth user id
  display_name      text
  nationality_country_id uuid fk nullable  -- powers correct visa lookup

trips
  id                uuid pk
  owner_id          uuid fk -> profiles
  name              text
  start_date        date
  end_date          date

trip_countries                       -- many-to-many: multi-country trips supported from the start
  trip_id           uuid fk
  country_id        uuid fk
  arrival_date      date nullable
  departure_date    date nullable
  sort_order        integer

trip_cities
  trip_id           uuid fk
  city_id           uuid fk
  arrival_date      date nullable
  departure_date    date nullable

trip_pins                            -- "pin anything from the country page"
  trip_id           uuid fk
  entity_type       text             -- 'phrase' | 'poi' | 'tip' | 'guide_section'
  entity_id         uuid
  note              text nullable

checklist_items
  trip_id           uuid fk
  title             text
  is_done           boolean
  due_date          date nullable
  source            text             -- 'template' | 'user' | 'country_prep'
```

`trip_countries` as a join table (rather than a single country per trip) is what makes "are you also traveling to other countries from here?" work without a later migration.

`trip_pins` uses a polymorphic reference deliberately — pinning arbitrary content types is the whole feature, and separate pin tables per type would multiply as content types grow.

**Not yet schema'd, phase 3+ idea: trip diary & photo feed.** Colleen wants a later iteration to let users keep a diary of photos and notes from the activities they did on a trip — calendar-style layout floated as one option, not decided. Anything an entry's author marks public would surface in a scrollable photo feed scoped to that country/city/activity, for other users browsing while deciding where to go. This is distinct from `trip_pins` — pins reference existing curated content, diary entries are retrospective, user-authored content with photos attached after the fact — so it likely wants its own table (something like `trip_diary_entries`: trip_id fk, an activity reference, entry_date, photo(s), note, is_public boolean) plus a photo storage strategy (Supabase Storage) and a feed query joining public entries back to country/city/POI at whatever granularity the feed ends up scoped to. Flagging here so the trip schema above doesn't get reshaped without accounting for it later; see Open Decisions.

---

## Data Movement

```
Public datasets ──(scheduled import script)──> country_facts, cities, leadership
Weather API ─────(Edge Function, key hidden)──> app, never stored long-term
Friend forms ────> research_submissions ───
Other research ───────────────────────────┼──> Colleen writes ──> tips, country_guides,
Colleen's own experience ──────────────────                       phrases, landmarks
                                                          │
                                    Postgres (single source of truth)
                                                          │
                          ┌───────────────────────────────┴──────────┐
                    REST/GraphQL API                          per-country export
                          │                                          │
                    Flutter app  ◄────── caches locally ◄────────────┘
```

Note that `research_submissions` sits *outside* the publish path — it feeds Colleen's writing process, not the app. The app never reads it.

**Offline-first is a requirement, not a nice-to-have.** Users are abroad, roaming, frequently without data — precisely when phrases matter most. Design pattern: fetch a country's full content bundle once, cache locally, read from cache thereafter, refresh opportunistically. This preserves the original static-JSON instinct — the difference is that the JSON is now *generated from the database* rather than hand-maintained.

**Weather is never stored.** It's fetched live through an Edge Function and cached briefly. It's the one genuinely dynamic field and shouldn't pollute the curated schema.

### Automated refresh: the State Department Consular Affairs API

**Resolved: there is an official API, so US advisories and entry/exit requirements do not need scraping.** The scratch notes flagged this as an open question ("advisory data availability varies by government — worth checking what's actually pullable"). For the US State Department specifically, the answer is a proper JSON/XML API at `cadataapi.state.gov`, no key required:

| Endpoint | Returns |
|---|---|
| `api/TravelAdvisories` | Every country's advisory — level, risk indicators, summary, dates |
| `api/TravelAdvisories/{iso2}` | One country's advisory |
| `api/CountryTravelInformation` | All countries' travel information |
| `api/CountryTravelInformation/{iso2}` | One country, e.g. `/AR` |
| `api/CountryTravelInformation/{iso2}/{field}` | One field, e.g. `/AR/entry_exit_requirements` — **this is the visa data** |

A bulk snapshot also exists via `cadatacatalog.state.gov` (`countrytravelinfo.json`), useful for a first full import rather than iterating country by country. **Global Affairs Canada** publishes a comparable JSON feed at `data.international.gc.ca/travel-voyage/` (`index-updated.json` is the chronological-by-update-date file, best for change detection) — a good second issuing authority for `travel_advisories.level`, but Canadian-nationality-scoped, so not a source for US visa rows.

**Gotchas worth budgeting for:**
- The State Dept API **applies bot detection** — a naive fetcher without a realistic `User-Agent` gets hard-blocked; needs a proper server-side call, not a browsing tool.
- `entry_exit_requirements` returns **HTML markup embedded inside JSON strings**, not clean structured fields — needs sanitizing (strip tags, preserve links) before storage. Budget real parsing work, not a field-to-field mapping.

**Weekly refresh design:**
1. **Schedule** — a Supabase Edge Function on a weekly cron (`pg_cron` or Supabase scheduled functions). Weekly is well-matched to the source: State reviews Levels 1–2 every 12 months and Levels 3–4 at least every 6 months, updating off-cycle when conditions change. Nothing is lost by not polling daily.
2. **Change detection keys off `date_issued`, not text diffing.** Every advisory carries an issue date; if it hasn't moved, nothing changed — a cheap date comparison rather than a diff that false-positives on markup churn.
3. **Bump `last_verified_at` even when nothing changed** — same principle already established for correction reports: a check that finds nothing still proves the data was verified that day.

---

## Client Data Objects (Flutter/Dart)

These are the shapes the app works with — deliberately **not** one-to-one with the tables. The database is normalized for integrity and editing; the client wants denormalized bundles it can cache whole and read offline. The API layer flattens between them.

### The core unit: a country bundle

One fetch, one cache entry, one offline unit. This is what gets stored locally when a user selects a country.

```dart
class CountryBundle {
  final Country country;
  final CountryFacts facts;
  final List<City> cities;
  final Leader? leader;           // one per country now — see country_leadership schema
  final CountryGuide guide;
  final List<PointOfInterest> pointsOfInterest;
  final List<Tip> tips;
  final List<Phrase> phrases;
  final List<Word> words;                // dictionary layer, referenced by phrase tokens
  final List<CategoryNode> categories;   // tree, prebuilt server-side
  final List<TravelAdvisory> advisories; // multiple governments, side by side
  final List<String> contributorNames;   // credited contributors only
  final VisaInfo? visa;                  // null until nationality known
  final RegionalNote? regionalNote;      // shared fact for country.regionalGroup, if tagged (e.g. Schengen)
  final DateTime fetchedAt;              // drives cache staleness
}

class TravelAdvisory {
  final String issuingAuthority;   // required — never render a level without it
  final String? level;
  final String? levelLabel;
  final String? summary;
  final String officialUrl;        // required
  final DateTime? issuedAt;
  final DateTime lastVerifiedAt;   // required
}
```

Fetching the whole bundle rather than per-screen slices is the offline-first decision made concrete: a user in an airport with wifi grabs Portugal once, then has everything on the plane and on the ground.

### Country and facts

```dart
class Country {
  final String id;
  final String isoCode;        // "PT"
  final String nameCommon;
  final String nameOfficial;
  final ContentStatus contentStatus;   // none | partial | complete
}

enum ContentStatus { none, partial, complete }

class CountryFacts {
  final String? flagSvgUrl;
  final String? capital;
  final int? population;
  final String? currencyCode;
  final String? currencyName;
  final String? callingCode;
  final List<String> officialLanguages;
  final List<String> borderingCountryCodes;  // alpha-2, e.g. ["PA", "NI"] — added 2026-08-19
  final double? latitude;
  final double? longitude;
  final DateTime? lastImportedAt;
}
```

Nearly everything in `CountryFacts` is nullable — imports fail, small countries have gaps, and the UI needs to render gracefully around missing fields rather than assuming completeness.

```dart
class City {
  final String id;
  final String name;
  final int? population;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;     // Colleen's editorial pick
}

class Leader {
  final String title;            // country-specific: "Prime Minister", "President", etc.
  final String name;
  final DateTime? since;
  final String? sourceUrl;
  final DateTime? lastVerifiedAt;   // UI must surface this
}
```

### The curated guide

```dart
class CountryGuide {
  final List<BestTime> bestTimes;
  final List<NormItem> practicalNorms;  // tipping_norm, punctuality_norm, ... — fixed, checkable, not interpretive
  final List<DressExpectation> dressExpectations;
  final List<CuisineNote> cuisine;
  final List<HistoricalEvent> historicalEvents;
  final List<Festival> festivals;       // named recurring events, distinct from generic bestTimes date ranges
  final List<PrepNote> prepNotes;
  final DateTime? lastReviewedAt;
}

class Festival {
  final String title;
  final String body;
  final String months;           // when it occurs, same shape as BestTime.months
}

class BestTime {
  final String months;           // "May–June"
  final String whyShort;         // short parenthetical reason, e.g. "dry season"
  final String why;
  final CrowdLevel crowdLevel;
  final String? weatherNote;
}

enum CrowdLevel { low, moderate, high, peak }

class NormItem {
  final String type;             // "tipping_norm" | "punctuality_norm" | future additions — each independently filterable/deletable
  final String title;
  final String body;
  final Severity severity;       // drives visual emphasis
}

enum Severity { fyi, important, critical }

class DressExpectation {
  final String context;          // "religious sites"
  final String expectation;
  final String? appliesTo;       // "women" | "all" | site name
}

class CuisineNote {
  final String dish;
  final String description;
  final String? where;
  final List<String> dietaryFlags;   // "vegetarian", "contains pork", ...
}

class HistoricalEvent {
  final int year;
  final String title;
  final String whyItMatters;     // the curated part; the year is commodity
}

class PrepNote {
  final String title;
  final String body;
  final Urgency urgency;
}

enum Urgency { optional, recommended, required }
```

`Severity` and `Urgency` as enums rather than free strings: they drive UI treatment (a critical practical norm should not render like a fun fact), and enums make that mapping total rather than a string-matching guess.

```dart
class PointOfInterest {
  final String id;
  final PoiType poiType;          // landmark | restaurant | neighborhood | extensible
  final List<String> tags;        // breakfast/lunch/dinner/coffee/bar — restaurant-type POIs only
  final String name;
  final String description;
  final String? dressCode;
  final String? visitNotes;
  final double? latitude;
  final double? longitude;
  final String? cityId;
}

enum PoiType { landmark, restaurant, neighborhood }

class Tip {
  final String id;
  final String title;
  final String body;
  final String? cityId;
  final String? categoryId;
}
```

### Language content

```dart
class CategoryNode {
  final String id;
  final String slug;
  final String name;
  final List<CategoryNode> children;   // tree built server-side, not by the client
  final int sortOrder;
}

class Word {
  final String id;
  final String lemma;
  final String translation;
  final String? partOfSpeech;
  final String? gender;
  final String? pronunciation;
  final String? ipa;
  final String? audioUrl;
  final String? usageNote;
  final int? difficulty;
  final List<String> categoryIds;
}

class Phrase {
  final String id;
  final String categoryId;
  final String text;
  final String translation;
  final String? literalTranslation;
  final String? pronunciation;
  final String? audioUrl;
  final Formality? formality;
  final String? usageNote;
  final List<PhraseToken> tokens;

  // Convenience for exercise generation
  List<PhraseToken> get maskable =>
      tokens.where((t) => t.isMaskable).toList();
}

class PhraseToken {
  final int position;
  final String surfaceForm;    // the form as it appears in this phrase
  final String? wordId;        // link to the dictionary entry, when applicable
  final bool isMaskable;
  final TokenType type;
}

enum TokenType { word, punctuation, particle }

enum Formality { formal, informal, either }
```

`CategoryNode` arrives as a prebuilt tree rather than a flat list with `parentId`. The client should never assemble a hierarchy from parent pointers — that's server work, and doing it client-side means every screen re-derives the same structure.

### Visa

```dart
class VisaInfo {
  final String summary;
  final String officialUrl;       // required, never null — informational source
  final String? applicationUrl;   // where to actually apply, if different and relevant
  final DateTime lastVerifiedAt;  // required, never null
  final String nationalityIsoCode;
  final String? prohibitedOnEntry;
  final String? prohibitedOnExit;
}

class RegionalNote {
  final String groupSlug;         // 'schengen', etc.
  final String noteType;          // 'visa' for now
  final String summary;
  final String officialUrl;
  final DateTime lastVerifiedAt;
}
```

Both `officialUrl` and `lastVerifiedAt` are non-nullable in the client model, mirroring the `NOT NULL` in the schema. The UI is expected to render the link and the date alongside any summary — the type system makes it impossible to display visa guidance without them.

### The personalized dictionary (derived, never stored)

```dart
class PersonalizedDictionary {
  final String countryId;
  final List<String> selectedCategoryIds;
  final List<Phrase> phrases;      // filtered from the bundle
  final List<Word> words;          // filtered from the bundle
}
```

Still a filtered view over already-fetched data — the "personalizing" step remains a local operation over the cached bundle, so it works offline and stays instant. Now filters both entities, since words and phrases are independently useful: flashcards may drill either, and games built on `phrase_tokens` need the word layer available to show dictionary forms.

### Phase 2: trip objects

```dart
class Trip {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripCountry> countries;
  final List<ChecklistItem> checklist;
  final List<TripPin> pins;

  int get daysUntil => startDate.difference(DateTime.now()).inDays;
}

class TripCountry {
  final String countryId;
  final String countryName;
  final DateTime? arrivalDate;
  final DateTime? departureDate;
  final List<String> cityIds;
}

class TripPin {
  final String id;
  final PinnedType entityType;
  final String entityId;
  final String? note;
}

enum PinnedType { phrase, poi, tip, guideSection }

class ChecklistItem {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? dueDate;
  final ChecklistSource source;
}

enum ChecklistSource { template, user, countryPrep }
```

`daysUntil` as a computed getter rather than a stored field — it's the dashboard's headline number and should never be persisted or cached, since it changes daily.

### Weather (fetched live, never bundled)

```dart
class WeatherOutlook {
  final String countryId;
  final String? cityId;
  final DateTime forecastFor;
  final double? tempHighC;
  final double? tempLowC;
  final String? conditions;
  final DateTime fetchedAt;
}
```

Deliberately outside `CountryBundle`. Weather is the one genuinely live field — bundling it would mean caching something that's wrong within hours, and would break the "bundle is good offline for weeks" property everything else depends on.

### Currency conversion (fetched live, never bundled)

```dart
class ExchangeRate {
  final String currencyCode;      // 'EUR', 'CAD', etc. — matches Commodity_Facts.currency_code
  final double rateFromUsd;
  final DateTime fetchedAt;
}
```

Same pattern as weather, same reasoning: a cached rate is a rate that's quietly wrong. Daily-update free tiers are plenty accurate for "roughly how many euros is this" — nobody planning a trip needs forex-trader precision.

**API candidate: ExchangeRate-API** (exchangerate-api.com). Free tier, all world currencies, daily updates, no commercial-use restriction — worth checking against at implementation time, but a safer long-term pick than free tiers that explicitly disallow commercial use (a real constraint given this could become a paid product). `freecurrencyapi.com` is a fallback if ExchangeRate-API's terms or reliability don't hold up, though its free tier does bar commercial use.

---

## MVP Scope

**What V1 ships:** country pages, read-only, no accounts. Per country:

- Weather (live, via API)
- Travel advisories from multiple governments, attributed and dated
- Visa requirements (US nationality first), linked to official sources
- Best times of year to visit
- Practical basics (tipping, punctuality), dress expectations
- Activity-specific phrases and vocabulary
- Points of interest (landmarks, restaurants, neighborhoods), cuisine notes, prep advice
- Commodity facts (flag, capital, currency, cities, languages, bordering countries)

**What waits:** accounts, trip dashboards, checklists, pinning, word-of-the-day notifications, and anything social. All have schema defined already so they don't require redesign — they just aren't built.

**Country coverage at launch:** start with countries Colleen has personally visited, where firsthand knowledge already exists and verification is fastest. Everything else shows the coming-soon state.

**Data freshness strategy for V1:** everything is hand-researched and statically populated rather than auto-imported — including the commodity fields, since a spreadsheet-to-import path is faster to stand up than a live integration. Staleness is managed three ways: Colleen's own monitoring, her network flagging changes, and an in-app contextual correction form. This is workable specifically because the riskiest fields (visas, advisories, leadership) always display a verification date and link to the authoritative source, so a user can check the live source themselves. Automated importers for commodity data remain the eventual path, but aren't a launch requirement.

**Friend verification at this stage** is confirmation and nuance — checking that researched information matches lived experience, catching what's stale or overstated, surfacing what's missing. It is not a content-generation pipeline, and the app doesn't depend on submission volume to launch.

---

## Future Exercise Types (captured, not scoped)

Ideas worth recording now so schema decisions don't accidentally foreclose them. None are MVP.

### Spelling with pronunciation feedback

**The exercise:** learner hears an audio clip and types the word. If wrong, they don't just see the correct spelling — they see an explanation of what *their* spelling would actually sound like under the language's pronunciation rules, and why that differs from the target.

Origin: a Portuguese class where the teacher read students' misspellings aloud exactly as written, so they could hear that their version was a real, pronounceable string that simply meant something else.

**Why it's pedagogically strong:** ordinary spelling correction teaches word shapes. This teaches the grapheme-phoneme mapping itself — the learner discovers the rule by seeing their own error interpreted literally. That transfers to words they haven't studied.

**Implementation note:** generating audio of a learner's arbitrary misspelling is hard (TTS on a non-word gives unreliable results). Written explanation is the practical substitute: "in Peninsular Spanish, *ll* before a vowel is pronounced /ʎ/ or /ʝ/, so your *ll* here would sound like…" — text rules rather than synthesized audio.

**What this needs that the current schema doesn't have:**

```
pronunciation_rules                  -- per language, the grapheme-phoneme mappings
  id                uuid pk
  language_id       uuid fk
  region            text nullable    -- 'peninsular' | 'rioplatense' | null for general
  grapheme          text             -- "ll", "ñ", "ç"
  context           text nullable    -- "before a vowel", "word-initial", "between vowels"
  ipa               text             -- the sound it makes
  plain_explanation text             -- learner-facing wording
  example_words     jsonb            -- words demonstrating the rule
```

Then a misspelling can be matched against applicable rules to build the feedback. Full coverage is a linguistics project in itself — but a curated subset covering the handful of graphemes learners actually trip on (in Spanish: `ll`, `y`, `ñ`, `h`, `b/v`, `c/s/z`, `g/j`, `qu`, `rr`) gets most of the pedagogical value at a fraction of the effort.

**Sequencing note:** this doesn't require `phrase_tokens` or the full word database. It can be built against a deliberately chosen subset of words that exercise the target rules — which makes it independently shippable rather than blocked on content coverage.

`words.ipa` already exists in the schema alongside `words.pronunciation` — this feature can lean on it directly rather than needing a new field, making rule-matching more reliable than working from an ad-hoc respelling alone.

---

## Sequencing

The single most useful property of this architecture: **data collection is fully decoupled from writing code.**

1. **Now — lock the schema.** A few hours of thinking, no code. This is the highest-value next step, because reshaping a thousand hand-entered rows later is genuinely expensive.
2. **Now — start collecting.** Spreadsheets with columns matching the schema above work fine, and can run in parallel with TEFOL, the practicum, and master's applications. Start with countries already visited, where the knowledge already exists. **Build-start trigger: app development begins once every personally-visited country is fully collected** — not a fixed date. Keeps the launch strategy coherent (visited countries are the ones you can vouch for directly, no friend-verification bottleneck) rather than switching to a different selection criterion partway through.
3. **Build the importer** for commodity data — one script, immediately fills in the free 40%.
4. **Stand up Supabase**, import the spreadsheets, start using the admin UI for ongoing entry.
5. **Flutter client reads country pages** — read-only, no accounts. This is the honest V1.
6. **Auth + trips** — phase 2.
7. **Social** — phase 3.

**Scope note worth revisiting deliberately:** the code has grown well beyond the original no-backend V1, and it lands in the same window as a master's program starting. Claude Code compresses the *coding* meaningfully — it does not compress data collection or schema judgment. The realistic call is that V1 ships as country pages only, read-only, with trip dashboards genuinely waiting for phase 2 rather than being quietly pulled forward.

---

## Open Decisions

- ~~**Contributor credit policy**~~ — **resolved:** country-level credit, opt-in via a checkbox on the form, contributor picks their own display name. Published content is Colleen's synthesis, so per-tip attribution would be inaccurate.
- ~~**Nationality scope for visas**~~ — **resolved: US nationality only** for V1, with the pairwise schema already in place so expansion doesn't require migration. Supporting all nationality pairs would be a combinatorial explosion for no benefit to the actual V1 audience.
- ~~**Canada's language content scope**~~ — **resolved: Quebec French only.** Canada is mostly English-speaking; full-country vocabulary/phrase content wouldn't help a US traveler the way it does for a genuinely non-English destination. Quebec is the one region where phrases are actually useful. Flagged via `countries.language_scope_na = TRUE` (see `content_status` thresholds above) so this deliberate scoping doesn't get mistaken for a content gap.
- ~~**Whether leadership data earns its keep**~~ — **resolved: not in V1.** It's commodity data (zero differentiation value) carrying curated-data staleness risk (manual entry, no refresh trigger) until the commodity auto-importer exists — worst of both categories at launch, and stale leadership risks eroding trust in the actually-curated content on the same page. Schema stays as designed; leadership is populated and shown starting once the auto-importer (sequencing step 3) covers it on a scheduled refresh, at which point the staleness risk drops to the same level as flag/capital.
- ~~**Landmarks tab structure**~~ — **resolved: dedicated "Explore" tab, `landmarks` generalized to `points_of_interest`.** Surfaced once a landmark-heavy country (Greece, 11 points of interest and climbing after just Athens) showed points of interest would outnumber everything else in Guide combined. Rather than three near-identical tables for landmarks/restaurants/neighborhoods, one table with a `poi_type` discriminator — the same pattern as `guide_items`' `*_norm` types, extensible without a schema change.
- ~~**Leadership: one row or two, generic role or country-specific title**~~ — **resolved: one row, country-specific `title`.** The earlier `head_of_state`/`head_of_government` split was constitutionally accurate (Canada technically has both a monarch and a Prime Minister) but not what the feature is actually for — showing a traveler who leads the country in the terms they'd recognize. `title` holds the real term ("Prime Minister," "President") rather than a fixed two-slot enum that doesn't fit every government structure and surfaces a technically-correct answer nobody's looking for.
- ~~**Named recurring events (festivals)**~~ — **resolved: new `festival` guide_item type / `country_guides.festivals` field.** Surfaced by Lavagem do Bonfim (Salvador) — a specific named annual event worth planning a trip around, which didn't fit `best_times` (generic date-range judgment, no proper name) or `points_of_interest` (a place, not an event). Displays in the Guide tab alongside dress/cuisine/history/prep.
- ~~**Prohibited items on entry/exit**~~ — **resolved: `prohibited_on_entry`/`prohibited_on_exit` on `visa_requirements`, not `advisories`.** Customs restrictions are a legal requirement (same category as visa rules), not a safety-risk rating (what `advisories.level` is built around), and in practice come from the same government source page as the visa summary. Known mismatch: unlike visa rules, customs restrictions usually aren't nationality-dependent, so pairing them to a nationality makes the table hold identical data per nationality pair — harmless while V1 stays US-only, worth revisiting if that scope ever expands.
- **Trip diary / photo feed schema** (added 2026-08-17) — Colleen wants, in a later iteration, a trip diary of photos and notes per activity (calendar-style is one option), with public entries feeding a scrollable photo feed on the relevant country/city/activity page. See the note under "Phase 2: trips" above for the sketch (`trip_diary_entries` distinct from `trip_pins`, photo storage, feed query). Open until scoped: what an entry attaches to (a `trip_pin`? a `points_of_interest` row? freeform text?), feed granularity (country/city/activity all at once, or pick one), and moderation/privacy before public photos are feed-eligible.
- ~~**City-level pages / scoping landmarks to nearest city**~~ — **resolved: keep `city_id` nullable, no forced nearest-city assignment.** The instinct behind this (cities as a real navigational layer, not just metadata) is right and cheap to build toward — `city_id` was already threaded through `points_of_interest` from the start. But forcing every POI onto a "nearest city" would misrepresent genuinely regional sites (Delphi, Meteora, Neuschwanstein — none meaningfully "near" any single profiled city) or bloat `Cities` with towns that aren't real destinations themselves (Kalambaka, Füssen). Untagged POIs display under a "Regional" heading instead. Guide items (cuisine, festivals, practical norms) stay country-level for now — city-scoping those is a bigger lift with less clear payoff at this stage, revisit if it becomes a real pain point (e.g. wanting "moqueca is a Bahia thing" distinct from a generic Brazil note).
- ~~**`content_status` thresholds**~~ — **resolved:** see thresholds under the `countries` schema above. Now tab-presence based (Overview + at least one other tab = `'partial'`; all five tabs individually clear their own bar = `'complete'`), replacing an earlier raw-field-count floor rule that penalized deliberately-scoped content like Canada's Quebec-only language coverage. Kept distinct from the Coverage sheet's `is_published` gate — a country can be published and 'partial' at once.
- ~~**Guide items threshold for 'complete'**~~ — **resolved: lowered from 8+ to 5+.** The original 8 was set early, based on Canada's initial data, before other countries showed what a realistic natural spread actually looks like — Ireland organically landed at 7 (best_time, festival, tipping_norm, four cuisine notes) without needing padding. 5 is a more honest bar for "genuinely useful," not an arbitrary round number carried over from the first country worked on.
