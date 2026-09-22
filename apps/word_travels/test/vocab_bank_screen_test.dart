import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/screens/practice_screen.dart';
import 'package:pocket_talk/screens/vocab_bank_screen.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/practice_scores.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Widget _harness(VocabBank vocabBank) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: vocabBank),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider(create: (_) => PracticeScores()),
    ],
    child: const MaterialApp(home: VocabBankScreen()),
  );
}

void main() {
  testWidgets(
    'the practice button is visible even with nothing saved yet',
    (tester) async {
      await tester.pumpWidget(_harness(VocabBank()));

      // A button that only appears once its own precondition is met would
      // leave nothing on screen announcing practice exists at all.
      expect(find.widgetWithText(FloatingActionButton, 'Practice'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping practice while empty hints at what unlocks it, without navigating',
    (tester) async {
      await tester.pumpWidget(_harness(VocabBank()));

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Practice'));
      await tester.pump(); // show the SnackBar

      expect(find.textContaining('Bookmark a phrase'), findsOneWidget);
      expect(find.byType(PracticeScreen), findsNothing);
    },
  );

  testWidgets(
    'tapping practice with something saved opens the practice screen',
    (tester) async {
      final vocabBank = VocabBank()..toggle('basics_1');
      await tester.pumpWidget(_harness(vocabBank));

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Practice'));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeScreen), findsOneWidget);
    },
  );
}
