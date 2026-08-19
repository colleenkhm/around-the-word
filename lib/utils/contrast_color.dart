import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Picks black or white, whichever reads better on [background], via the
/// real WCAG 2.0 relative-luminance formula.
Color readableTextColor(Color background) {
  return _contrastRatio(background, Colors.white) >= _contrastRatio(background, Colors.black)
      ? Colors.white
      : Colors.black;
}

// WCAG 2.0 contrast ratio, 1.0 to 21.0.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a) + 0.05;
  final lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

// WCAG 2.0 relative luminance.
double _relativeLuminance(Color color) {
  double linearize(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// A darker version of [color], stepped down until it reads on white.
/// Unchanged if it already contrasts well enough.
Color accentReadableOnWhite(Color color) {
  if (_contrastRatio(color, Colors.white) >= 3.0) return color;
  final hsl = HSLColor.fromColor(color);
  var lightness = hsl.lightness;
  var candidate = color;
  while (_contrastRatio(candidate, Colors.white) < 3.0 && lightness > 0.15) {
    lightness -= 0.05;
    candidate = hsl.withLightness(lightness).toColor();
  }
  return candidate;
}
