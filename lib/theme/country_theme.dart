import 'package:flutter/material.dart';

/// Design tokens for the country page's passport/travel-document visual
/// language — colors and text styles lifted directly from the
/// country-page-mockups.html spec (2026-08-10). Plain static consts rather
/// than a ThemeExtension: this app's styling has stayed deliberately
/// simple so far (see HANDOFF.md on `provider` vs `riverpod`), and a
/// single reusable token class matches that without extra ceremony.
/// Revisit as a ThemeExtension if this ends up needing to vary by context
/// (e.g. a future dark mode) rather than being one fixed palette.
class CountryTheme {
  CountryTheme._();

  // Document ink navy / cool document-stock paper — deliberately not a
  // warm cream, per the mockup's own comment.
  static const ink = Color(0xFF12213A);
  static const inkSoft = Color(0xFF3A4A63);
  static const paper = Color(0xFFE7EBE6);
  static const card = Color(0xFFFBFCFA);
  static const rule = Color(0xFFC8D0C9);
  static const stamp = Color(0xFF0E6E6E); // "customs teal" — links, verification stamps

  // Header text sits on the ink background, not the paper — separate,
  // lighter tokens.
  static const headerText = Color(0xFFEAEFEA);
  static const headerNative = Color(0xFF9DB0AE);
  static const headerMrz = Color(0xFF7E938F);
  static const headerMrzStrong = Color(0xFFB9C9C4);
  static const pillInactiveText = Color(0xFFC6D3D0);

  // Advisory levels 1–4, low to high risk.
  static const advisoryLevel1 = Color(0xFF2E6B4F);
  static const advisoryLevel2 = Color(0xFF9A6714);
  static const advisoryLevel3 = Color(0xFFB4551D);
  static const advisoryLevel4 = Color(0xFF96262B);

  static Color advisoryColor(int level) => switch (level) {
        1 => advisoryLevel1,
        2 => advisoryLevel2,
        3 => advisoryLevel3,
        _ => advisoryLevel4,
      };

  // --- Text styles -----------------------------------------------------

  static const _archivo = 'Archivo';
  static const _publicSans = 'Public Sans';
  static const _mono = 'IBM Plex Mono';

  /// The big country name (.cname) — 31px mobile / 42px desktop in the
  /// mockup; callers pass the size for their breakpoint.
  static TextStyle countryName(double fontSize) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w800,
        fontSize: fontSize,
        height: 1.02,
        letterSpacing: fontSize * -0.028,
        color: headerText,
      );

  /// Native name + romanization (.native / .native em).
  static const nativeName = TextStyle(
    fontFamily: _publicSans,
    fontSize: 12.5,
    color: headerNative,
  );
  static const nativeNameRomanized = TextStyle(
    fontFamily: _publicSans,
    fontStyle: FontStyle.italic,
    fontSize: 11.5,
    color: headerNative, // opacity handled by caller (Colors.withValues)
  );

  /// Section labels (.shead) — small caps-style mono labels used
  /// throughout the page, not just the header.
  static const sectionLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: inkSoft,
  );

  /// The "Right now" live strip (.live .k/.v/.s) — a small mono label, a
  /// big bold value, and a muted subtitle, stacked per column.
  static const liveLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 9.5,
    letterSpacing: 1.14,
    color: inkSoft,
  );
  static const liveValue = TextStyle(
    fontFamily: _archivo,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: -0.34,
    color: ink,
  );
  static const liveSubtitle = TextStyle(
    fontFamily: _publicSans,
    fontSize: 11,
    color: inkSoft,
  );

  /// MRZ strip (.mrz) — monospace, muted; `strong` variant for the
  /// bracketed data tokens (.mrz b).
  static const mrz = TextStyle(
    fontFamily: _mono,
    fontSize: 10.5,
    letterSpacing: 0.63,
    color: headerMrz,
  );
  static const mrzStrong = TextStyle(
    fontFamily: _mono,
    fontSize: 10.5,
    letterSpacing: 0.63,
    fontWeight: FontWeight.w500,
    color: headerMrzStrong,
  );

  /// Tab pill label text.
  static const pillLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 11.5,
    height: 1,
  );
}
