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
  //
  // `ink` and `rule` were both softened 2026-08-11 (per Colleen: the
  // original mockup values read as "government website" / intimidating,
  // not just "official"). `ink` moved from a near-black navy toward the
  // existing `stamp` teal's hue family — still a serious document color,
  // but warmer and closer to the one accent already used for links, so
  // the header doesn't feel like a colder, unrelated block bolted onto
  // the rest of the page. `rule` is a lighter, lower-contrast version of
  // the same grey-green so card borders read as gentle definition rather
  // than ruled form lines. See also `cardRadius`/`cardShadow` below,
  // which round and soften the boxes those rules outline.
  static const ink = Color(0xFF1E3F52);
  static const inkSoft = Color(0xFF3A4A63);
  static const paper = Color(0xFFE7EBE6);
  static const card = Color(0xFFFBFCFA);
  static const rule = Color(0xFFDCE1DB);
  static const stamp = Color(0xFF0E6E6E); // "customs teal" — links, verification stamps

  /// Shared corner radius for card-style boxes (Right Now, Travel Info,
  /// Cities) and the header — bumped from the mockup's 10px 2026-08-11,
  /// alongside `cardShadow`, so boxes read as soft cards rather than
  /// sharp-edged form fields.
  static const cardRadius = 16.0;

  /// A soft, low-contrast shadow standing in for the mockup's hard
  /// `border`-only card style — added 2026-08-11 so cards read as sitting
  /// on the page rather than boxed into it. Kept as a getter (not a
  /// `const`) since `Color.withValues` isn't a const constructor call.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: ink.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

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

  /// A light pastel of [base]'s hue — used for the country page's
  /// background (added 2026-08-11, corrected same day: originally applied
  /// to the Travel Info boxes, but Colleen's actual ask was the *page*
  /// background between sections, not the card boxes — see
  /// `CountryHeaderPreviewScreen`'s `Scaffold.backgroundColor`. Card boxes
  /// stay plain white/[card], same as [DividedCard]'s original look,
  /// reading as documents sitting on a colored surface).
  ///
  /// **Takes only the hue from [base]; saturation and lightness are fixed**
  /// — two earlier versions (`withValues(alpha: 0.08)`, then `0.16`) both
  /// alpha-blended [base] toward white in *RGB* space via
  /// `Color.alphaBlend`, which was the real problem, not the percentage.
  /// Costa Rica's flag blue is close to fully saturated in HSL (S≈1.0) —
  /// blending a saturated dark color toward white in RGB crushes
  /// saturation fast (16% blend left under 10% saturation), so the result
  /// read as grey no matter how far the alpha was pushed up. Working in
  /// HSL and fixing saturation/lightness instead of diluting them fixes
  /// that at the root, and also means every country's accent tints
  /// consistently regardless of how saturated or dark its own flag color
  /// happens to be.
  static Color lightTint(Color base) {
    final hue = HSLColor.fromColor(base).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.42, 0.90).toColor();
  }

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

  /// Shared list-row styling (.cn / .cmeta) — used by both the best-times
  /// list and the cities list, per the mockup reusing the same markup
  /// pattern for both.
  static const listRowTitle = TextStyle(
    fontFamily: _publicSans,
    fontWeight: FontWeight.w600,
    fontSize: 14.5,
    color: ink,
  );
  static const listRowMeta = TextStyle(
    fontFamily: _publicSans,
    fontSize: 11.5,
    color: inkSoft,
  );
  // (.idx) — light-background mono index, distinct from the header's
  // .mrz styles even though both are "small muted mono" — those are
  // colored for the dark header background and would be too faint here.
  static const listRowIndex = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    color: inkSoft,
  );
  static const listRowDetail = TextStyle(
    fontFamily: _publicSans,
    fontSize: 13.5,
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
