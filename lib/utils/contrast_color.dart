import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Picks plain black or white — whichever reads better against
/// [background] — using the actual WCAG 2.0 relative-luminance formula,
/// not a hardcoded "these hues are light" guess. Added 2026-08-18: the
/// per-country flag-color sections needed *some* rule for section-title
/// text color once the background stopped being a fixed set of six known
/// pastels, and Colleen asked directly for a real function over a
/// hardcoded list ("if the color is white yellow or orange... otherwise
/// black. or if you can create a better function... please do").
Color readableTextColor(Color background) {
  return _contrastRatio(background, Colors.white) >= _contrastRatio(background, Colors.black)
      ? Colors.white
      : Colors.black;
}

/// WCAG 2.0 contrast ratio between two colors — 1.0 (no contrast, same
/// color) to 21.0 (black vs. white). 3.0 is the WCAG AA minimum for large
/// text; 4.5 for body text.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a) + 0.05;
  final lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

/// WCAG 2.0 relative luminance — linearizes each sRGB channel (the
/// perceptual gamma curve) before weighting them by how much the human
/// eye actually responds to red/green/blue, rather than just averaging
/// the raw channel values.
double _relativeLuminance(Color color) {
  double linearize(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// A darker (same hue/saturation, lower lightness) version of [color],
/// stepped down until it contrasts reasonably against a white background
/// — for accent elements (links, borders) that need to sit on a *white*
/// card even though the section's own flag color might be too light to
/// read there (a flag with a white or pale-yellow field, say). Returns
/// [color] unchanged if it already contrasts well enough on its own —
/// this is a legibility floor, not a stylistic darken-everything rule.
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
