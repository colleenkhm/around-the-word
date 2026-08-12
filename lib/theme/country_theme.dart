import 'package:flutter/material.dart';

/// Design tokens for the country page's visual language — now a full
/// arrivals/departures board, not a light "document" page with a dark
/// board-styled header sitting on top of it.
///
/// **Re-based entirely 2026-08-11, replacing the mockup's light
/// navy-on-parchment scheme** — per Colleen: "I want the whole page to
/// look like an arrivals board. This theme looks clunky right now." The
/// clunkiness was real: a warm parchment page and white rounded cards
/// (complete with drop shadows, a soft-app-UI move) were sitting directly
/// underneath a stark black-panel amber header, two different visual
/// systems stacked on one page rather than one. This version goes all in
/// instead — one dark surface family (`paper` for the page canvas, `ink`
/// for every panel raised on it: header, MRZ strip, and now every card),
/// amber as the one accent for values/labels/links, flat panels with thin
/// rule-line borders instead of rounded shadowed cards. See each token's
/// comment for specifics; the country-page-mockups.html spec (2026-08-10)
/// is no longer the source of truth for color — the board direction
/// superseded it.
///
/// Plain static consts rather than a ThemeExtension: this app's styling
/// has stayed deliberately simple so far (see HANDOFF.md on `provider` vs
/// `riverpod`), and a single reusable token class matches that without
/// extra ceremony. Revisit as a ThemeExtension if this ends up needing to
/// vary by context (e.g. a future light mode) rather than being one fixed
/// palette.
class CountryTheme {
  CountryTheme._();

  // --- Surfaces ----------------------------------------------------------

  /// The page canvas — the darkest surface, everything else sits on top
  /// of it. Was a warm parchment `#EFE8D8` before this pass; the whole
  /// page is dark now, not just the header.
  static const paper = Color(0xFF0E1113);

  /// Every raised panel — header, MRZ strip, and now Right Now / Travel
  /// Info / Cities cards too — shares this one dark surface color rather
  /// than each having its own similar-but-different value. One step
  /// lighter than [paper] so panels read as raised without needing a
  /// drop shadow (see `cardRadius`'s doc comment on why shadows were
  /// dropped entirely).
  static const ink = Color(0xFF181D20);

  /// [ink] reused under its "board panel" name — the MRZ strip and the
  /// split-flap name cells were the first things to use this surface
  /// (2026-08-11), before cards moved onto it too. Kept as a separate
  /// name since call sites read more clearly as "the board panel" than
  /// "the ink," even though they're now the same value everywhere.
  static const boardBg = ink;

  /// A dim divider line, visible against both [paper] and [ink] without
  /// being loud — card borders, internal row dividers, and the ticket
  /// perforation dashes all use this one line color.
  static const rule = Color(0xFF3A362E);

  /// Corner radius for panels (header, Right Now, Travel Info, Cities) —
  /// small and consistent, not the earlier softening pass's 16px "app
  /// card" radius. A real board is a flush rectangular panel; some
  /// rounding keeps it from reading as a sharp government form again (see
  /// the "less intimidating" pass this superseded), but the panels should
  /// look like board panels, not floating UI cards.
  static const cardRadius = 8.0;

  // Card drop shadows (`cardShadow`, previously) were removed in this
  // pass, not just left unused — a shadow implies a light card floating
  // above a light page, which stopped being true the moment every panel
  // became a dark surface value-stepped off an equally dark page. Flat
  // panels + rule-line borders is the actual board look; keeping a
  // vestigial shadow getter around would just invite it creeping back in.

  // --- Text on light... there is no light surface anymore. Every text
  // color below assumes it's sitting on `ink` or `paper`. ---------------

  /// Primary text color on a dark panel — titles, city names, the big
  /// values. Was `headerText`, header-only, before this pass; promoted to
  /// the page's one "bright neutral" now that every panel is dark. Warm
  /// off-white rather than pure white, matching the amber accent's
  /// warmth rather than fighting it with a cold white.
  static const headerText = Color(0xFFF1ECE0);

  /// Secondary/muted text on a dark panel — body copy (advisory and visa
  /// summaries), subtitles, native-name text. Was a dark warm grey tuned
  /// for *light* card backgrounds (`#5B564E`) through the previous pass;
  /// that reads as near-invisible on today's dark panels, so this is a
  /// light warm grey instead — same role, inverted for the surface it
  /// actually sits on now.
  static const inkSoft = Color(0xFFB8AFA0);

  static const headerNative = Color(0xFFB3A99A);
  static const pillInactiveText = Color(0xFFD4CDBC);

  /// The flap's physical center crease in [SplitFlapText]'s cells.
  static const boardSeam = Color(0x59000000);

  /// The one accent color for the whole page — values, section labels,
  /// links, badges, the featured-city star. Bright: every surface it
  /// sits on is dark now, so there's no more need for a separate darker
  /// "ticketRust" variant tuned for light card backgrounds (removed this
  /// pass — it has no surface left to be legible against).
  static const boardAmber = Color(0xFFF2A93B);

  /// A dimmer version of [boardAmber] for de-emphasized text that's still
  /// part of the amber family — plain MRZ segments, small mono index
  /// numbers, the "Verified" footer text — vs. [boardAmber] itself for
  /// what should actually pop (big values, links, the selected tab).
  static const boardAmberMuted = Color(0xFFA9793E);

  // Advisory levels 1–4, low to high risk — brightened this pass (were
  // tuned for a light card background; too muddy against a dark panel at
  // the original values).
  static const advisoryLevel1 = Color(0xFF5FAE81);
  static const advisoryLevel2 = Color(0xFFD7A34A);
  static const advisoryLevel3 = Color(0xFFDD8355);
  static const advisoryLevel4 = Color(0xFFDD6363);

  static Color advisoryColor(int level) => switch (level) {
        1 => advisoryLevel1,
        2 => advisoryLevel2,
        3 => advisoryLevel3,
        _ => advisoryLevel4,
      };

  /// A light pastel of [base]'s hue — built for the country page
  /// background back when that background was light parchment. **Not
  /// currently used anywhere** — `CountryHeaderPreviewScreen`'s
  /// `_useAccentPageBackground` flag is off, and even if it were flipped
  /// on, a light pastel page would fight the all-dark board this theme is
  /// now built around. Left in place rather than deleted per Colleen's
  /// "keep it in the code but don't want to use it at the moment" — still
  /// correct standalone HSL-tint logic if a light surface ever comes back.
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
  /// throughout the page, not just the header. [boardAmberMuted] (a
  /// dimmer accent, not the full-bright [boardAmber]) — these appear on
  /// nearly every section, so keeping them a step down from the page's
  /// truly emphatic text (big values, links) preserves some hierarchy
  /// instead of every mono label on the page shouting at the same volume.
  static const sectionLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: boardAmberMuted,
  );

  /// The "Right now" live strip (.live .k/.v/.s) — a small mono label, a
  /// big bold value, and a muted subtitle, stacked per column. Already
  /// laid out like a flight-info board before any of the 2026-08-11
  /// theming — `liveValue` is full [boardAmber] now (was dark `ink` text,
  /// back when this strip sat on a white card) for the "glowing readout"
  /// look; `liveLabel` stays at [boardAmberMuted], matching
  /// [sectionLabel]'s label/value hierarchy.
  static const liveLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 9.5,
    letterSpacing: 1.14,
    color: boardAmberMuted,
  );
  static const liveValue = TextStyle(
    fontFamily: _archivo,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    letterSpacing: -0.34,
    color: boardAmber,
  );
  static const liveSubtitle = TextStyle(
    fontFamily: _publicSans,
    fontSize: 11,
    color: inkSoft,
  );

  /// Shared list-row styling (.cn / .cmeta) — used by both the best-times
  /// list and the cities list, per the mockup reusing the same markup
  /// pattern for both. `listRowTitle` is [headerText] now (was dark `ink`
  /// text for a white card) — city names, "For US passport holders", an
  /// advisory's issuing authority.
  static const listRowTitle = TextStyle(
    fontFamily: _publicSans,
    fontWeight: FontWeight.w600,
    fontSize: 14.5,
    color: headerText,
  );
  static const listRowMeta = TextStyle(
    fontFamily: _publicSans,
    fontSize: 11.5,
    color: inkSoft,
  );

  /// (.idx) — small mono index/footer text (city numbering, the
  /// "Verified … · Source" line). [boardAmberMuted] rather than a neutral
  /// grey (changed this pass) — these are the same small-mono-label shape
  /// as the MRZ strip's plain segments, so they read as part of the same
  /// board typography instead of a separate, unrelated muted-grey system.
  static const listRowIndex = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    color: boardAmberMuted,
  );

  /// Body copy — advisory and visa summaries, prohibited-item notes.
  /// Deliberately **not** part of the amber family like [listRowIndex] —
  /// amber-colored paragraphs of real reading text would be tiring and
  /// gimmicky; this stays a neutral, legible [inkSoft] the way actual
  /// board displays reserve amber for numbers/status and use white/grey
  /// for supplementary text.
  static const listRowDetail = TextStyle(
    fontFamily: _publicSans,
    fontSize: 13.5,
    color: inkSoft,
  );

  /// MRZ strip (.mrz) — monospace, on the [boardBg] panel; `strong`
  /// variant for the bracketed data tokens (.mrz b).
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
