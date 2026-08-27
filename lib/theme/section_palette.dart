import 'package:flutter/material.dart';

import '../utils/contrast_color.dart';

/// One section's colors — generated per country. See [SectionPalette].
class SectionColors {
  /// Section background — a real flag color, unmodified.
  final Color tint;

  /// Black or white, whichever reads on [tint].
  final Color textColor;

  /// A version of [tint] guaranteed to read on white.
  final Color accentOnWhite;

  const SectionColors({
    required this.tint,
    required this.textColor,
    required this.accentOnWhite,
  });
}

/// The eight section accents plus the ticket stub's own accent —
/// generated from a country's actual flag colors. See HANDOFF.md for the
/// full decision history (why per-country, why not pastel, why toned).
class SectionPalette {
  final SectionColors visa;
  final SectionColors cities;
  final SectionColors borderCountries;
  final SectionColors times;
  final SectionColors advisory;
  final SectionColors language;
  final SectionColors norms;

  /// Additional Resources' accent.
  final SectionColors resources;

  /// Ticket header/site-nav accent — a deepened version of [visa]'s hue.
  final SectionColors header;

  /// Ticket stub's own background — a midtone, distinct from [header]
  /// and [visa].
  final SectionColors stub;

  const SectionPalette({
    required this.visa,
    required this.cities,
    required this.borderCountries,
    required this.times,
    required this.advisory,
    required this.language,
    required this.norms,
    required this.resources,
    required this.header,
    required this.stub,
  });

  /// All eight section accents in a fixed order, for widgets that want a
  /// color cycle rather than one fixed section color — e.g. each month
  /// square in [BestTimesSection] gets the next one, wrapping around.
  List<SectionColors> get cycle =>
      [visa, cities, borderCountries, times, advisory, language, norms, resources];

  /// Maps [colors] (most-prominent first) onto the eight sections,
  /// cycling if fewer than eight.
  factory SectionPalette.fromFlagColors(List<Color> colors) {
    assert(
      colors.isNotEmpty,
      'SectionPalette.fromFlagColors needs at least one color',
    );
    final ordered = List.generate(8, (i) => colors[i % colors.length]);
    final sectionColors = ordered.map(_colorsFor).toList();
    return SectionPalette(
      visa: sectionColors[0],
      cities: sectionColors[1],
      borderCountries: sectionColors[2],
      times: sectionColors[3],
      advisory: sectionColors[4],
      language: sectionColors[5],
      norms: sectionColors[6],
      resources: sectionColors[7],
      header: _colorsFor(_deepen(colors.first), toneDown: false),
      stub: _colorsFor(_midtone(colors.first), toneDown: false),
    );
  }

  static SectionColors _colorsFor(Color rawColor, {bool toneDown = true}) {
    final tint = toneDown ? _toned(rawColor) : rawColor;
    return SectionColors(
      tint: tint,
      textColor: readableTextColor(tint),
      accentOnWhite: accentReadableOnWhite(rawColor),
    );
  }

  // Same hue, ~28% less saturation.
  static Color _toned(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * 0.72).clamp(0.0, 1.0))
        .toColor();
  }

  // Dark, fixed-saturation version for the masthead. Saturation kept high
  // even though it's dark — a dark *and* desaturated red reads as brown,
  // not red. See design-preferences.md.
  static Color _deepen(Color color) {
    final hue = HSLColor.fromColor(color).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.16).toColor();
  }

  // Medium-dark version for the ticket stub. Same brown-vs-hue reasoning
  // as _deepen, one step lighter.
  static Color _midtone(Color color) {
    final hue = HSLColor.fromColor(color).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.55, 0.32).toColor();
  }

  /// Loading-state/extraction-failure fallback.
  static final fallback = SectionPalette(
    visa: _colorsFor(const Color(0xFFD8EDF8)),
    cities: _colorsFor(const Color(0xFFE8E0F5)),
    borderCountries: _colorsFor(const Color(0xFFE8E0F5)),
    times: _colorsFor(const Color(0xFFFDF3D0)),
    advisory: _colorsFor(const Color(0xFFD8EDE0)),
    language: _colorsFor(const Color(0xFFFAE0E4)),
    norms: _colorsFor(const Color(0xFFFDECD8)),
    resources: _colorsFor(const Color(0xFFD8EDF8)),
    header: _colorsFor(_deepen(const Color(0xFFD8EDF8)), toneDown: false),
    stub: _colorsFor(_midtone(const Color(0xFFD8EDF8)), toneDown: false),
  );
}
