import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/screens/phrasebook_screen.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/recent_phrases.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Widget _harness({ValueChanged<String>? onTranslate}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VocabBank()),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider(create: (_) => RecentPhrases()),
    ],
    child: MaterialApp(
      home: PhrasebookScreen(onTranslate: onTranslate ?? (_) {}),
    ),
  );
}

void main() {
  testWidgets('shows the category grid when nothing is typed', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.text('Food & drink'), findsOneWidget);
    expect(find.text('Transportation'), findsOneWidget);
  });

  testWidgets('searching filters the curated set', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.enterText(find.byType(TextField).first, 'thank you');
    await tester.pumpAndSettle();

    expect(find.text('Gracias'), findsOneWidget);
    expect(find.text('Food & drink'), findsNothing);
  });

  testWidgets('an unmatched search hands the query to Translate', (
    tester,
  ) async {
    String? handedOver;
    await tester.pumpWidget(_harness(onTranslate: (q) => handedOver = q));

    await tester.enterText(find.byType(TextField).first, 'my flight was delayed');
    await tester.pumpAndSettle();

    // No dead end — it offers the lookup instead.
    expect(find.textContaining('Nothing in your phrasebook matches'), findsOneWidget);
    expect(handedOver, isNull);

    await tester.tap(find.text('Translate it instead'));
    await tester.pumpAndSettle();

    expect(handedOver, 'my flight was delayed');
  });

  testWidgets('never translates on its own — no provider is even needed', (
    tester,
  ) async {
    // The harness registers no TranslationProvider at all, so any attempt to
    // look something up here would throw rather than silently pass.
    await tester.pumpWidget(_harness());

    await tester.enterText(find.byType(TextField).first, 'my flight was delayed');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
