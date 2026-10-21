# Pocket Talk

Travel phrases you actually need, saved and drilled. A curated Spanish
phrasebook scoped to where you are, plus a general translation lookup for
anything the phrasebook doesn't cover — and whatever you look up is added to
your practice deck automatically.

```sh
flutter pub get
flutter run
flutter test
flutter analyze
```

No accounts, no backend. All state is local (`shared_preferences`). The one
network call is translation (see below).

## Layout

| Path | What lives there |
| --- | --- |
| `lib/data/phrases.dart` | The curated phrase set (`allPhrases`), categories, selectable countries/settings, and `currentLanguage` |
| `lib/models/` | `Phrase`, `Language`, `Category`, `Place` |
| `lib/state/` | `ChangeNotifier`s, registered in `main.dart` via `provider`, each persisting to `shared_preferences` |
| `lib/models/trip.dart` | A trip: name, destination, settings — the container decks hang off |
| `lib/services/` | `TranslationProvider` and its implementations |
| `lib/screens/`, `lib/widgets/` | UI |
| `lib/theme/pocket_talk_theme.dart` | Palette (`PTColors`, `PTTints`) and type ramp (`ptHeading`, `ptBody`, `ptMono`) |

State objects: `VocabBank` (deck membership plus looked-up phrase content),
`PracticeScores` (per-phrase running score, weakest drilled first),
`RecentPhrases` (quick-access strip), `Trips` (the trips and which is
active).

Use the theme helpers rather than raw `Color`s or `TextStyle`s. `TicketRow`,
`PhraseFlipCard` and `PTSearchField` are shared — build on them rather than
restyling a copy per screen.

### Trips

A **trip** is the container for vocabulary: a name, a destination country and
the topics you've switched off for it. Those live on the trip rather than in
global settings because they describe a journey, not the language — so two
trips to different countries can show different wording (`carro` in Mexico,
`auto` in Chile) without one overwriting the other.

`Trips` (`lib/state/trips.dart`) owns the list and which one is active, and
exposes `activePlace`. Everything downstream still filters by a `Place`, so
only the *source* of it moved.

### Tailoring a trip: tags and muting

A phrase can carry **tags** naming the setting or activity it belongs to —
`Hiking`, `Public transit`, `Surfing`. The vocabulary is two levels deep:
four settings (`Urban`, `Rural`, `Coastal`, `Mountain`), each with the
activities that only come up there. `environmentOptions` in
`lib/data/phrases.dart` is the whole list; `allEnvironmentTags` flattens it
and is what a phrase's tags are checked against.

**The nesting is a UI affordance, not a data relationship.** A surf phrase is
tagged `'Surfing'` alone, never `'Surfing'` *and* `'Coastal'` — a setting
never independently gates its own activities. Muting a setting mutes its
activities alongside it (`withActivitiesMuted`), and each can then be
switched back on by itself, so "not going near the coast, except to surf" is
a state the model can express.

**Everything is on by default.** `Trip.mutedTags` stores what the user
switched *off*, not what they chose, so a setting or activity added in a
later version is on for trips that already exist — a stored list of choices
would silently never mention it. Empty means the whole phrasebook is in play,
which is also why skipping the question during setup is now the generous
answer rather than the stingy one.

Muting reaches three places and deliberately stops short of two others:

| | muted topics |
| --- | --- |
| Browsing by category (`phrasesForPlace`) | hidden |
| The pre-populated practice deck ("Everything") | excluded |
| Search on the My trip tab (`phrasesForCountry`) | **still found** |
| The saved deck (`VocabBank.deckFor`) | **never filtered** |
| The recent strip | **never filtered** |

The last three are the point. Search and the recent strip are the user asking
for something by name, and a toggle set weeks ago shouldn't override that;
a phrase they bookmarked is a much stronger signal than a topic they left
alone, so muting never takes it away. Country scope is separate and applies
everywhere — that's `Phrase.availableIn`, while muting is
`Phrase.isMutedIn`.

Decks are membership, not copies: `VocabBank._decks` maps a phrase id to the
set of trips holding it. Looking the same phrase up for a second trip adds
membership rather than a duplicate, so its practice score — kept by phrase id
in `PracticeScores` — carries over instead of resetting. A phrase is saved
exactly when it belongs to at least one deck, so deleting a trip removes only
what was unique to it.

An install from before trips is carried over on first launch:
`Trips.migrateLegacySettings` turns the old global country and settings into
a first trip, and `VocabBank.adoptLegacySaves` puts everything already saved
into it.

### Tabs

`RootScaffold` in `main.dart` holds three, in an `IndexedStack` so each keeps
its state while you're on another:

1. **Translate** (`translate_screen.dart`) — the landing tab. Looks anything
   up, shows the recently-looked-up strip. A curated phrase wins when one
   matches the query, since it has a real pronunciation and a hand-picked
   practice word; everything else is translated live and saved to the active
   trip's deck.
2. **My trip** (`my_trip_screen.dart`) — the active trip's destination and
   how much of the phrasebook it's showing, then the curated set by category
   scoped to it. Its search covers the whole book for that country, muted
   topics included, and never calls the API; an unmatched search offers to
   hand the query to Translate, via the `onTranslate` callback `RootScaffold`
   passes down and `TranslateScreen.incomingQuery` picks up.
3. **Practice** (`deck_screen.dart`) — with one trip it opens straight into
   that deck; with several it lists a deck per trip, plus an umbrella deck
   per language that two or more trips share. Either way the deck screen
   offers two pools: **My deck** (what you saved, never filtered by muting)
   and **Everything** (the curated set for the trip minus muted topics, plus
   your own lookups). The session (`practice_screen.dart`) takes its deck as
   a parameter and is a pushed screen rather than inline, because the deck
   list below it shows every answer.

   A session asks `sessionLength` (20) phrases, taken off the top of the
   weakest-first order — "Everything" can be over a hundred phrases, and a
   round with no end in sight is one nobody finishes. "Practice again"
   re-sorts against the scores just recorded, so the next round is the
   next-weakest rather than a replay.

## Phrases come from two places

This is the main thing to know before changing anything phrase-related.

**Curated** phrases live in `allPhrases` and are referenced elsewhere by id
alone. They're hand-written: a phonetic `pronunciation` and a deliberately
hand-picked `blankWord` (the word practice blanks out — Spanish article and
gender agreement makes auto-picking unreliable, so it's chosen per phrase).
They can be scoped to countries, to settings, or carry per-country wording
variants.

**Looked-up** phrases are created at runtime by `Phrase.fromLookup` when a
search has no curated match. They carry their own content, because nothing
in the static data can resolve them, and `VocabBank` stores them in full.
Their `blankWord` is guessed by `autoBlankWord` — the longest non-function
word, a heuristic that will sometimes pick an awkward one — and their
pronunciation is generated (below) rather than hand-written.

Their pronunciation guide is generated rather than written, by
`spanishPronunciation` in `lib/models/pronunciation.dart` — rules, not a
dictionary, so it runs locally the instant a translation arrives. Spanish
spelling maps onto sound regularly enough that this works: vowels are fixed,
the consonant exceptions are a short list, and stress is a rule with a
written-accent override. It's measured against the curated guides in
`test/pronunciation_test.dart` (93.6% exact, 98.1% per word), which also
guards the floor. Note this is Spanish-specific — another language needs its
own implementation, and English would need a real pronouncing dictionary.

Their ids are `lookup_<languageCode>_<normalized english>`, so looking the
same thing up twice overwrites rather than duplicating.

**Resolving an id back to a phrase: use `VocabBank.resolve(id)`, not
`phraseById`.** `phraseById` only searches the curated set, so anywhere a
saved or recent id is turned back into a phrase, it would silently drop
everything the user looked up. It lives on the bank because the bank is what
holds the looked-up content — `lib/data/phrases.dart` is data and knows
nothing about state.

## Translation

`lib/services/translation_service.dart`.

`TranslationProvider` is the seam. `MyMemoryTranslationProvider` is the
current implementation: free, no API key. `activeTranslationProvider` names
the one in use; `main.dart` hands it to the widget tree, so screens read it
via `context.read<TranslationProvider>()` and tests inject a fake.

**To move to a paid provider** (DeepL, Google Cloud Translate): add a class
implementing `TranslationProvider`, change the `activeTranslationProvider`
line. Nothing else should need to know.

Two things to know about MyMemory specifically:

- It answers **HTTP 200 even when refusing**. A blown quota comes back as
  `responseStatus` 403 with the complaint sitting in `translatedText`, which
  would otherwise be saved as though it were a real translation. The
  provider checks `responseStatus` for this reason.
- The anonymous tier is roughly **1k words/day per IP**. Expect the error
  state during heavy testing. Passing a contact email raises it; a paid
  provider removes the concern.

Lookups are debounced (500ms) and only fire when a query has no curated
match, so ordinary phrasebook searching costs nothing.

## Adding a second language

The data model is ready for this; the app around it is not yet. Already done:
`Language` exists, every `Phrase` and every `Trip` carries a `languageCode`,
`Trips.tripsForLanguage()` groups by it (which is what decides whether an
umbrella practice deck is offered), looked-up ids are namespaced by language,
and the translation call takes `from`/`to` rather than assuming Spanish.

Still hardcoded, and what a second language would need:

1. `currentLanguage` in `lib/data/phrases.dart` is a `const`. It needs to
   become selectable state (probably alongside `Trips`, since a trip already
   names the language it teaches), and the handful of `currentLanguage` reads
   point at that instead.
2. `targetLanguage` and `spanishCountries` are loose constants still used by
   `country_screen.dart` and `pt_app_bar.dart`. They'd be read off the
   active `Language`, which already has `name` and `countries` fields for
   this — the trip editor already reads `currentLanguage.countries`.
3. `allPhrases` is Spanish-only and its entries rely on the `languageCode`
   default of `'es'`. Curated content for another language would need to set
   it explicitly.
4. `RecentPhrases` is not language- or trip-scoped — it's a flat id list, so
   the quick-access strip would mix languages until it filters too.
5. There's no language-switcher UI at all.

## Tests

`flutter test`. Widget tests build screens under a `MultiProvider` harness —
see `test/translate_lookup_test.dart`, which fakes `TranslationProvider` so
the lookup path is covered without touching the network. `test/phrases_test.dart`
holds the invariants for the curated data (unique ids, blank words that
actually appear in their phrase, variants naming only selectable countries),
so it will catch most content mistakes.
