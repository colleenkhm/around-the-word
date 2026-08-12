import 'package:flutter/material.dart';

/// Design tokens for the country page's visual language — a warm, light
/// **ticket** as the base, with the dark **arrivals-board** treatment kept
/// as an inset, not spread across the whole page.
///
/// **Re-based 2026-08-11, a third time** — per Colleen: "I don't think I
/// like how dark it is... maybe we should make it look more like a ticket
/// than an arrivals/departure board... or a combination of both but all
/// within one color theme." The previous pass made *everything* dark
/// (page, header, every card) to chase the board metaphor as hard as
/// possible; this walks that back to a light, warm "ticket stock" surface
/// for the page and every card, and keeps the near-black board panel only
/// where it was actually earned — the MRZ strip and [SplitFlapText]'s
/// name cells, the two pieces Colleen specifically said she liked ("the
/// part that looks like <<ATW<< and mimics travel/ticket stuff"). One
/// accent color (`ticketRust`, a dark saturated amber) carries the theme
/// on every light surface; the board panels keep their own brighter
/// `boardAmber` pair, since that's tuned for a dark background a light
/// accent color isn't.
///
/// Plain static consts rather than a ThemeExtension: this app's styling
/// has stayed deliberately simple so far (see HANDOFF.md on `provider` vs
/// `riverpod`), and a single reusable token class matches that without
/// extra ceremony. Revisit as a ThemeExtension if this ends up needing to
/// vary by context (e.g. a future dark mode) rather than being one fixed
/// palette.
class CountryTheme {
  CountryTheme._();

  // --- Ticket surfaces (light, warm) — the page and every card --------

  /// The page canvas — warm kraft/parchment, a shade deeper than [card]
  /// so cards read as sitting on top of it.
  static const paper = Color(0xFFF1E6CC);

  /// Every card/panel surface — Right Now, Travel Info, Cities, and the
  /// header container itself. Lighter "ticket stock" cream, distinct from
  /// [paper] but still warm and light — nothing on the page is a dark
  /// surface except the two board insets below.
  static const card = Color(0xFFFAF3E1);

  /// Divider/border line, warm tan — card borders, internal row dividers,
  /// [SectionHeading]'s dashed line.
  static const rule = Color(0xFFD9C9A0);

  /// Primary text on a ticket surface — titles, values, city names. A
  /// deep warm brown-black, not a cool grey or pure black, to match the
  /// warmth of the paper it sits on.
  static const ink = Color(0xFF2A2016);

  /// Secondary/muted text on a ticket surface — body copy, subtitles.
  static const inkSoft = Color(0xFF6E5D48);

  /// The one accent color for everything on a ticket surface — section
  /// labels, links, the featured-city star, big values. A dark, saturated
  /// amber/rust: legible against light card backgrounds, unlike
  /// [boardAmber] below, which is tuned bright specifically for a dark
  /// panel and would fail contrast here.
  static const ticketRust = Color(0xFF8E5A0B);

  /// Shared corner radius for card-style panels and the header.
  static const cardRadius = 8.0;

  // --- Board insets (dark) — MRZ strip + split-flap name cells only ---

  /// The board panel's own dark surface — deliberately **not** reused for
  /// anything else on the page anymore (an earlier pass unified this with
  /// `ink`/every card; that's what made the whole page read as one giant
  /// dark board instead of a ticket with one printed data-strip on it).
  static const boardBg = Color(0xFF17191B);

  /// The flap's physical center crease in [SplitFlapText]'s cells.
  static const boardSeam = Color(0x59000000);

  /// Bright board-panel text (MRZ's emphasized segments, flap-cell
  /// letters) — only ever sits on [boardBg], never on a ticket surface.
  static const boardAmber = Color(0xFFF2A93B);

  /// Dimmer board-panel text — MRZ's plain segments.
  static const boardAmberMuted = Color(0xFFA9793E);

  // Advisory levels 1–4, low to high risk — back to darker, light-card-
  // tuned values now that every card is light again.
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

  /// A light pastel of [base]'s hue — built for the country page
  /// background back when per-country tinting was tried. **Not currently
  /// used anywhere** — `CountryHeaderPreviewScreen`'s
  /// `_useAccentPageBackground` flag is off. Left in place per Colleen's
  /// "keep it in the code but don't want to use it at the moment" —
  /// still correct standalone HSL-tint logic if it comes back.
  static Color lightTint(Color base) {
    final hue = HSLColor.fromColor(base).hue;
    return HSLColor.fromAHSL(1.0, hue, 0.42, 0.90).toColor();
  }

  // --- Text styles -----------------------------------------------------

  static const _archivo = 'Archivo';
  static const _publicSans = 'Public Sans';
  static const _mono = 'IBM Plex Mono';

  /// The big country name (.cname) — unused now that [SplitFlapText]
  /// renders the header's name as individual flap cells instead of a
  /// single `Text`; kept rather than deleted in case a plain-text name
  /// rendering is wanted somewhere else later (a share card, a list row).
  static TextStyle countryName(double fontSize) => TextStyle(
        fontFamily: _archivo,
        fontWeight: FontWeight.w800,
        fontSize: fontSize,
        height: 1.02,
        letterSpacing: fontSize * -0.028,
        color: ink,
      );

  /// Native name + romanization (.native / .native em) — sits directly on
  /// the header's [card] surface now (the header stopped being a dark
  /// panel this pass), so this is [inkSoft], not a header-only token.
  static const nativeName = TextStyle(
    fontFamily: _publicSans,
    fontSize: 12.5,
    color: inkSoft,
  );
  static const nativeNameRomanized = TextStyle(
    fontFamily: _publicSans,
    fontStyle: FontStyle.italic,
    fontSize: 11.5,
    color: inkSoft,
  );

  /// Small caps-style mono labels used throughout the page — section
  /// headings, and anywhere else a "field label" tone is wanted.
  static const sectionLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: ticketRust,
  );

  /// The "Right now" live strip — a small mono label, a big bold value,
  /// and a muted subtitle, stacked per column. Back on a light [card]
  /// surface this pass, so `liveValue` is [ink] again, not [boardAmber].
  static const liveLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 9.5,
    letterSpacing: 1.14,
    color: ticketRust,
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

  /// Shared list-row styling — used by the cities list and Travel Info.
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

  /// Small mono index/footer text (city numbering, the "Verified ·
  /// Source" line) — [ticketRust], not neutral grey, so these small mono
  /// labels read as the same accent family as section headings and links.
  static const listRowIndex = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    color: ticketRust,
  );

  /// Body copy — advisory and visa summaries, prohibited-item notes.
  /// Deliberately neutral [inkSoft], not [ticketRust] — amber-colored
  /// paragraphs of real reading text would be tiring and gimmicky.
  static const listRowDetail = TextStyle(
    fontFamily: _publicSans,
    fontSize: 13.5,
    color: inkSoft,
  );

  /// MRZ strip — monospace, on the dark [boardBg] panel; `strong` variant
  /// for the bracketed data tokens. Unchanged by this pass — the MRZ
  /// strip is one of the two pieces that kept the dark board treatment.
  static const mrz = TextStyle(
    fontFamily: _mono,
    fontSize: 10.5,
    letterSpacing: 0.63,
    color: boardAmberMuted,
  );
  static const mrzStrong = TextStyle(
    fontFamily: _mono,
    fontSize: 10.5,
    letterSpacing: 0.63,
    fontWeight: FontWeight.w500,
    color: boardAmber,
  );

  /// Tab pill label text.
  static const pillLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 11.5,
    height: 1,
  );
}
