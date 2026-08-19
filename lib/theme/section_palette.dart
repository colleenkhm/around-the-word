import 'package:flutter/material.dart';

import '../utils/contrast_color.dart';

/// One section's colors — what [AccordionTheme]'s `sky`/`skyDark` and its
/// five siblings used to be as fixed `static const` values. Now generated
/// per country instead (see [SectionPalette]).
class SectionColors {
  /// The section's background — a real flag color, unmodified (see
  /// [SectionPalette]'s class doc on why this isn't lightened/pastel).
  final Color tint;

  /// Black or white, whichever reads better on [tint] — see
  /// [readableTextColor]. Used for the section's title/meta text and
  /// anything else sitting directly on [tint].
  final Color textColor;

  /// A version of [tint] guaranteed to read on a *white* background —
  /// see [accentReadableOnWhite]. For accent details (links, borders,
  /// badges) inside a section's expanded white content cards, where
  /// [tint] itself might be too light (a flag's white or pale-yellow
  /// field, say) to work as body-text-sized accent color.
  final Color accentOnWhite;

  const SectionColors({
    required this.tint,
    required this.textColor,
    required this.accentOnWhite,
  });
}

/// The eight section accents (Visa & Entry, Cities, Neighbors, When to
/// Visit, Travel Advisory, Language, Practical Norms, Additional
/// Resources) plus the ticket stub's own accent — generated from a
/// country's actual flag colors rather than hand-picked per section.
///
/// **2026-08-18: per-country recoloring**, per Colleen: "how difficult
/// would it be to write code that pulls hex codes from each country's
/// flag and creates the color theme for that page based off of that" —
/// asked a second time; the first pass at something adjacent
/// (`CountryFacts.accentColorHex` + `CountryTheme.lightTint`, a single
/// hand-picked accent tinting the whole page) was built 2026-08-11 and
/// then explicitly turned off the same day ("I want the page theme to be
/// more overarchingly cohesive... a different pastel per country was
/// working against the one identity"). Confirmed directly this time that
/// she wants the bigger version anyway, reopening that call on purpose.
///
/// **Two corrections, same day, both from Colleen looking at the actual
/// rendered result:**
/// - First version spread one seed hue 60° apart six times — a generated
///   rainbow, not the flag's own colors ("I want the colors of the
///   sections to only be variations of the colors in that country's
///   flag"). Second version pulled `PaletteGenerator`'s vibrant/muted
///   *target* swatches, which surfaced small-but-vivid emblem/seal
///   colors alongside the flag's actual field colors ("I only want to
///   incorporate base flag colors, not every color in the seal"). Fixed
///   in [extractFlagBaseColors] by filtering `paletteColors` on
///   `population` (pixel count) instead of using target swatches at all
///   — see that function's doc comment.
/// - This class originally lightened each hue into a fixed pastel
///   band (matching the original hand-picked tokens' ~90% lightness).
///   Colleen rejected that too, twice — first clarifying what "pastel"
///   should even mean if kept ("a lighter version but not in a different
///   position on the actual color gradient"), then dropping the idea
///   entirely mid-message: "don't even do a pastel version. Just do the
///   main colors that are in the flag."
///
/// **Third correction, later the same day: "the colors are a bit too
/// bright."** [tint] is *still* the flag's own hue at (almost) its own
/// lightness — this doesn't reopen the "no pastel" call, which was
/// specifically about *lightening toward white*. What changed is
/// *saturation*: [tint] now runs through [_toned] first, which pulls
/// intensity down a controlled ~28% (same hue, same lightness, less
/// chroma) — the standard "don't run a large fill at 100% saturation,
/// save that for small accents" move, not a step back toward pastel.
/// [SectionColors.accentOnWhite] deliberately derives from the
/// **un-toned** raw color instead — a small link/badge/border reads
/// better at full intensity than a huge background does.
///
/// **Text color is computed, not guessed** — Colleen's own fallback
/// suggestion was a hardcoded rule ("if the color is white yellow or
/// orange... otherwise black") but she explicitly invited a real
/// function instead, so section text uses [readableTextColor] (WCAG
/// relative luminance) rather than a hue/name lookup — correct for any
/// color a flag could actually contain, not just the three she named.
class SectionPalette {
  final SectionColors visa;
  final SectionColors cities;

  /// Neighbors' accent — added 2026-08-19 alongside that new section (per
  /// Colleen), cycling the same flag colors as every other section, same
  /// reasoning [resources] already established for a section added after
  /// the original six.
  final SectionColors neighbors;

  final SectionColors times;
  final SectionColors advisory;
  final SectionColors language;
  final SectionColors norms;

  /// Additional Resources' accent — added 2026-08-18 alongside that new
  /// section (per Colleen), cycling the same flag colors as every other
  /// section rather than a special-cased neutral tone, so a 7th section
  /// doesn't need a different color story from the other six.
  final SectionColors resources;

  /// The ticket header/site-nav's own accent — a **deepened** version of
  /// the country's primary color (the same seed [visa] and the ticket
  /// stub share), not the generic fixed `AccordionTheme.ink` the header
  /// used before. Added 2026-08-18, per Colleen: the flat-black masthead
  /// "looks weird" sitting above a page that's otherwise entirely this
  /// country's own colors now — it read as leftover from before the
  /// per-country system existed (which it was), disconnected from
  /// everything below it. Tying the header to the same color family as
  /// the rest of the page, just pushed dark for weight/contrast, reads
  /// as one deliberate identity instead of "brand-black bar, then a
  /// separate colorful country page." See [_deepen].
  final SectionColors header;

  /// The ticket stub's own background (local time / currency) — a
  /// **midtone** version of the country's primary color, distinct from
  /// both [header] (darkest) and [visa] (the section it sits directly
  /// above). Added 2026-08-18, per Colleen: the stub used to share
  /// [visa]'s exact `tint`, and since the Visa & Entry row is the very
  /// next thing on the page, the seam between them disappeared — two
  /// adjacent blocks of the identical color read as one, not two. See
  /// [_midtone].
  final SectionColors stub;

  const SectionPalette({
    required this.visa,
    required this.cities,
    required this.neighbors,
    required this.times,
    required this.advisory,
    required this.language,
    required this.norms,
    required this.resources,
    required this.header,
    required this.stub,
  });

  /// Maps [colors] (real flag colors, most-prominent first — see
  /// [extractFlagBaseColors]) onto the accordion's eight sections in
  /// order, cycling (`i % colors.length`) rather than requiring exactly
  /// eight — a three-color flag (most flags) repeats those three across
  /// the eight slots, not eight distinct-but-invented colors.
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
      neighbors: sectionColors[2],
      times: sectionColors[3],
      advisory: sectionColors[4],
      language: sectionColors[5],
      norms: sectionColors[6],
      resources: sectionColors[7],
      header: _colorsFor(_deepen(colors.first), toneDown: false),
      stub: _colorsFor(_midtone(colors.first), toneDown: false),
    );
  }

  /// [toneDown] defaults to `true` (every section fill) — [header] passes
  /// `false` since [_deepen] already did its own, separate lightness/
  /// saturation shaping; running [_toned] on top of that would fight it.
  static SectionColors _colorsFor(Color rawColor, {bool toneDown = true}) {
    final tint = toneDown ? _toned(rawColor) : rawColor;
    return SectionColors(
      tint: tint,
      textColor: readableTextColor(tint),
      accentOnWhite: accentReadableOnWhite(rawColor),
    );
  }

  /// Same hue, ~28% less saturation — see this class's doc comment on why
  /// this is a different axis from the "no pastel" lightening Colleen
  /// rejected (lightness is untouched here).
  static Color _toned(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * 0.72).clamp(0.0, 1.0))
        .toColor();
  }

  /// A dark, moderately-saturated version of [color] for the ticket
  /// header/site-nav — same hue, saturation pulled toward a consistent
  /// mid-strength (not the source color's own, which could be anywhere),
  /// lightness dropped to a near-black band. Deliberately not just
  /// "very dark" (a HSL lightness drop alone, on an already-low or
  /// already-high original saturation, can read muddy or oddly neon) —
  /// fixing saturation to one consistent value keeps every country's
  /// header reading as "the same kind of deep, confident color," not a
  /// grab-bag of however saturated each flag's particular hue happened
  /// to start.
  static Color _deepen(Color color) {
    final hue = HSLColor.fromColor(color).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.42, 0.15).toColor();
  }

  /// A medium-dark version of [color] for the ticket stub — same idea as
  /// [_deepen] (fixed saturation/lightness, not a relative shift off the
  /// source color, so it's dependable across every flag hue) but a step
  /// lighter, landing this between [_deepen]'s near-black masthead and a
  /// section's own lighter [_toned] tint. Gives the top of the page a
  /// deliberate three-step gradient — masthead, stub, first section row —
  /// instead of two of those three steps landing on the same color.
  static Color _midtone(Color color) {
    final hue = HSLColor.fromColor(color).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.38, 0.30).toColor();
  }

  /// The loading-state/extraction-failure fallback — the original
  /// hand-picked Costa-Rica-era hues (`AccordionTheme`'s old `sky`/
  /// `lavender`/`butter`/`sage`/`rose`/`peach` constants, plus `sky` and
  /// `lavender` reused for the seventh/eighth slots — Additional
  /// Resources and Neighbors didn't exist in that original six-token
  /// palette, so there's no seventh/eighth hand-picked hue to fall back
  /// to), run through the same [_colorsFor] derivation every real
  /// country's colors use, so nothing visibly changes for the loading
  /// flash or if flag-color extraction ever fails outright. `static
  /// final`, not `const` — [readableTextColor]/[accentReadableOnWhite]
  /// aren't const-evaluable.
  static final fallback = SectionPalette(
    visa: _colorsFor(const Color(0xFFD8EDF8)),
    cities: _colorsFor(const Color(0xFFE8E0F5)),
    neighbors: _colorsFor(const Color(0xFFE8E0F5)),
    times: _colorsFor(const Color(0xFFFDF3D0)),
    advisory: _colorsFor(const Color(0xFFD8EDE0)),
    language: _colorsFor(const Color(0xFFFAE0E4)),
    norms: _colorsFor(const Color(0xFFFDECD8)),
    resources: _colorsFor(const Color(0xFFD8EDF8)),
    header: _colorsFor(_deepen(const Color(0xFFD8EDF8)), toneDown: false),
    stub: _colorsFor(_midtone(const Color(0xFFD8EDF8)), toneDown: false),
  );
}
