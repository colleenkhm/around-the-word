import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/main.dart';

void main() {
  testWidgets(
    'Destination search -> categories -> personalizing -> use -> vocab flow',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AroundTheWordApp());
      await tester.pumpAndSettle(); // reference data loads async

      // Destination screen: search field filters the full country list.
      expect(find.text('Where are you going?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Costa');
      await tester.pumpAndSettle();
      expect(find.text('Costa Rica'), findsOneWidget);
      await tester.tap(find.text('Costa Rica'));
      await tester.pumpAndSettle();

      // Category selection: pick Museums, continue.
      expect(find.text('What do you want to learn?'), findsOneWidget);
      await tester.tap(find.text('Museums'));
      await tester.pump(); // let the FAB's enabled state rebuild
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle(); // personalizing screen's cosmetic delay

      // Learn/Use fork.
      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();

      // Category list (Use mode) -> Museums has no sub-subjects, so this
      // goes straight to the vocab list.
      await tester.tap(find.text('Museums'));
      await tester.pumpAndSettle();
      expect(find.text('la entrada'), findsOneWidget);
      expect(find.text('the entrance ticket'), findsOneWidget);
    },
  );
}
