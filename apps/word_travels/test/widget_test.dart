import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:word_travels/main.dart';

void main() {
  testWidgets('welcome, country and setting picks lead to the app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const WordTravelsApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Where are you using Spanish?'), findsOneWidget);
    await tester.tap(find.text('Mexico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Everything is on by default here, so this step is opt-out: tapping
    // Coastal switches it off rather than choosing it.
    expect(find.text('Anything you won\'t need?'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Coastal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Lands on Translate.
    expect(find.text('Translate a word or phrase'), findsOneWidget);
    expect(find.textContaining('Type anything'), findsOneWidget);

    // The curated phrasebook is one tab over, now headed by the trip that
    // was just set up, and saying how much of it got switched off.
    await tester.tap(find.text('My trip'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mexico'), findsWidgets);
    expect(find.textContaining('1 topic off'), findsOneWidget);
    expect(find.text('Food & drink'), findsOneWidget);
  });
}
