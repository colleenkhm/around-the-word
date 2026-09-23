import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/screens/deck_screen.dart';
import 'package:pocket_talk/screens/practice_screen.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/practice_scores.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Widget _harness(VocabBank vocabBank, {PracticeScores? scores}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: vocabBank),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider.value(value: scores ?? PracticeScores()),
    ],
    child: const MaterialApp(home: DeckScreen()),
  );
}

void main() {
  testWidgets('practice leads, rather than hiding behind the deck', (
    tester,
  ) async {
    final vocabBank = VocabBank()..toggle('basics_1');
    await tester.pumpWidget(_harness(vocabBank));

    // The start card sits above the deck list.
    final startY = tester.getTopLeft(find.text('Ready to practice')).dy;
    final deckY = tester.getTopLeft(find.text('YOUR DECK')).dy;
    expect(startY, lessThan(deckY));
  });

  testWidgets('the start button is visible even with nothing saved yet', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(VocabBank()));

    // A button that only appears once its own precondition is met would
    // leave nothing on screen announcing practice exists at all.
    expect(find.text('Start practice'), findsOneWidget);
    expect(find.text('Nothing to practice yet'), findsOneWidget);
    expect(find.text('YOUR DECK'), findsNothing);
  });

  testWidgets(
    'tapping start while empty hints at what unlocks it, without navigating',
    (tester) async {
      await tester.pumpWidget(_harness(VocabBank()));

      await tester.tap(find.text('Start practice'));
      await tester.pump(); // show the SnackBar

      expect(find.textContaining('Save or look up a phrase'), findsOneWidget);
      expect(find.byType(PracticeScreen), findsNothing);
    },
  );

  testWidgets('tapping start with a deck opens the practice screen', (
    tester,
  ) async {
    final vocabBank = VocabBank()..toggle('basics_1');
    await tester.pumpWidget(_harness(vocabBank));

    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();

    expect(find.byType(PracticeScreen), findsOneWidget);
  });

  testWidgets('the deck size and what needs work are surfaced up front', (
    tester,
  ) async {
    final vocabBank = VocabBank()
      ..toggle('basics_1')
      ..toggle('basics_2')
      ..toggle('basics_3');
    // basics_2 has been missed more than it's been got right.
    final scores = PracticeScores()..recordIncorrect('basics_2');

    await tester.pumpWidget(_harness(vocabBank, scores: scores));

    expect(find.text('3 phrases · 1 needs work'), findsOneWidget);
  });

  testWidgets('a deck with nothing struggling just says it is ready', (
    tester,
  ) async {
    final vocabBank = VocabBank()..toggle('basics_1');
    await tester.pumpWidget(_harness(vocabBank));

    expect(find.text('1 phrase ready'), findsOneWidget);
  });

  testWidgets('a looked-up phrase shows a generated pronunciation guide', (
    tester,
  ) async {
    final vocabBank = VocabBank()
      ..saveLookup(
        Phrase.fromLookup(
          english: 'my flight was delayed',
          target: 'mi vuelo se ha retrasado',
          language: currentLanguage,
        ),
      );
    await tester.pumpWidget(_harness(vocabBank));

    expect(find.text('mee VWEH-loh seh ah reh-trah-SAH-doh'), findsOneWidget);
  });

  testWidgets('a lookup saved before guides existed still shows one', (
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
    final vocabBank = VocabBank()..saveLookup(Phrase.fromJson(stored));
    await tester.pumpWidget(_harness(vocabBank));

    expect(find.text('mee VWEH-loh seh ah reh-trah-SAH-doh'), findsOneWidget);
  });

  testWidgets('a looked-up phrase renders as a card like any other', (
    tester,
  ) async {
    // It belongs to no curated category, which used to throw "Bad state: No
    // element" here the moment anything was looked up.
    final vocabBank = VocabBank()
      ..saveLookup(
        Phrase.fromLookup(
          english: 'my flight was delayed',
          target: 'mi vuelo se ha retrasado',
          language: currentLanguage,
        ),
      );
    await tester.pumpWidget(_harness(vocabBank));

    expect(tester.takeException(), isNull);
    expect(find.text('mi vuelo se ha retrasado'), findsOneWidget);
  });
}
