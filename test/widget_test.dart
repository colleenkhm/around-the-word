import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:around_the_word/screens/category_selection_screen.dart';
import 'package:around_the_word/state/trip_selection.dart';

// Deliberately doesn't import main.dart/ContinentMapScreen — that pulls in
// countries_world_map, which embeds ~290KB of map data and is expensive to
// compile. Keeping this file's dependency graph light means this flow test
// isn't stuck paying that compile cost (and isn't bundled into the same
// compile unit as the test that does need it — see app_boot_test.dart).
void main() {
  testWidgets(
    'categories -> personalizing -> use -> vocab flow, starting from a '
    'continent/country already selected (i.e. what a successful map tap produces)',
    (tester) async {
      // Directly awaiting a raw asset-load Future in a testWidgets body can
      // hang — the fake-async zone testWidgets runs in doesn't reliably
      // deliver real async I/O (asset reads) on its own. tester.runAsync()
      // is the documented escape hatch: it steps outside the fake-async
      // zone to run genuinely async work, then hands control back.
      late TripSelection trip;
      await tester.runAsync(() async {
        trip = TripSelection();
        await trip.loadReferenceData();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: trip,
          child: const MaterialApp(home: CategorySelectionScreen()),
        ),
      );
      await tester.pump();

      trip.selectContinent('north-america');
      trip.selectCountry(
        trip.countries.firstWhere((c) => c.countryCode == 'CR'),
      );
      await tester.pump();

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
