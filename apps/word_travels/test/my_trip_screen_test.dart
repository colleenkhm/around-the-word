import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:word_travels/data/phrases.dart';
import 'package:word_travels/models/place.dart';
import 'package:word_travels/screens/my_trip_screen.dart';
import 'trip_support.dart';
import 'package:word_travels/state/recent_phrases.dart';
import 'package:word_travels/state/vocab_bank.dart';

Widget _harness({ValueChanged<String>? onTranslate, Set<String> muted = const {}}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VocabBank()),
      ChangeNotifierProvider.value(value: tripsWithOne(mutedTags: muted)),
      ChangeNotifierProvider(create: (_) => RecentPhrases()),
    ],
    child: MaterialApp(
      home: MyTripScreen(onTranslate: onTranslate ?? (_) {}),
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

  testWidgets('a muted topic is hidden from browsing but not from search', (
    tester,
  ) async {
    final muted = withActivitiesMuted({'Coastal'});
    await tester.pumpWidget(_harness(muted: muted));

    // The trip says how much it's put away, and the phrase count comes down
    // with it.
    final shown = phrasesForPlace(Place('Mexico', muted)).length;
    expect(shown, lessThan(phrasesForCountry(const Place('Mexico')).length));
    expect(find.textContaining('1 topic off'), findsOneWidget);
    expect(find.textContaining('$shown phrases'), findsOneWidget);

    // But someone who types "surf" has said exactly what they want, and a
    // toggle they set weeks ago shouldn't get in the way of that.
    await tester.enterText(find.byType(TextField).first, 'surf');
    await tester.pumpAndSettle();

    expect(find.text('¿Dónde podemos alquilar tablas de surf?'), findsOneWidget);
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
