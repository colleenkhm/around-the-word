import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/main.dart';

void main() {
  testWidgets('App boots to the continent map screen', (tester) async {
    await tester.pumpWidget(const AroundTheWordApp());
    await tester.pumpAndSettle();

    expect(find.text('Where are you going?'), findsOneWidget);
    // The map itself renders. Actual tap selection is covered by
    // resolveContinentTap/resolveCountryTap in
    // test/data/map_tap_resolution_test.dart rather than a pixel tap here —
    // computing a specific country's exact on-screen shape coordinates
    // would be brittle for very little extra confidence.
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
