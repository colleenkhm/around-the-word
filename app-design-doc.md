# App Design Doc — Travel Phrase App (Prototype)

*Living doc. Colleen drives, Claude documents. Captures decisions as they're made, in the order they're made.*

---

## ⚠️ Superseded by [language-app-system-design.md](language-app-system-design.md)

That doc is now the authoritative plan. Specifically overridden from this doc:
- **Subject list:** reverted to the original generic 14-category list below (Food, Shopping, Hiking, Family, etc.), not the Costa-Rica-specific activity list (Airport, Hotel, Beach Day, Nature Tours, etc.) developed further down in this doc.
- **Trip/activity selection as the core differentiator:** explicitly out of scope for V1-V3 in the new doc ("Explicitly not on this roadmap: trip/itinerary planning"). Not discarded — flagged in the new doc's roadmap as something that could resurface in later, master's-dependent work.
- **Exercises:** simplified to flip-card flashcards (Learn mode) — the reveal/recall + multiple-choice-fill-in-blank + matching set, and the per-activity scenario framing, are not part of current scope.
- **Vocab grammar tagging** (part of speech, gender, number, activity tags) and the spaCy tagging pipeline: not needed for the new content model (`{phrase, translation}` pairs only), so that work is paused, not continued.
- **Phrasebook:** not in V1 — the new doc has zero persistence in V1 (browse-only, no accounts).
- **Place-first framing still holds** in spirit — content is scoped per-country in the new doc too — but via a continent/country map UI rather than a single first-place choice, and Costa Rica (Spanish) is still the working first country.

Target-user framing (traveler prepping for a trip, not chasing fluency) and the social-layer idea (deferred, validate-by-asking) both still hold and carry over cleanly into the new doc. Everything below this notice is kept for history/context, not as current direction.

## Target User & Problem (superseded — see notice above; kept for history)

**Target user:** Colleen herself, and travelers like her — people who want to learn some of a destination's language before a trip, but aren't trying to become fluent.

**The problem:** big language-learning apps (Duolingo, Babbel) force users through a general skill-tree curriculum before reaching anything relevant, and even once you reach a relevant unit it's padded with vocabulary that has nothing to do with your actual trip.

**What this app is instead:** a focused, trip-specific supplement — not a fluency tool. Priority is the phrases and practice tied to what someone is actually going to be doing on a specific trip, reachable directly, without wading through unrelated curriculum.

## MVP Scope (superseded — see notice above; kept for history)

**Primary organizing unit is now Place, not language.** A destination determines its language(s) — the user doesn't pick a language abstractly, they pick where they're going. This directly reflects the real use case ("I'm traveling to Costa Rica") rather than an abstract "learn Spanish" framing.

**First place: Costa Rica (Spanish).** Deliberately one specific country rather than "South America" broadly — South America isn't linguistically uniform (Brazil is Portuguese, plus French/Dutch/English-speaking pockets), and the whole point of place-first framing is region-specific vocab and customs, which a continent-wide generic-Spanish set would flatten back into "just Spanish," indistinguishable from existing apps. Spanish is also a language Colleen has enough personal knowledge of to verify content accuracy. *(Note: Costa Rica is Central America, not South America — worth deciding whether "South America" is still the right label for the eventual broader region grouping, or whether grouping should just be by country for now.)*

**Structure: Place → Activity → Phrases + Exercises**
- Activities are specific things a traveler does (restaurant, airport, hiking, snorkeling, etc.) — similar granularity to what competitors offer, but the differentiator is letting a user select only the activities on their actual itinerary and getting vocab scoped to just those.
- Activity selection/filtering as a user-facing feature is explicitly **post-MVP** — the data just needs to be shaped so filtering is possible later, not built now.

**Phrases are bilingual**, not English-only text: target-language text plus an English meaning. (Original MVP was "teach English," so phrases were English-only; that no longer applies now that the target user is learning a destination's language.)

**Exercises are in MVP scope** — this is not just a passive word list, it's meant to function as a secondary language-learning tool. Three mechanics, chosen deliberately as proven/established rather than novel, since the app's differentiation is meant to come from trip-relevance rather than exercise-format novelty:
- Reveal/recall
- Multiple choice fill-in-the-blank
- Matching

Where creativity comes in: these should be **framed per-activity/scenario** (e.g. a matching exercise styled around "the snorkeling guide hands you this — what do you say?") rather than generic decontextualized drills, so the trip-relevance differentiator shows up in the exercises too, not just the vocab list.

**Personal phrasebook (saving/favoriting phrases) is in MVP scope.**

**Social "liking" of phrases (crowdsourced usefulness-by-place data) is NOT in MVP scope.** Real signal requires multiple real users and a backend; building a fake single-user version risks validating the wrong thing. Instead, validate demand for this by asking testers directly whether they'd want it, rather than building it.

---

## Original MVP Scope (superseded — kept for history)

**Language:** English only for the prototype — lined up with TEFL certification work, so real teaching experience could feed content directly into the app.

**Core structure (original, simplified concept):**
1. Subject list (e.g., restaurants, transit, greetings — exact list TBD)
2. User selects a subject
3. User sees the vocab words/phrases within that subject

No "learn vs. use" mode split, no personalization/itinerary input, no multi-language, no exercises — just: pick a subject, see the words.

## Subject List (v1 — from the original English MVP; being re-scoped into Costa-Rica-specific activities)

Framed around specific activities someone might actually be doing while traveling abroad — the more niche/specific, the better (vs. generic broad topics).

- **Food:** cooking, grocery shopping
- **Shopping:** malls, souvenirs
- **Hiking / the outdoors**
- **Talking about family**
- **Talking about aesthetics**
- **Transportation:** airports/flying, bus stations, taxis
- **Talking about houses**
- **Museums**
- **Music**
- **Occupations**
- **Speaking casually**
- **Celebrations:** wedding, graduation, birthday, holiday
- **TV shows / movies**
- **Going to a party**

*Many of these translate directly into "activities" for the place-first framing (Transportation, Hiking, Museums); some are more general-conversation topics than trip activities and may not carry over as-is (Talking about family/houses/aesthetics, Occupations). Costa-Rica-specific activities (e.g. volcano tours, wildlife/rainforest excursions, surfing, beach days) will likely need to be added.*

## Future Direction: Social/Community Layer (post-MVP)

Idea: layer social-media-style features on top of the core structure —
- Users can **like/upvote phrases** that came in handy for them while actually traveling somewhere specific
- Users can **recommend places** tied to a location (ties phrase usefulness to real, specific place context, not just abstract activity categories)
- Dual purpose: builds genuine community/social value (real traveler tips, not just static content) **and** generates usage data that could power better recommendations — e.g., surfacing which phrases/activities are actually most useful for a given destination, based on real traveler behavior rather than assumptions
- For MVP, this idea is validated by directly asking testers if they'd want it — not by building it.

## Decisions Log
*(most recent at bottom)*

- Narrowed from "language + activity + learn/use mode" down to "English + subject list + vocab within subject" for a leaner MVP
- English chosen first specifically because it overlaps with the TEFL cert work — real classroom material could inform the subject/vocab lists
- First subject list drafted: 11 categories, several with niche sub-groups (e.g., Transportation — airports/flying, bus stations, taxis), framed specifically around travel-abroad activities rather than generic topics
- Added Celebrations (with sub-items), TV shows/movies, Going to a party
- New future-direction idea: social/community layer — liking phrases, recommending places — doubles as both a user-facing feature and a data source for better recommendations later
- MVP built in Flutter: category list → subject list (where applicable) → phrase list, with hardcoded English phrases for every subject; added a "20 Common Verbs" category alongside the topic-based ones. Implementation-level decisions and rationale tracked separately in [HANDOFF.md](HANDOFF.md)
- **Major pivot:** reframed target user from "English learner tied to TEFL" to "traveler preparing for a specific trip" (Colleen herself) — the actual problem is that curriculum-based apps (Duolingo, Babbel) bury relevant content behind a full skill tree and pad relevant units with irrelevant vocab
- MVP is explicitly not a fluency tool — it prioritizes phrases/practice tied to a specific trip over a general learning arc
- Confirmed MVP includes a small exercise set (reveal/recall, multiple-choice fill-in-the-blank, matching) rather than being a passive word list, since the product is meant to function as a secondary language-learning tool
- Exercises should be framed per-activity/scenario rather than generically, so trip-relevance shows up in practice, not just vocab — deliberately kept to proven exercise mechanics rather than novel game formats, to avoid spending MVP effort validating unproven pedagogy instead of the actual product hypothesis
- Personal phrasebook (saving/favoriting phrases) confirmed in MVP scope
- Social "liking" mechanic confirmed **out** of MVP scope — validate demand by asking testers, not by building it, since real signal needs multi-user data anyway
- Chose French and Spanish as the first two target languages specifically because Colleen has enough personal knowledge of both to verify content accuracy
- Reframed the primary organizing unit from language to **place/destination** — a destination implies its language, so there's no separate abstract language-selection step; this matches the real use case ("I'm traveling to Costa Rica") much more directly than "learn Spanish" in the abstract
- First place selected: **Costa Rica** (Spanish) — one specific country rather than "South America" broadly, so activity-specific vocab reflects real regional detail rather than collapsing into generic Spanish content; plan to expand to additional countries/regions (e.g. Europe) once this one is proven out

## Open Questions

- What specific activities matter most for a Costa Rica trip (first real activity list needed — likely a mix of carried-over topics like Transportation/Hiking and new Costa-Rica-specific ones like volcano tours, wildlife/rainforest excursions, surfing)
- Exact exercise UI/interaction design — mechanics are locked (reveal/recall, multiple-choice fill-in-blank, matching), screens are not yet designed
- Whether "South America" is still the right label for the eventual broader region grouping, given Costa Rica is Central America — or whether grouping should just be by country for now, with continent-level umbrellas decided later
- What the second place/region should be once Costa Rica is done — Europe mentioned as a direction, no specific country chosen yet
- Whether/how sub-subjects (activity groupings) should nest, now revisited under the activity/place structure rather than the original subject list
