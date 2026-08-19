import 'package:flutter/material.dart';

/// Design tokens for the country page's **collapsible-sections** restyle —
/// built against `trip-dashboard-v5.html` (2026-08-18, Colleen's mockup:
/// "override any existing design decisions with what you see here").
///
/// **Deliberately a second, parallel token set — not a repoint of
/// [CountryTheme]'s values.** [CountryTheme] already drives the app's
/// global `MaterialApp` theme, `DestinationScreen`, and the shared
/// `SiteHeader`/`CountryHeader` widgets; this mockup only shows the country
/// page (confirmed with Colleen before building — scope is this screen and
/// its own [SiteHeader] instance, not a site-wide reskin). Consuming
/// widgets that are exclusive to the country page (verified: `CitiesSection`,
/// `LanguagePairSection`, `BestTimesSection`, `PracticalNormsSection`, the
/// old `TravelInfoSection`'s split-out replacements, `CountryHeader`) pull
/// from here now instead. `CountryTheme` itself is untouched.
///
/// **This is a direct, deliberate reversal of two very recent, explicit
/// decisions** — flagged before building, per Colleen's own working-style
/// note in CLAUDE.md, then overridden per her instruction:
/// - `design-preferences.md` (2026-08-17): "stay in the warm/cream family
///   — cool or blue-leaning tones don't fit this page." The mockup's
///   section tints (sky blue, lavender, sage green) are exactly the cool
///   family that note rejected. If a cool tone reads wrong again once it's
///   actually on screen, that's the same signal the note describes — worth
///   a fast look, not a surprise.
/// - The 2026-08-11 "advisories and visa share one source, one section"
///   call (see the old `TravelInfoSection`'s doc comment) — this mockup
///   splits them into two independent accordion sections, each citing its
///   own source line even when (as for Costa Rica) it's really the same
///   URL/date twice. Simpler than trying to visually connect a shared
///   footer across two now-independently-collapsible cards.
///
/// **2026-08-18, later: the six fixed section pastels
/// (`sky`/`lavender`/`sage`/`rose`/`butter`/`peach`) and their gradients
/// were removed from here** once section colors became per-country,
/// derived from each flag's own colors instead — see
/// `SectionPalette.fromFlagColors`. `skyDark`/`butterDark`/`roseDark`
/// stay: `skyDark` is still this file's own text-style default,
/// `butterDark`/`roseDark` are still genuinely reused elsewhere
/// (the featured-city gold star, [advisoryColor]'s level scale) for
/// reasons unrelated to section identity.
class AccordionTheme {
  AccordionTheme._();

  // --- Surfaces -------------------------------------------------------

  /// The page canvas, behind every card — mockup's `body` background.
  static const page = Color(0xFFF0EEF5);

  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAF8);

  // --- Colors still genuinely reused outside per-country section theming --
  // See this class's doc comment on why these three specifically survived
  // the fixed-pastel cleanup: `skyDark` is this file's own text-style
  // default below, `butterDark`/`roseDark` back the featured-city gold
  // star and [advisoryColor]'s level scale.

  static const skyDark = Color(0xFF3A78AA);
  static const butterDark = Color(0xFFB08020);
  static const roseDark = Color(0xFFC45070);

  // --- Ink --------------------------------------------------------------

  static const ink = Color(0xFF1A1520);
  static const ink2 = Color(0xFF3D3848);
  static const ink3 = Color(0xFF6B6578);

  static const rule = Color(0xFFE0DCE8);
  static const ruleDark = Color(0xFFC8C3D4);

  // --- Status -----------------------------------------------------------

  static const ok = Color(0xFF2E7A50);
  static const warn = Color(0xFF8A6200);
  static const danger = Color(0xFF8B2020);

  /// Advisory levels 1-4, low to high risk. The mockup only shows level 1
  /// (green); 2-4 extrapolate along this palette's warm accents rather
  /// than inventing new hues, same pattern [CountryTheme.advisoryColor]
  /// already used for the old palette.
  static Color advisoryColor(int level) => switch (level) {
        1 => ok,
        2 => butterDark,
        3 => roseDark,
        _ => danger,
      };

  /// Elevation for the ticket + flat white cards — the mockup's layered
  /// `--shadow-a/b/c`, condensed to what [CountryTheme.cardShadow] already
  /// does for the other palette.
  static const cardShadow = [
    BoxShadow(color: Color(0x1A1A1520), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A1A1520), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x121A1520), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const cardRadius = 8.0;

  // --- Fonts --------------------------------------------------------------

  static const fraunces = 'Fraunces';
  static const dmSans = 'DM Sans';
  static const dmMono = 'DM Mono';

  // --- Text styles ----------------------------------------------------

  /// The ticket's country name — `.tk-name`.
  static TextStyle tkName(double fontSize) => TextStyle(
        fontFamily: fraunces,
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        height: 1.0,
        letterSpacing: fontSize * -0.02,
        color: white,
      );

  /// A large serif heading on the light page background (not the dark
  /// ticket) — [ink], not [white]. Added 2026-08-18 for
  /// `DestinationScreen`'s "Where are you going?" heading, bringing it
  /// onto this palette/type system alongside the country page.
  static TextStyle pageHeading(double fontSize) => TextStyle(
        fontFamily: fraunces,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.1,
        letterSpacing: fontSize * -0.01,
        color: ink,
      );

  /// `.tk-eyebrow` / `.tk-native`-style small mono label on the dark
  /// ticket surface.
  ///
  /// **All sizes in this file bumped up a bit** (2026-08-18, per Colleen:
  /// "let's make all the text at least a bit bigger") — same "size up,
  /// not down, for anything a user actually needs to read" instinct
  /// design-preferences.md already recorded from 2026-08-17's ticket-stub
  /// pass, just applied a second time across the whole file rather than
  /// one section.
  static const tkEyebrow = TextStyle(
    fontFamily: dmMono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
    color: Color(0x59FFFFFF), // ~35% white
  );

  static const tkNative = TextStyle(
    fontFamily: dmMono,
    fontSize: 12.5,
    letterSpacing: 0.4,
    color: Color(0x59FFFFFF),
  );

  /// `.tf-label` — the ticket stub's field label.
  static const tfLabel = TextStyle(
    fontFamily: dmMono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: skyDark,
  );

  /// `.tf-val` — the ticket stub's big value.
  static const tfVal = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 27,
    letterSpacing: -0.2,
    color: ink,
  );

  /// `.tf-sub`.
  static const tfSub = TextStyle(
    fontFamily: dmMono,
    fontSize: 12,
    color: ink3,
  );

  /// `.tf-link` / the "Expand all" / "Collapse all" links.
  static const tfLink = TextStyle(
    fontFamily: dmMono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: skyDark,
  );

  /// `.sec-name` — a section's title, in both collapsed and expanded rows.
  static const secName = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 19,
    height: 1.1,
    letterSpacing: -0.1,
    color: ink,
  );

  /// `.sec-meta` — the collapsed-only subheading (currently not rendered
  /// at all — see [AccordionSection.showSubheading] — but kept in step
  /// with everything else here in case that flips back on).
  static const secMeta = TextStyle(
    fontFamily: dmMono,
    fontSize: 11.5,
    color: ink3,
    letterSpacing: 0.2,
  );

  /// `.s-label` — small caps mono field label inside an expanded card.
  static const sLabel = TextStyle(
    fontFamily: dmMono,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.4,
    color: ink3,
  );

  /// `.s-head` — a card's bold serif headline.
  static const sHead = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: ink,
  );

  /// `.s-body` — paragraph copy inside an expanded card.
  static const sBody = TextStyle(
    fontFamily: dmSans,
    fontSize: 15,
    color: ink2,
    height: 1.55,
  );

  /// Row title (city names, list-row headings) — `.city-name`/similar.
  static const rowTitle = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w600,
    fontSize: 15.5,
    color: ink,
  );

  /// Row meta (population, index numbers, verified dates).
  static const rowMeta = TextStyle(
    fontFamily: dmMono,
    fontSize: 12.5,
    color: ink3,
  );

  /// Source-row mono footer text.
  static const srcRow = TextStyle(
    fontFamily: dmMono,
    fontSize: 11.5,
    color: ink3,
  );
}
