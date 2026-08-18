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
///   — cool or blue-leaning tones don't fit this page." This palette's
///   core section tints ([sky], [lavender], [sage]) are exactly the cool
///   family that note rejected. If a cool tone reads wrong again once it's
///   actually on screen, that's the same signal the note describes — worth
///   a fast look, not a surprise.
/// - The 2026-08-11 "advisories and visa share one source, one section"
///   call (see the old `TravelInfoSection`'s doc comment) — this mockup
///   splits them into two independent accordion sections, each citing its
///   own source line even when (as for Costa Rica) it's really the same
///   URL/date twice. Simpler than trying to visually connect a shared
///   footer across two now-independently-collapsible cards.
class AccordionTheme {
  AccordionTheme._();

  // --- Surfaces -------------------------------------------------------

  /// The page canvas, behind every card — mockup's `body` background.
  static const page = Color(0xFFF0EEF5);

  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAF8);

  // --- Section tints (collapsed row + expanded card background) -------
  // One pastel + one "dark" (text-on-pastel / accent) per section, per
  // the mockup's --lavender/--sage/--rose/--butter/--sky/--peach pairs.

  static const lavender = Color(0xFFE8E0F5);
  static const lavenderDark = Color(0xFF7C5CBF);

  static const sage = Color(0xFFD8EDE0);
  static const sageDark = Color(0xFF3A7A58);

  static const rose = Color(0xFFFAE0E4);
  static const roseDark = Color(0xFFC45070);

  static const butter = Color(0xFFFDF3D0);
  static const butterDark = Color(0xFFB08020);

  static const sky = Color(0xFFD8EDF8);
  static const skyDark = Color(0xFF3A78AA);

  static const peach = Color(0xFFFDECD8);

  /// Visa & Entry's collapsed-row background — matches the mockup's
  /// `.sec-visa` (`linear-gradient(285deg, rgba(200,225,245,.5) 0%, var(--white) 55%)`),
  /// a pale-blue-to-white diagonal. **Deliberately not the flat [sky]** —
  /// added 2026-08-18, per Colleen: Visa & Entry read as the same solid
  /// blue as the ticket stub directly above it. Every other section keeps
  /// its plain pastel [tint]; only this one mockup class defines a
  /// gradient distinct from its own section color (the rest gradient from
  /// a faint tint *to* their own pastel, not to white).
  static const visaRowGradient = LinearGradient(
    begin: Alignment(0.6, -1),
    end: Alignment(-0.6, 1),
    colors: [Color(0xFFDCE9F5), white],
    stops: [0.0, 0.55],
  );

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

  /// `.tk-eyebrow` / `.tk-native`-style small mono label on the dark
  /// ticket surface.
  static const tkEyebrow = TextStyle(
    fontFamily: dmMono,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
    color: Color(0x59FFFFFF), // ~35% white
  );

  static const tkNative = TextStyle(
    fontFamily: dmMono,
    fontSize: 11,
    letterSpacing: 0.4,
    color: Color(0x59FFFFFF),
  );

  /// `.tf-label` — the ticket stub's field label.
  static const tfLabel = TextStyle(
    fontFamily: dmMono,
    fontSize: 8.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: skyDark,
  );

  /// `.tf-val` — the ticket stub's big value.
  static const tfVal = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    letterSpacing: -0.2,
    color: ink,
  );

  /// `.tf-sub`.
  static const tfSub = TextStyle(
    fontFamily: dmMono,
    fontSize: 10.5,
    color: ink3,
  );

  /// `.tf-link` / the "Expand all" / "Collapse all" links.
  static const tfLink = TextStyle(
    fontFamily: dmMono,
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: skyDark,
  );

  /// `.sec-name` — a section's title, in both collapsed and expanded rows.
  static const secName = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    height: 1.1,
    letterSpacing: -0.1,
    color: ink,
  );

  /// `.sec-meta` — the collapsed-only subheading. Hidden once a section is
  /// expanded (see [AccordionSection]'s doc comment).
  static const secMeta = TextStyle(
    fontFamily: dmMono,
    fontSize: 10,
    color: ink3,
    letterSpacing: 0.2,
  );

  /// `.s-label` — small caps mono field label inside an expanded card.
  static const sLabel = TextStyle(
    fontFamily: dmMono,
    fontSize: 9,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.4,
    color: ink3,
  );

  /// `.s-head` — a card's bold serif headline.
  static const sHead = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: ink,
  );

  /// `.s-body` — paragraph copy inside an expanded card.
  static const sBody = TextStyle(
    fontFamily: dmSans,
    fontSize: 13.5,
    color: ink2,
    height: 1.55,
  );

  /// Row title (city names, list-row headings) — `.city-name`/similar.
  static const rowTitle = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: ink,
  );

  /// Row meta (population, index numbers, verified dates).
  static const rowMeta = TextStyle(
    fontFamily: dmMono,
    fontSize: 11,
    color: ink3,
  );

  /// Source-row mono footer text.
  static const srcRow = TextStyle(
    fontFamily: dmMono,
    fontSize: 10,
    color: ink3,
  );
}
