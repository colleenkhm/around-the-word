import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forin/utils/hex_color.dart';

void main() {
  test('parses a "#RRGGBB" string', () {
    expect(hexToColor('#002B7F'), const Color(0xFF002B7F));
  });

  test('parses a bare "RRGGBB" string, no leading #', () {
    expect(hexToColor('CE1126'), const Color(0xFFCE1126));
  });

  test('is case-insensitive', () {
    expect(hexToColor('#ce1126'), const Color(0xFFCE1126));
  });
}
