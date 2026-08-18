import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/main.dart';

void main() {
  testWidgets(
    'Destination search -> country page',
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

      // An active country now opens the country page directly (2026-08-17)
      // rather than the old CategorySelectionScreen checkboxes — that flow
      // is still real code (see category_selection_flow_test.dart), just
      // not reachable from here until it's wired as the Language tab.
      expect(find.text('Where are you going?'), findsNothing);
      expect(find.text('What do you want to learn?'), findsNothing);

      // 2026-08-18: the country page is now a collapsible accordion —
      // every section always renders as a row (see
      // CountryHeaderPreviewScreen's class doc), but a city name is only
      // in the tree once its section is expanded.
      expect(find.text('Cities'), findsOneWidget);
      expect(find.text('4 destinations'), findsOneWidget);
      expect(find.text('San José'), findsNothing); // collapsed by default

      await tester.tap(find.text('Cities'));
      await tester.pumpAndSettle();
      expect(find.text('San José'), findsOneWidget); // Costa Rica's capital
    },
  );
}
