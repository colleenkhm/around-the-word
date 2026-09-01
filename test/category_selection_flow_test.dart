import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:forin/screens/category_selection_screen.dart';
import 'package:forin/state/trip_selection.dart';

// Split out of widget_test.dart 2026-08-17 when DestinationScreen stopped
// leading here directly (an active country now opens the country page
// instead — see CountryHeaderPreviewScreen). The categories -> personalizing
// -> Learn/Use -> vocab flow itself is unchanged and still real code (it'll
// become the Language tab's sub-flow per the pivot-3 docs), so this pumps
// CategorySelectionScreen directly against a seeded TripSelection rather
// than going through the full app/navigation from search.
void main() {
  testWidgets(
    'categories -> personalizing -> use -> vocab flow',
    (WidgetTester tester) async {
      final trip = TripSelection();
      await trip.loadReferenceData();
      trip.selectCountry(trip.countries.firstWhere((c) => c.countryCode == 'CR'));

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: trip,
          child: const MaterialApp(home: CategorySelectionScreen()),
        ),
      );
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
