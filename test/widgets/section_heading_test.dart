import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forin/widgets/country_page/section_heading.dart';

/// Regression test for a real breakage (2026-08-11): an earlier
/// [SectionHeading] used `LayoutBuilder` to space its dashed trailing
/// line, which threw inside `TravelInfoSection`'s desktop layout —
/// `_AdvisoriesColumn`/`_VisaColumn` (each starting with a
/// `SectionHeading`) sit inside an `IntrinsicHeight` there, and
/// `LayoutBuilder` explicitly doesn't support intrinsic-dimension
/// queries. Nothing in this suite otherwise renders `SectionHeading` or
/// `CountryHeaderPreviewScreen` at all, so that broke a real running app
/// without any test catching it — this exists specifically to close that
/// gap for this one failure mode, not as general coverage of the preview
/// screen.
void main() {
  testWidgets('renders inside an IntrinsicHeight without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SectionHeading('Advisories')),
                SizedBox(width: 16),
                Expanded(child: SectionHeading('Visa & entry')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Advisories'), findsOneWidget);
    expect(find.text('Visa & entry'), findsOneWidget);
  });

  testWidgets('renders at a realistic narrow (mobile) width without overflowing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 150, child: SectionHeading('Cities')),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
