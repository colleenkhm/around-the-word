import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/travel_info.dart';
import 'package:around_the_word/widgets/country_page/travel_info_section.dart';

/// Covers two things nothing else in the suite touches: (1) the
/// desktop side-by-side layout, which wraps both cards in an
/// `IntrinsicHeight` — the exact context that broke `SectionHeading`
/// once already (see `test/widgets/section_heading_test.dart`) — and (2)
/// the 2026-08-11 shared-source behavior added here, since a regression
/// that silently brought back two "Source (see latest)" links wouldn't
/// be caught by anything else either.
void main() {
  final advisory = TravelAdvisory(
    issuingAuthority: 'US State Department',
    level: 'Level 1',
    levelLabel: 'Exercise Normal Precautions',
    summary: 'Overall a very safe destination.',
    officialUrl: 'https://travel.state.gov/costa-rica',
    lastVerifiedAt: DateTime(2026, 7, 1),
  );

  final visaWithApplyLink = VisaInfo(
    summary: 'US citizens may enter visa-free for up to 90 days.',
    officialUrl: 'https://travel.state.gov/costa-rica',
    applicationUrl: 'https://costarica-embassy.org/visas/',
    lastVerifiedAt: DateTime(2026, 7, 1),
    nationalityIsoCode: 'US',
  );

  Future<void> pumpAt(WidgetTester tester, Size size, Widget child) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('desktop: shares one Source link, no exception from IntrinsicHeight',
      (tester) async {
    await pumpAt(
      tester,
      const Size(1200, 900),
      TravelInfoSection(advisories: [advisory], visa: visaWithApplyLink),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Source (see latest)'), findsOneWidget);
    expect(find.textContaining('Verified'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('mobile: still shares one Source link, no exception', (tester) async {
    await pumpAt(
      tester,
      const Size(400, 900),
      TravelInfoSection(advisories: [advisory], visa: visaWithApplyLink),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Source (see latest)'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('advisories only: falls back to the advisory citing its own source',
      (tester) async {
    await pumpAt(tester, const Size(1200, 900), TravelInfoSection(advisories: [advisory]));

    expect(tester.takeException(), isNull);
    expect(find.text('Source (see latest)'), findsOneWidget);
  });

  testWidgets('visa only: falls back to the visa citing its own source', (tester) async {
    await pumpAt(
      tester,
      const Size(1200, 900),
      TravelInfoSection(advisories: const [], visa: visaWithApplyLink),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Source (see latest)'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });
}
