import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/utils/format_population.dart';

void main() {
  test('groups by thousands', () {
    expect(formatPopulation(664046), '664,046');
    expect(formatPopulation(5180829), '5,180,829');
  });

  test('leaves numbers under 1000 alone', () {
    expect(formatPopulation(6000), '6,000');
    expect(formatPopulation(999), '999');
    expect(formatPopulation(0), '0');
  });
}
