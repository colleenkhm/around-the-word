import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/country.dart';

void main() {
  group('Country.fromJson', () {
    test('parses an active country', () {
      final country = Country.fromJson({
        'countryCode': 'CR',
        'name': 'Costa Rica',
        'continent': 'north-america',
        'languageCode': 'es',
        'active': true,
      });

      expect(country.countryCode, 'CR');
      expect(country.name, 'Costa Rica');
      expect(country.continent, 'north-america');
      expect(country.languageCode, 'es');
      expect(country.active, isTrue);
    });

    test('parses an inactive country', () {
      final country = Country.fromJson({
        'countryCode': 'FR',
        'name': 'France',
        'continent': 'europe',
        'languageCode': 'fr',
        'active': false,
      });

      expect(country.active, isFalse);
    });
  });
}
