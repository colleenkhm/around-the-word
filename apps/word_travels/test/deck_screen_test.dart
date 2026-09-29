import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/models/trip.dart';
import 'package:pocket_talk/screens/deck_screen.dart';
import 'package:pocket_talk/screens/practice_screen.dart';
import 'package:pocket_talk/state/practice_scores.dart';
import 'package:pocket_talk/state/trips.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

import 'trip_support.dart';

late Trips _trips;
late String _tripId;

Widget _harness(VocabBank vocabBank, {PracticeScores? scores, Trips? trips}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: vocabBank),
      ChangeNotifierProvider.value(value: trips ?? _trips),
      ChangeNotifierProvider.value(value: scores ?? PracticeScores()),
    ],
    child: const MaterialApp(home: DeckScreen()),
  );
}

/// Scoped to the deck list, since the app-bar badge also shows the active
/// trip's name and would otherwise match too.
Finder _inList(String text) =>
    find.descendant(of: find.byType(ListView), matching: find.text(text));

Trip _addTrip(Trips trips, String country, {String? name}) {
  final trip = Trip.create(
    languageCode: currentLanguage.code,
    country: country,
    name: name,
  );
  trips.add(trip);
  return trip;
}

void main() {
  setUp(() {
    _trips = tripsWithOne(name: 'Mexico');
    _tripId = onlyTripId(_trips);
  });

  group('with a single trip it opens straight into the deck', () {
    testWidgets('practice leads, rather than hiding behind the deck', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(VocabBank()..toggle('basics_1', _tripId)));

      final startY = tester.getTopLeft(find.text('Ready to practice')).dy;
      final deckY = tester.getTopLeft(find.text('YOUR DECK')).dy;
      expect(startY, lessThan(deckY));
    });

    testWidgets('the start button shows even with nothing saved yet', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(VocabBank()));

      // A button that only appears once its own precondition is met would
      // leave nothing on screen announcing practice exists at all.
      expect(find.text('Start practice'), findsOneWidget);
      expect(find.text('Nothing to practice yet'), findsOneWidget);
      expect(find.text('YOUR DECK'), findsNothing);
    });

    testWidgets('tapping start while empty hints at what unlocks it', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(VocabBank()));

      await tester.tap(find.text('Start practice'));
      await tester.pump(); // show the SnackBar

      expect(find.textContaining('Save or look up a phrase'), findsOneWidget);
      expect(find.byType(PracticeScreen), findsNothing);
    });

    testWidgets('tapping start with a deck opens the practice screen', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(VocabBank()..toggle('basics_1', _tripId)));

      await tester.tap(find.text('Start practice'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeScreen), findsOneWidget);
    });

    testWidgets('the deck size and what needs work are surfaced up front', (
      tester,
    ) async {
      final vocabBank = VocabBank()
        ..toggle('basics_1', _tripId)
        ..toggle('basics_2', _tripId)
        ..toggle('basics_3', _tripId);
      final scores = PracticeScores()..recordIncorrect('basics_2');

      await tester.pumpWidget(_harness(vocabBank, scores: scores));

      expect(find.text('3 phrases · 1 needs work'), findsOneWidget);
    });
  });

  group('with several trips the decks are listed separately', () {
    testWidgets('one card per trip, plus an umbrella for the language', (
      tester,
    ) async {
      final trips = tripsWithOne(name: 'Mexico');
      final mexico = onlyTripId(trips);
      final spain = _addTrip(trips, 'Spain').id;

      final vocabBank = VocabBank()
        ..toggle('basics_1', mexico)
        ..toggle('basics_2', spain);

      await tester.pumpWidget(_harness(vocabBank, trips: trips));

      expect(_inList('Mexico'), findsOneWidget);
      expect(_inList('Spain'), findsOneWidget);
      // Both trips teach Spanish, so drilling all of it is offered too.
      expect(_inList('Spanish'), findsOneWidget);
    });

    testWidgets('the umbrella covers every trip in that language', (
      tester,
    ) async {
      final trips = tripsWithOne(name: 'Mexico');
      final mexico = onlyTripId(trips);
      final spain = _addTrip(trips, 'Spain').id;

      final vocabBank = VocabBank()
        ..toggle('basics_1', mexico)
        ..toggle('basics_2', spain);

      await tester.pumpWidget(_harness(vocabBank, trips: trips));
      await tester.tap(_inList('Spanish'));
      await tester.pumpAndSettle();

      expect(find.text('2 phrases ready'), findsOneWidget);
    });

    testWidgets('tapping a trip opens just that trip\'s deck', (tester) async {
      final trips = tripsWithOne(name: 'Mexico');
      final mexico = onlyTripId(trips);
      final spain = _addTrip(trips, 'Spain').id;

      final vocabBank = VocabBank()
        ..toggle('basics_1', mexico)
        ..toggle('basics_2', spain)
        ..toggle('basics_3', spain);

      await tester.pumpWidget(_harness(vocabBank, trips: trips));
      await tester.tap(_inList('Spain'));
      await tester.pumpAndSettle();

      expect(find.text('2 phrases ready'), findsOneWidget);
    });
  });

  group('choosing what the session draws from', () {
    testWidgets('it opens on the saved deck, with both pools counted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(VocabBank()..toggle('basics_1', _tripId)),
      );

      expect(find.text('My deck'), findsOneWidget);
      expect(find.text('Everything'), findsOneWidget);
      expect(find.text('YOUR DECK'), findsOneWidget);
      // The saved deck holds one; the phrasebook holds the rest.
      expect(find.text('1 phrase ready'), findsOneWidget);
    });

    testWidgets('switching to Everything drills the whole phrasebook', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(VocabBank()..toggle('basics_1', _tripId)),
      );

      await tester.tap(find.text('Everything'));
      await tester.pumpAndSettle();

      final pool = phrasesForPlace(_trips.activePlace).length;
      expect(pool, greaterThan(sessionLength));
      // Far more than one sitting, so the card promises a round, not the lot.
      expect(find.text('$sessionLength of $pool phrases ready'), findsOneWidget);
    });

    testWidgets('a muted topic stays in the saved deck', (tester) async {
      // Muting says "don't drill me on surfing"; bookmarking a surf phrase
      // says the opposite about that one phrase, and is the stronger signal.
      final trips = Trips()
        ..add(
          Trip.create(
            languageCode: currentLanguage.code,
            country: 'Mexico',
            name: 'Mexico',
            mutedTags: withActivitiesMuted({'Coastal'}),
          ),
        );
      final tripId = onlyTripId(trips);
      final vocabBank = VocabBank()..toggle('activities_11', tripId);

      await tester.pumpWidget(_harness(vocabBank, trips: trips));

      expect(find.text('1 phrase ready'), findsOneWidget);
      expect(find.text('¿Dónde podemos alquilar tablas de surf?'), findsOneWidget);
    });

    testWidgets('a muted topic is kept out of Everything', (tester) async {
      final trips = Trips()
        ..add(
          Trip.create(
            languageCode: currentLanguage.code,
            country: 'Mexico',
            name: 'Mexico',
            mutedTags: withActivitiesMuted({'Coastal'}),
          ),
        );

      await tester.pumpWidget(_harness(VocabBank(), trips: trips));
      await tester.tap(find.text('Everything'));
      await tester.pumpAndSettle();

      final ids = phrasesForPlace(trips.activePlace).map((p) => p.id);
      expect(ids, isNot(contains('activities_11')));
      expect(ids, contains('basics_1'));
    });
  });

  group('looked-up phrases', () {
    testWidgets('show a generated pronunciation guide', (tester) async {
      final vocabBank = VocabBank()
        ..saveLookup(
          Phrase.fromLookup(
            english: 'my flight was delayed',
            target: 'mi vuelo se ha retrasado',
            language: currentLanguage,
          ),
          _tripId,
        );
      await tester.pumpWidget(_harness(vocabBank));

      expect(find.text('mee VWEH-loh seh ah reh-trah-SAH-doh'), findsOneWidget);
    });

    testWidgets('one saved before guides existed still shows one', (
      tester,
    ) async {
      // Older versions stored an empty pronunciation on the phrase itself, so
      // reading the stored value back would leave these cards blank forever.
      // The guide is derived from the target instead, which heals them with
      // no migration.
      final stored = {
        'id': 'lookup_es_my_flight_was_delayed',
        'categoryId': 'lookup',
        'english': 'my flight was delayed',
        'target': 'mi vuelo se ha retrasado',
        'pronunciation': '',
        'blankWord': 'retrasado',
        'languageCode': 'es',
      };
      final vocabBank = VocabBank()
        ..saveLookup(Phrase.fromJson(stored), _tripId);
      await tester.pumpWidget(_harness(vocabBank));

      expect(find.text('mee VWEH-loh seh ah reh-trah-SAH-doh'), findsOneWidget);
    });

    testWidgets('render as a card like any other', (tester) async {
      // Belonging to no curated category used to throw "Bad state: No
      // element" here the moment anything was looked up.
      final vocabBank = VocabBank()
        ..saveLookup(
          Phrase.fromLookup(
            english: 'my flight was delayed',
            target: 'mi vuelo se ha retrasado',
            language: currentLanguage,
          ),
          _tripId,
        );
      await tester.pumpWidget(_harness(vocabBank));

      expect(tester.takeException(), isNull);
      expect(find.text('mi vuelo se ha retrasado'), findsOneWidget);
    });
  });
}
