import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/country_guide.dart';

void main() {
  group('Season.covers', () {
    test('normal range (no wraparound)', () {
      final season = Season(startMonth: 5, endMonth: 6, label: 'Green season');
      expect(season.covers(5), isTrue);
      expect(season.covers(6), isTrue);
      expect(season.covers(4), isFalse);
      expect(season.covers(7), isFalse);
    });

    test('wraparound range spanning the new year', () {
      final season = Season(startMonth: 12, endMonth: 4, label: 'Dry season');
      expect(season.covers(12), isTrue);
      expect(season.covers(1), isTrue);
      expect(season.covers(4), isTrue);
      expect(season.covers(5), isFalse);
      expect(season.covers(11), isFalse);
    });

    test('single-month range', () {
      final season = Season(startMonth: 8, endMonth: 8, label: 'Peak heat');
      expect(season.covers(8), isTrue);
      expect(season.covers(7), isFalse);
      expect(season.covers(9), isFalse);
    });
  });

  group('CountryGuide.seasonFor', () {
    test('finds the season covering a given date, wraparound included', () {
      final guide = CountryGuide(
        bestTimes: const [],
        seasons: const [
          Season(startMonth: 12, endMonth: 4, label: 'Dry season'),
          Season(startMonth: 5, endMonth: 11, label: 'Green season'),
        ],
        practicalNorms: const [],
        dressExpectations: const [],
        cuisine: const [],
        historicalEvents: const [],
        festivals: const [],
        prepNotes: const [],
      );

      expect(guide.seasonFor(DateTime(2026, 1, 15))!.label, 'Dry season');
      expect(guide.seasonFor(DateTime(2026, 7, 1))!.label, 'Green season');
    });

    test('returns null when seasons is empty or has a gap', () {
      const guide = CountryGuide(
        bestTimes: [],
        seasons: [Season(startMonth: 12, endMonth: 4, label: 'Dry season')],
        practicalNorms: [],
        dressExpectations: [],
        cuisine: [],
        historicalEvents: [],
        festivals: [],
        prepNotes: [],
      );

      expect(guide.seasonFor(DateTime(2026, 7, 1)), isNull);
    });
  });
}
