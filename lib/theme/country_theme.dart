import 'package:flutter/material.dart';

/// Design tokens for the country page's older navy/gold theme. See
/// HANDOFF.md for history.
class CountryTheme {
  CountryTheme._();

  // --- Surfaces ---------------------------------------------------------

  /// Page canvas — warm cream/linen.
  static const paper = Color(0xFFF5EDD8);

  /// Default card fill. Prefer an alternate tone below when depth matters.
  static const card = Color(0xFFF5EDD8);

  /// Warm alternate card tone (Best Times).
  static const cardWarm = Color(0xFFEDE3C4);

  /// Visa/Entry's alternate card tone.
  static const cardCool = Color(0xFFF1E8CE);

  /// Travel Advisories' alternate card tone.
  static const cardMint = Color(0xFFF1E8CE);

  /// Generic alternate card tone (Cities, Language pair, Practical Notes).
  static const aged = Color(0xFFE8DDB8);

  /// Divider/border line, warm tan.
  static const rule = Color(0xFFCFC0A0);

  // --- Ink (text on a light card/paper surface) --------------------------

  /// Primary text — titles, values, city names.
  static const ink = Color(0xFF1C1A17);

  /// Body/paragraph copy on a light surface.
  static const inkBody = Color(0xFF3D3A35);

  /// Secondary/muted text on a light surface.
  static const inkSoft = Color(0xFF6B6048);

  // --- Ink (text on a dark navy surface) ----------------------------------

  static const onNavy = Color(0xFFFFFFFF);
  static const onNavySoft = Color(0xB3FFFFFF); // ~70% white
  static const onNavyMuted = Color(0x66FFFFFF); // ~40% white

  // --- Accents ------------------------------------------------------------

  /// Header/word-of-day/emphasis surface, also used as link/CTA color.
  static const navy = Color(0xFF1B3560);
  static const navyMid = Color(0xFF254876);

  /// Warm accent — city-row star, ticket top stripe.
  static const gold = Color(0xFFC4850A);

  /// Deep red — source-row attribution, emergency-number badge.
  static const stampRed = Color(0xFF9E3020);

  /// Warning-box accent, distinct from gold.
  static const amber = Color(0xFF8A6200);

  /// Word of Day card's accent (stripe + button).
  static const terracotta = Color(0xFFC1653D);

  /// Elevation shadow for flat (non-notched) cards.
  static const cardShadow = [
    BoxShadow(color: Color(0x1A1C1A17), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A1C1A17), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x121C1A17), blurRadius: 28, offset: Offset(0, 12)),
  ];

  /// Shared corner radius for card-style panels and the header.
  static const cardRadius = 8.0;

  // Advisory levels 1–4, low to high risk.
  static const advisoryLevel1 = Color(0xFF2A7A4B);
  static const advisoryLevel2 = Color(0xFFC4850A);
  static const advisoryLevel3 = Color(0xFFB85020);
  static const advisoryLevel4 = Color(0xFF8B2020);

  static Color advisoryColor(int level) => switch (level) {
        1 => advisoryLevel1,
        2 => advisoryLevel2,
        3 => advisoryLevel3,
        _ => advisoryLevel4,
      };

  /// A light pastel of [base]'s hue. Currently unused.
  static Color lightTint(Color base) {
    final hue = HSLColor.fromColor(base).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.42, 0.90).toColor();
  }

  // --- Text styles ---------------------------------------------------------

  static const _publicSans = 'Public Sans';
  static const _cormorant = 'Cormorant Garamond';
  static const _libreBaskerville = 'Libre Baskerville';
  static const _courierPrime = 'Courier Prime';

  /// The big country name.
  static TextStyle countryName(double fontSize) => TextStyle(
        fontFamily: _libreBaskerville,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.1,
        letterSpacing: fontSize * -0.01,
        color: ink,
      );

  /// Ticket header's native name, on the navy block.
  static const ticketNativeName = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 11,
    letterSpacing: 0.4,
    color: onNavyMuted,
  );

  /// Ticket stub's field label ("LOCAL TIME", "$1 USD").
  static const ticketStubLabel = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: inkSoft,
  );

  /// Ticket stub's big value ("19:42", "€0.92").
  static const ticketStubValue = TextStyle(
    fontFamily: _cormorant,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: navy,
  );

  /// Ticket stub's small subtitle ("Aug 12 · UTC+3").
  static const ticketStubSub = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 12,
    color: inkSoft,
  );

  /// Ticket stub's "Convert →" link. Currently unused.
  static const ticketStubLink = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: navy,
  );

  /// Small caps-style mono labels — section headings, field labels.
  static const sectionLabel = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: inkSoft,
  );

  /// Shared list-row title — city names, advisory authority, etc.
  static const listRowTitle = TextStyle(
    fontFamily: _libreBaskerville,
    fontWeight: FontWeight.w700,
    fontSize: 14.5,
    color: ink,
  );

  /// Shared list-row meta — population counts, city sub-labels.
  static const listRowMeta = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 11.5,
    color: inkSoft,
  );

  /// Small mono index/footer text.
  static const listRowIndex = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    color: inkSoft,
  );

  /// Body copy — summaries, notes, reasons.
  static const listRowDetail = TextStyle(
    fontFamily: _publicSans,
    fontSize: 13.5,
    color: inkBody,
  );

  /// Tab pill label text.
  static const pillLabel = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 11.5,
    height: 1,
  );
}
