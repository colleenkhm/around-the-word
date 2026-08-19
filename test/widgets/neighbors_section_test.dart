import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/country.dart';
import 'package:around_the_word/widgets/country_page/neighbors_section.dart';

const _accent = Color(0xFF3A78AA);

/// [NeighborsSection] resolves codes against a plain passed-in country
/// list (see that class's doc) rather than watching `TripSelection`
/// itself, so it's testable without a `Provider`/full app boot.
void main() {
  final allCountries = [
    const Country(
      countryCode: 'PA',
      name: 'Panama',
      continent: 'north-america',
      languageCode: 'es',
      active: false,
    ),
    const Country(
      countryCode: 'NI',
      name: 'Nicaragua',
      continent: 'north-america',
      languageCode: 'es',
      active: false,
    ),
  ];

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  testWidgets('renders each resolved neighbor by name, no exception', (
    tester,
  ) async {
    await pump(
      tester,
      NeighborsSection(
        borderingCountryCodes: const ['PA', 'NI'],
        allCountries: allCountries,
        tint: _accent,
        textColor: Colors.white,
        onTapNeighbor: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Panama'), findsOneWidget);
    expect(find.text('Nicaragua'), findsOneWidget);
  });

  testWidgets('an unresolved code still renders, as its raw code', (
    tester,
  ) async {
    await pump(
      tester,
      NeighborsSection(
        borderingCountryCodes: const ['PA', 'ZZ'],
        allCountries: allCountries,
        tint: _accent,
        textColor: Colors.white,
        onTapNeighbor: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Panama'), findsOneWidget);
    expect(find.text('ZZ'), findsOneWidget);
  });

  testWidgets('tapping a resolved neighbor calls onTapNeighbor with it', (
    tester,
  ) async {
    Country? tapped;
    await pump(
      tester,
      NeighborsSection(
        borderingCountryCodes: const ['PA'],
        allCountries: allCountries,
        tint: _accent,
        textColor: Colors.white,
        onTapNeighbor: (country) => tapped = country,
      ),
    );

    await tester.tap(find.text('Panama'));
    await tester.pump();

    expect(tapped?.countryCode, 'PA');
  });

  testWidgets('empty list renders nothing', (tester) async {
    await pump(
      tester,
      NeighborsSection(
        borderingCountryCodes: const [],
        allCountries: allCountries,
        tint: _accent,
        textColor: Colors.white,
        onTapNeighbor: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NeighborsSection), findsOneWidget);
  });
}
