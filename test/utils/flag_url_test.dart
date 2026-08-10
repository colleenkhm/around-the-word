import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/utils/flag_url.dart';

void main() {
  test('builds the public, keyless flagcdn.com PNG URL', () {
    expect(flagPngUrl('CR'), 'https://flagcdn.com/w160/cr.png');
  });

  test('lowercases the ISO code', () {
    expect(flagPngUrl('gr'), 'https://flagcdn.com/w160/gr.png');
  });
}
