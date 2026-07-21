import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/main.dart';

void main() {
  testWidgets('Category list shows subjects and drills into phrases', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AroundTheWordApp());

    // Category list is shown first.
    expect(find.text('Food'), findsOneWidget);

    // A category with sub-subjects opens a subject list.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(find.text('Cooking'), findsOneWidget);
    expect(find.text('Grocery Shopping'), findsOneWidget);

    // Selecting a subject shows its phrases.
    await tester.tap(find.text('Cooking'));
    await tester.pumpAndSettle();
    expect(find.text('recipe'), findsOneWidget);

    // A category with a single subject skips straight to its phrases.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('20 Common Verbs'), 200);
    await tester.tap(find.text('20 Common Verbs'));
    await tester.pumpAndSettle();
    expect(find.text('to be'), findsOneWidget);
  });
}
