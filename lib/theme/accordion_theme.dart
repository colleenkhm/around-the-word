import 'package:flutter/material.dart';

/// Design tokens for the country page's collapsible-sections restyle.
/// A parallel token set to [CountryTheme], scoped to the country page
/// only. See HANDOFF.md for history.
class AccordionTheme {
  AccordionTheme._();

  // --- Surfaces -------------------------------------------------------

  /// Page canvas, behind every card.
  static const page = Color(0xFFF0EEF5);

  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAF8);

  // --- Colors reused outside per-country section theming ------------------

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

  /// Advisory levels 1-4, low to high risk.
  static Color advisoryColor(int level) => switch (level) {
        1 => ok,
        2 => butterDark,
        3 => roseDark,
        _ => danger,
      };

  /// Elevation for the ticket and flat white cards.
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

  /// Ticket's country name.
  static TextStyle tkName(double fontSize) => TextStyle(
        fontFamily: fraunces,
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        height: 1.0,
        letterSpacing: fontSize * -0.02,
        color: white,
      );

  /// Serif heading on the light page background.
  static TextStyle pageHeading(double fontSize) => TextStyle(
        fontFamily: fraunces,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.1,
        letterSpacing: fontSize * -0.01,
        color: ink,
      );

  /// Small mono label on the dark ticket surface.
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

  /// Ticket stub's field label.
  static const tfLabel = TextStyle(
    fontFamily: dmMono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: skyDark,
  );

  /// Ticket stub's big value.
  static const tfVal = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 27,
    letterSpacing: -0.2,
    color: ink,
  );

  static const tfSub = TextStyle(
    fontFamily: dmMono,
    fontSize: 12,
    color: ink3,
  );

  /// Expand/collapse-all links.
  static const tfLink = TextStyle(
    fontFamily: dmMono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: skyDark,
  );

  /// Section title, collapsed and expanded rows.
  static const secName = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 19,
    height: 1.1,
    letterSpacing: -0.1,
    color: ink,
  );

  /// Collapsed-only subheading (currently unused, see showSubheading).
  static const secMeta = TextStyle(
    fontFamily: dmMono,
    fontSize: 11.5,
    color: ink3,
    letterSpacing: 0.2,
  );

  /// Small caps mono field label inside an expanded card.
  static const sLabel = TextStyle(
    fontFamily: dmMono,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.4,
    color: ink3,
  );

  /// Card's bold serif headline.
  static const sHead = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: ink,
  );

  /// Paragraph copy inside an expanded card.
  static const sBody = TextStyle(
    fontFamily: dmSans,
    fontSize: 15,
    color: ink2,
    height: 1.55,
  );

  /// Row title — city names, list-row headings.
  static const rowTitle = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w600,
    fontSize: 15.5,
    color: ink,
  );

  /// Row meta — population, index numbers, verified dates.
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
