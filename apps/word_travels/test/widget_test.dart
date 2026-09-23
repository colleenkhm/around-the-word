import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_talk/main.dart';

void main() {
  testWidgets('welcome, country and setting picks lead to the app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PocketTalkApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Where are you using Spanish?'), findsOneWidget);
    await tester.tap(find.text('Mexico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What will it be like there?'), findsOneWidget);
    await tester.tap(find.text('Coastal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Lands on Translate.
    expect(find.text('Translate a word or phrase'), findsOneWidget);
    expect(find.textContaining('Type anything'), findsOneWidget);

    // The curated phrasebook is one tab over.
    await tester.tap(find.text('Phrasebook'));
    await tester.pumpAndSettle();

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Food & drink'), findsOneWidget);
  });
}
