import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/utils/format_date.dart';

void main() {
  test('formats as "Mon D, YYYY"', () {
    expect(formatShortDate(DateTime(2026, 7, 1)), 'Jul 1, 2026');
    expect(formatShortDate(DateTime(2026, 3, 1)), 'Mar 1, 2026');
  });

  test('does not zero-pad the day', () {
    expect(formatShortDate(DateTime(2026, 1, 5)), 'Jan 5, 2026');
  });

  test('ignores time-of-day and timezone', () {
    expect(
      formatShortDate(DateTime.parse('2026-07-01T23:59:00Z').toUtc()),
      'Jul 1, 2026',
    );
  });
}
