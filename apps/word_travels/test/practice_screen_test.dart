import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/screens/practice_screen.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/practice_scores.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Widget _harness({
  required VocabBank vocabBank,
  required PracticeScores scores,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: vocabBank),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider.value(value: scores),
    ],
    child: const MaterialApp(home: PracticeScreen()),
  );
}

void main() {
  testWidgets('the deck starts with the lowest-scoring phrase', (
    tester,
  ) async {
    final vocabBank = VocabBank()
      ..toggle('basics_1') // Please
      ..toggle('basics_2') // Thank you
      ..toggle('basics_3'); // Good morning
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
    final vocabBank = VocabBank()..toggle('basics_1'); // Please / Por favor
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
    final vocabBank = VocabBank()..toggle('basics_1');
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
      ..toggle('basics_1') // curated
      ..saveLookup(lookup); // translated in-app
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
