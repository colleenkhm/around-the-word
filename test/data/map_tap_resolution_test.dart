import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/data/map_tap_resolution.dart';
import 'package:around_the_word/models/country.dart';
import 'package:around_the_word/models/world_map_country.dart';

void main() {
  const worldCountries = [
    WorldMapCountry(id: 'cr', name: 'Costa Rica', continent: 'north-america'),
    WorldMapCountry(id: 'mx', name: 'Mexico', continent: 'north-america'),
    WorldMapCountry(id: 'jp', name: 'Japan', continent: 'asia'),
  ];

  group('resolveContinentTap', () {
    test('unrecognized id (not on the map dataset at all)', () {
      final result = resolveContinentTap(
        tappedId: 'zz',
        worldCountries: worldCountries,
        isContinentActive: (_) => true,
      );
      expect(result, isA<ContinentTapUnrecognized>());
    });

    test('recognized but the continent has no active content', () {
      final result = resolveContinentTap(
        tappedId: 'jp',
        worldCountries: worldCountries,
        isContinentActive: (continent) => continent == 'north-america',
      );
      expect(result, isA<ContinentTapUnavailable>());
      expect((result as ContinentTapUnavailable).continent, 'asia');
    });

    test('recognized and the continent has active content', () {
      final result = resolveContinentTap(
        tappedId: 'cr',
        worldCountries: worldCountries,
        isContinentActive: (continent) => continent == 'north-america',
      );
      expect(result, isA<ContinentTapAvailable>());
      expect((result as ContinentTapAvailable).continent, 'north-america');
    });

    test('unrecognized id but tap position falls inside fallback bounds', () {
      final result = resolveContinentTap(
        tappedId: '', // what a background (no-path) tap resolves to
        worldCountries: worldCountries,
        isContinentActive: (continent) => continent == 'north-america',
        tapPosition: const Offset(0.25, 0.48),
        fallbackBounds: const Rect.fromLTRB(0.20, 0.44, 0.30, 0.53),
        fallbackContinent: 'north-america',
      );
      expect(result, isA<ContinentTapAvailable>());
      expect((result as ContinentTapAvailable).continent, 'north-america');
    });

    test('unrecognized id with tap position outside fallback bounds stays unrecognized', () {
      final result = resolveContinentTap(
        tappedId: '',
        worldCountries: worldCountries,
        isContinentActive: (_) => true,
        tapPosition: const Offset(0.9, 0.9),
        fallbackBounds: const Rect.fromLTRB(0.20, 0.44, 0.30, 0.53),
        fallbackContinent: 'north-america',
      );
      expect(result, isA<ContinentTapUnrecognized>());
    });

    test('a real match takes priority over the fallback bounds', () {
      final result = resolveContinentTap(
        tappedId: 'jp',
        worldCountries: worldCountries,
        isContinentActive: (_) => true,
        // Inside the fallback rect, but 'jp' is a real match — should
        // resolve to Japan/asia, not get overridden by the fallback.
        tapPosition: const Offset(0.25, 0.48),
        fallbackBounds: const Rect.fromLTRB(0.20, 0.44, 0.30, 0.53),
        fallbackContinent: 'north-america',
      );
      expect(result, isA<ContinentTapAvailable>());
      expect((result as ContinentTapAvailable).continent, 'asia');
    });
  });

  group('resolveCountryTap', () {
    const countries = [
      Country(
        countryCode: 'CR',
        name: 'Costa Rica',
        continent: 'north-america',
        languageCode: 'es',
        active: true,
      ),
      Country(
        countryCode: 'MX',
        name: 'Mexico',
        continent: 'north-america',
        languageCode: 'es',
        active: false,
      ),
    ];

    test('unrecognized id (not on the map dataset at all)', () {
      final result = resolveCountryTap(
        tappedId: 'zz',
        worldCountries: worldCountries,
        countries: countries,
      );
      expect(result, isA<CountryTapUnrecognized>());
    });

    test('a real country we have no content for at all', () {
      final result = resolveCountryTap(
        tappedId: 'jp',
        worldCountries: worldCountries,
        countries: countries,
      );
      expect(result, isA<CountryTapUnavailable>());
      expect((result as CountryTapUnavailable).name, 'Japan');
    });

    test('a curated country that is present but inactive', () {
      final result = resolveCountryTap(
        tappedId: 'mx',
        worldCountries: worldCountries,
        countries: countries,
      );
      expect(result, isA<CountryTapUnavailable>());
      expect((result as CountryTapUnavailable).name, 'Mexico');
    });

    test('an active curated country resolves to that Country', () {
      final result = resolveCountryTap(
        tappedId: 'cr',
        worldCountries: worldCountries,
        countries: countries,
      );
      expect(result, isA<CountryTapAvailable>());
      expect((result as CountryTapAvailable).country.countryCode, 'CR');
    });

    test('country code matching is case-insensitive', () {
      final result = resolveCountryTap(
        tappedId: 'cr', // lowercase, like the map's ids
        worldCountries: worldCountries,
        countries: countries, // countryCode is 'CR', uppercase
      );
      expect(result, isA<CountryTapAvailable>());
    });
  });
}
