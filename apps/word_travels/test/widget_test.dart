import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_talk/main.dart';

void main() {
  testWidgets('welcome screen leads to Home', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PocketTalkApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Food & drink'), findsOneWidget);
  });
}
