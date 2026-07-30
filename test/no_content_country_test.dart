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
    'selecting an inactive country dead-ends at the coming-soon screen, not the category flow',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AroundTheWordApp());
      await tester.pumpAndSettle();

      // Mexico is a real, selectable country in countries.json, but it's
      // not active — every country shows up in search, only active ones
      // lead to the real flow (see DestinationScreen._selectCountry).
      // Search text deliberately doesn't equal the full country name, so it
      // doesn't also match the search field's own current text below.
      await tester.enterText(find.byType(TextField), 'Mex');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mexico'));
      await tester.pumpAndSettle();

      expect(
        find.text("We're working on content for Mexico — here in the meantime:"),
        findsOneWidget,
      );
      expect(find.text('Google Translate'), findsOneWidget);
      expect(find.text('What do you want to learn?'), findsNothing);
    },
  );
}
