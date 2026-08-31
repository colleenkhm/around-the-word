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

/// The nine accordion row accents plus the ticket header/stub's own
/// accent — generated from a country's actual flag colors, two tones
/// alternating down the real row order (see [fromFlagColors]). See
/// HANDOFF.md for the full decision history (why per-country, why not
/// pastel, why toned, why two alternating tones rather than one per
/// section).
class SectionPalette {
  final SectionColors visa;
  final SectionColors cities;
  final SectionColors borderCountries;
  final SectionColors times;
  final SectionColors advisory;
  final SectionColors language;
  final SectionColors norms;
  final SectionColors holidays;

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
    required this.holidays,
    required this.resources,
    required this.header,
    required this.stub,
  });

  /// The accordion's real row order top-to-bottom (see
  /// `CountryHeaderPreviewScreen.build`'s section list) — the order that
  /// actually matters for "do adjacent rows alternate," which is *not*
  /// the constructor's param order above (holidays sits right after times
  /// on screen, not near the end). [fromFlagColors] assigns by this order
  /// specifically so alternation is correct on screen, not just in the
  /// param list.
  List<SectionColors> get _rowOrder =>
      [visa, cities, borderCountries, times, holidays, advisory, language, norms, resources];

  /// All nine section accents in real on-screen row order, for widgets
  /// that want a color cycle rather than one fixed section color — e.g.
  /// each month square in [BestTimesSection] gets the next one, wrapping
  /// around.
  List<SectionColors> get cycle => _rowOrder;

  /// Two tones only, alternating strictly down the real row order — not
  /// one color per section. A country's flag can have very few genuinely
  /// distinct hues (or several near-duplicate swatches at different
  /// lightness bands from the same hue), and assigning a fixed slot per
  /// *section* rather than per *row position* let two adjacent rows land
  /// on near-identical colors (e.g. "When to Visit" and "Holidays" both
  /// maroon back to back) — flagged directly against a real screenshot.
  /// Picking just two colors and alternating by row-order parity makes
  /// that structurally impossible instead of merely unlikely.
  factory SectionPalette.fromFlagColors(List<Color> colors) {
    assert(
      colors.isNotEmpty,
      'SectionPalette.fromFlagColors needs at least one color',
    );
    final (colorA, colorB) = _alternatingPair(colors);
    final tintA = _colorsFor(colorA);
    final tintB = _colorsFor(colorB);
    // Real row order: visa, cities, borderCountries, times, holidays,
    // advisory, language, norms, resources — even/odd position in *that*
    // order, then mapped back onto the named fields below.
    return SectionPalette(
      visa: tintA,
      cities: tintB,
      borderCountries: tintA,
      times: tintB,
      holidays: tintA,
      advisory: tintB,
      language: tintA,
      norms: tintB,
      resources: tintA,
      header: _colorsFor(_deepen(_headerSource(colors)), toneDown: false),
      stub: _colorsFor(_midtone(_headerSource(colors)), toneDown: false),
    );
  }

  // Picks two colors from `colors` (most-prominent first) that read as
  // genuinely different — different enough in hue or lightness that
  // alternating between them is visible, not just technically two
  // different Color values. Falls back to a lightened variant of the
  // first color if every extracted swatch is too close to it (a flag
  // that's functionally monochrome plus white/black), so alternation
  // still has something to alternate between.
  static (Color, Color) _alternatingPair(List<Color> colors) {
    final first = colors.first;
    for (final candidate in colors.skip(1)) {
      if (_readsDistinct(first, candidate)) return (first, candidate);
    }
    final hsl = HSLColor.fromColor(first);
    final lightened = hsl.withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0)).toColor();
    return (first, lightened);
  }

  static bool _readsDistinct(Color a, Color b) {
    final ha = HSLColor.fromColor(a);
    final hb = HSLColor.fromColor(b);
    final hueDiff = (ha.hue - hb.hue).abs();
    final hueDistance = hueDiff > 180 ? 360 - hueDiff : hueDiff;
    // Hue comparison alone misses white-vs-color (hue is meaningless at
    // zero saturation) — a lightness gap catches that case too.
    return hueDistance > 40 || (ha.lightness - hb.lightness).abs() > 0.25;
  }

  // The masthead/stub want a real hue to deepen, not just the single most
  // prominent color — white/black are valid, common flag colors (see the
  // per-country-palette note in design-preferences.md) but have no real
  // hue of their own, so a white-or-black-first flag (Finland: white
  // field, blue cross) should still get a masthead colored by its actual
  // chromatic color (blue) rather than converging on a generic dark gray.
  // Falls through to colors.first (letting _deepen/_midtone's own
  // achromatic guard handle it) only if every extracted color is
  // achromatic — a genuinely colorless flag, not just white/black-first.
  static Color _headerSource(List<Color> colors) {
    for (final color in colors) {
      if (HSLColor.fromColor(color).saturation >= _achromaticSaturationThreshold) {
        return color;
      }
    }
    return colors.first;
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

  // Below this input saturation, a color has no real hue to preserve —
  // HSLColor.fromColor conventionally gives hue=0 (red) for true
  // white/black/gray, since hue is undefined when R=G=B. Confirmed live
  // 2026-08-26 against Finland (a majority-white flag): _deepen/_midtone
  // were forcing that meaningless hue=0 up to a real saturation, fabricating
  // a vivid dark red masthead out of a flag with no red in it at all. This
  // is the "known follow-on edge case, not yet fixed" flagged in HANDOFF.md
  // 2026-08-25 when black/white were first re-admitted as flag colors —
  // that entry anticipated a black-flag-first country tripping it; a
  // white-flag-first one did instead, same root cause.
  static const _achromaticSaturationThreshold = 0.08;

  // Dark, fixed-saturation version for the masthead. Saturation kept high
  // even though it's dark — a dark *and* desaturated red reads as brown,
  // not red (see design-preferences.md). Achromatic input is darkened
  // toward near-black instead of being pushed toward a fabricated hue.
  static Color _deepen(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < _achromaticSaturationThreshold) {
      return hsl.withSaturation(0.0).withLightness(0.16).toColor();
    }
    return HSLColor.fromAHSL(1.0, hsl.hue, 0.65, 0.16).toColor();
  }

  // Medium-dark version for the ticket stub. Same brown-vs-hue reasoning
  // as _deepen, one step lighter, same achromatic guard.
  static Color _midtone(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < _achromaticSaturationThreshold) {
      return hsl.withSaturation(0.0).withLightness(0.32).toColor();
    }
    return HSLColor.fromAHSL(1.0, hsl.hue, 0.55, 0.32).toColor();
  }

  /// Loading-state/extraction-failure fallback — same two-tone, real-row-
  /// order alternation as [fromFlagColors], not nine independent picks
  /// (the old fixed set had this same adjacent-duplicate problem: cities/
  /// borderCountries and times/holidays each repeated the same hex).
  static final fallback = SectionPalette(
    visa: _colorsFor(const Color(0xFFD8EDF8)),
    cities: _colorsFor(const Color(0xFFFDF3D0)),
    borderCountries: _colorsFor(const Color(0xFFD8EDF8)),
    times: _colorsFor(const Color(0xFFFDF3D0)),
    holidays: _colorsFor(const Color(0xFFD8EDF8)),
    advisory: _colorsFor(const Color(0xFFFDF3D0)),
    language: _colorsFor(const Color(0xFFD8EDF8)),
    norms: _colorsFor(const Color(0xFFFDF3D0)),
    resources: _colorsFor(const Color(0xFFD8EDF8)),
    header: _colorsFor(_deepen(const Color(0xFFD8EDF8)), toneDown: false),
    stub: _colorsFor(_midtone(const Color(0xFFD8EDF8)), toneDown: false),
  );
}
