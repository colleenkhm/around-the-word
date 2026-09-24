import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/screens/practice_screen.dart';
import 'package:pocket_talk/state/trips.dart';
import 'trip_support.dart';
import 'package:pocket_talk/state/practice_scores.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

late Trips _trips;
late String _tripId;

/// Builds the deck the way the practice tab does — everything saved to the
/// trip — then hands it to the screen.
Widget _harness({
  required VocabBank vocabBank,
  required PracticeScores scores,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: vocabBank),
      ChangeNotifierProvider.value(value: _trips),
      ChangeNotifierProvider.value(value: scores),
    ],
    child: MaterialApp(
      home: PracticeScreen(
        phrases: vocabBank.deckFor(_tripId),
        place: _trips.activePlace,
      ),
    ),
  );
}

void main() {
  setUp(() {
    _trips = tripsWithOne();
    _tripId = onlyTripId(_trips);
  });

  testWidgets('the deck starts with the lowest-scoring phrase', (
    tester,
  ) async {
    final vocabBank = VocabBank()
      ..toggle('basics_1', _tripId) // Please
      ..toggle('basics_2', _tripId) // Thank you
      ..toggle('basics_3', _tripId); // Good morning
    final scores = PracticeScores()
      ..recordCorrect('basics_1')
      ..recordCorrect('basics_1')
      ..recordCorrect('basics_1')
      ..recordCorrect('basics_1')
      ..recordCorrect('basics_1') // basics_1: +5
      ..recordIncorrect('basics_2')
      ..recordIncorrect('basics_2')
      ..recordIncorrect('basics_2'); // basics_2: -3, basics_3 stays at 0

    await tester.pumpWidget(_harness(vocabBank: vocabBank, scores: scores));

    // basics_2 has the lowest (most negative) score, so it should be first.
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('a correct answer adds a point to that phrase', (tester) async {
    final vocabBank = VocabBank()..toggle('basics_1', _tripId); // Please / Por favor
    final scores = PracticeScores();
    await tester.pumpWidget(_harness(vocabBank: vocabBank, scores: scores));

    await tester.enterText(find.byType(TextField), 'favor');
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(scores.scoreFor('basics_1'), 1);
    expect(find.text('Correct!'), findsOneWidget);
  });

  testWidgets('a wrong answer subtracts a point from that phrase', (
    tester,
  ) async {
    final vocabBank = VocabBank()..toggle('basics_1', _tripId);
    final scores = PracticeScores();
    await tester.pumpWidget(_harness(vocabBank: vocabBank, scores: scores));

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(scores.scoreFor('basics_1'), -1);
  });

  testWidgets('looked-up phrases drill in the same deck as bookmarked ones', (
    tester,
  ) async {
    final lookup = Phrase.fromLookup(
      english: 'my flight was delayed',
      target: 'mi vuelo se ha retrasado',
      language: currentLanguage,
    );
    final vocabBank = VocabBank()
      ..toggle('basics_1', _tripId) // curated
      ..saveLookup(lookup, _tripId); // translated in-app
    // Sort the lookup to the front so it's the first question asked.
    final scores = PracticeScores()..recordIncorrect(lookup.id);

    await tester.pumpWidget(_harness(vocabBank: vocabBank, scores: scores));

    // One pool: both sources are in the same deck.
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('my flight was delayed'), findsOneWidget);

    // And the auto-picked blank word makes a working exercise.
    await tester.enterText(find.byType(TextField), 'retrasado');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
    expect(scores.scoreFor(lookup.id), 0); // -1 then +1
  });
}
