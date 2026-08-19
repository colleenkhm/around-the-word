import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/main.dart';

// Kept in its own file, not alongside widget_test.dart's flow test — pumping
// a second full AroundTheWordApp in the same test file makes pumpAndSettle
// hang (a pre-existing flutter_test quirk, reproduced with two bare
// pumpWidget/pumpAndSettle calls and nothing else from this app), not
// anything specific to this scenario.
void main() {
  testWidgets(
    'selecting a country with no curated bundle opens the country page, every section "coming soon"',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AroundTheWordApp());
      await tester.pumpAndSettle();

      // Mexico is a real, selectable country in countries.json, but it's
      // not `active` and has no `assets/data/bundles/mx.json` — 2026-08-18:
      // every country now opens the country page (see
      // CountryHeaderPreviewScreen's class doc), not a coming-soon dead
      // end, `active` or not. Search text deliberately doesn't equal the
      // full country name, so it doesn't also match the search field's own
      // current text below.
      await tester.enterText(find.byType(TextField), 'Mex');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mexico'));
      await tester.pumpAndSettle();

      // The country name renders (ticket header), and every accordion
      // section is present as a row, but collapsed by default — its
      // "Coming soon" body only shows once expanded (see
      // AccordionSection's class doc). (Collapsed-row subheadings, which
      // would otherwise read "Coming soon" too, are hidden for now — see
      // AccordionSection.showSubheading — so not asserted here.)
      expect(find.text('Mexico'), findsWidgets);
      expect(find.text('What do you want to learn?'), findsNothing);
      expect(find.text('Cities'), findsOneWidget);

      await tester.tap(find.text('Cities'));
      await tester.pumpAndSettle();
      expect(find.text("Coming soon — we haven't curated this yet."), findsOneWidget);
    },
  );
}
