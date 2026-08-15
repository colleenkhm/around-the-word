import 'package:flutter/material.dart';

/// Design tokens for the country page's visual language.
///
/// **2026-08-15: navy/gold "boarding pass" palette**, replacing the light
/// "ticket stock" theme below — built against `trip-dashboard-v3.html`
/// (Colleen's mockup; confirmed via clarifying questions to be an Overview-
/// tab restyle, not the separate "trip dashboard" feature CLAUDE.md flags
/// as deferred). Most token *names* are unchanged so call sites don't all
/// need touching at once — this file repoints values/adds new tokens first;
/// each consuming widget's own structural restyle (header, cities, travel
/// info, ...) lands as its own follow-up pass. See HANDOFF.md for the full
/// list of what carried over vs. what didn't (split-flap name rendering and
/// the MRZ strip, notably, are being dropped rather than reskinned).
///
/// [card] and [paper] are now the **same** hex — the new mockup relies on
/// [cardShadow] (not a lighter/darker tone) to make cards read as sitting
/// above the page, the same way it does. Kept as two separate constants
/// anyway so call sites stay self-documenting ("this is the page" vs. "this
/// is a card surface") even though they currently match.
///
/// [CountryHeader] (split-flap name + MRZ strip removed, replaced by plain
/// text + a merged time/currency stub) is done as of this pass; Cities,
/// Travel Info, Best Times, and the new Language-pair/Practical-norms
/// sections are still on the light-theme-era visuals and land as their own
/// follow-up passes — see HANDOFF.md.
///
/// --- Prior history (kept, not re-litigated) ---
/// **Re-based twice in one day, 2026-08-11.** First: per Colleen, "I don't
/// think I like how dark it is... maybe we should make it look more like
/// a ticket than an arrivals/departure board" — walked a whole-page-dark
/// pass back to a light, warm "ticket stock" surface for the page and
/// every card, keeping a near-black board panel only on the MRZ strip and
/// the split-flap name cells. Second: per Colleen again, that MRZ strip's
/// solid dark bar itself then read as "one bar of black... it looks off"
/// once it was the only dark rectangle left on an otherwise light page —
/// so the MRZ strip's background came off too.
///
/// Plain static consts rather than a ThemeExtension: this app's styling
/// has stayed deliberately simple so far (see HANDOFF.md on `provider` vs
/// `riverpod`), and a single reusable token class matches that without
/// extra ceremony. Revisit as a ThemeExtension if this ends up needing to
/// vary by context (e.g. a future dark mode) rather than being one fixed
/// palette.
class CountryTheme {
  CountryTheme._();

  // --- Surfaces ---------------------------------------------------------

  /// The page canvas — warm cream/linen.
  static const paper = Color(0xFFF5EDD8);

  /// Every card/panel surface. Deliberately the same hex as [paper] now —
  /// see class doc — depth comes from [cardShadow], not a tone shift.
  static const card = Color(0xFFF5EDD8);

  /// Warm alternate card tone — used to visually distinguish specific
  /// sections (e.g. Best Times) from the default [card] surface, matching
  /// the mockup's `.card-warm` modifier.
  static const cardWarm = Color(0xFFEDE3C4);

  /// Cool alternate card tone (`.card-cool` — Visa/Entry in the mockup).
  static const cardCool = Color(0xFFE8EEE8);

  /// Mint alternate card tone (`.card-mint` — Travel Advisory in the
  /// mockup).
  static const cardMint = Color(0xFFE4EFE9);

  /// "Aged stock" tone from the mockup's `--aged` — not currently assigned
  /// to any specific section (the mockup itself defines it but doesn't use
  /// it anywhere either). Kept for whichever section wants a fourth
  /// alternate tone later, same reasoning as [lightTint] below.
  static const aged = Color(0xFFE8DDB8);

  /// Divider/border line, warm tan.
  static const rule = Color(0xFFCFC0A0);

  // --- Ink (text on a light [card]/[paper] surface) ----------------------

  /// Primary text — titles, values, city names.
  static const ink = Color(0xFF1C1A17);

  /// Body/paragraph copy on a light surface (advisory and visa summaries,
  /// prohibited-item notes, best-time reasons) — the mockup's `--ink-2`.
  /// Distinct from [inkSoft]: this is for real reading text, not
  /// labels/meta, which read as tiring in a muted tone at paragraph length.
  static const inkBody = Color(0xFF3D3A35);

  /// Secondary/muted text on a light surface — section labels, meta text
  /// (population, "Verified `<date>`"), subtitles. The mockup's `--ink-3`.
  static const inkSoft = Color(0xFF6B6048);

  // --- Ink (text on a dark [navy] surface) --------------------------------
  // For the header's navy block, the Word-of-the-day card, and the Cities
  // section's dark header bar — introduced this pass, not yet consumed
  // anywhere until those widgets' own restyle lands.

  static const onNavy = Color(0xFFFFFFFF);
  static const onNavySoft = Color(0xB3FFFFFF); // ~70% white
  static const onNavyMuted = Color(0x66FFFFFF); // ~40% white

  // --- Accents ------------------------------------------------------------

  /// The header/word-of-day/emphasis surface — also used as a link/CTA
  /// color on light surfaces (the mockup's `.tk-f-link`/`.src-row a` are
  /// both navy, not gold).
  static const navy = Color(0xFF1B3560);
  static const navyMid = Color(0xFF254876);

  /// The one *warm* accent — used sparingly (mockup: the city-row star,
  /// the ticket's top stripe, advisory level 2's bar, the gold CTA
  /// button) — not a blanket replacement for every accent role the old
  /// `ticketRust` covered. See [navy] for the link/CTA-text role instead.
  static const gold = Color(0xFFC4850A);

  /// Deep red used for the "who" attribution in a source row and the
  /// Travel Info section's emergency-number badge.
  static const stampRed = Color(0xFF9E3020);

  /// A second, distinct warm tone from [gold] — the mockup's `--amber`,
  /// used only for the visa "upcoming requirement" warning box. Not a
  /// duplicate of [gold]: the mockup keeps these visually separate
  /// (`.adv-bar-l2`/`.city-star`/`.btn-gold` are `--gold`; `.visa-warn` is
  /// `--amber`), so this file does too rather than collapsing them into
  /// one token for convenience.
  static const amber = Color(0xFF8A6200);

  /// Layered elevation shadow for the new flat (non-notched) cards — the
  /// Cities list card, the Languages/Word-of-day pair. [TicketPanel]'s own
  /// notched shape keeps its existing dedicated painter/shadow, this is
  /// for plain rounded-rect cards that want the same "resting on the page"
  /// depth the mockup's `--shadow-a/b/c` give every `.card`.
  static const cardShadow = [
    BoxShadow(color: Color(0x1A1C1A17), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A1C1A17), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x121C1A17), blurRadius: 28, offset: Offset(0, 12)),
  ];

  /// Shared corner radius for card-style panels and the header.
  static const cardRadius = 8.0;

  // Advisory levels 1–4, low to high risk — per trip-dashboard-v3.html's
  // `.adv-bar-l1`..`l4` (level 2 uses [gold], not a separate amber — that
  // was the old palette's choice, not this one's).
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

  // --- Text styles ---------------------------------------------------------

  static const _publicSans = 'Public Sans';
  static const _cormorant = 'Cormorant Garamond';
  static const _libreBaskerville = 'Libre Baskerville';
  static const _courierPrime = 'Courier Prime';

  /// The big country name. Was unused for a while (SplitFlapText rendered
  /// the header's name as individual flap cells instead) — back in use now
  /// that [CountryHeader] renders plain text again, per the mockup's
  /// `.tk-name`. Defaults to [ink]; the header overrides to [onNavy] via
  /// `.copyWith` since it sits on the navy block, not a light surface.
  static TextStyle countryName(double fontSize) => TextStyle(
        fontFamily: _libreBaskerville,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.1,
        letterSpacing: fontSize * -0.01,
        color: ink,
      );

  /// The ticket header's native name, on the navy block.
  static const ticketNativeName = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 11,
    letterSpacing: 0.4,
    color: onNavyMuted,
  );

  /// The ticket stub's field label ("LOCAL TIME", "$1 USD" — `.tk-f-label`).
  static const ticketStubLabel = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 8,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: inkSoft,
  );

  /// The ticket stub's big value ("19:42", "€0.92" — `.tk-f-val`).
  static const ticketStubValue = TextStyle(
    fontFamily: _cormorant,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: navy,
  );

  /// The ticket stub's small subtitle ("Aug 12 · UTC+3" — `.tk-f-sub`).
  static const ticketStubSub = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    color: inkSoft,
  );

  /// The ticket stub's "Convert →" link (`.tk-f-link`). Currently unused —
  /// [ExternalLink] (used for that CTA) has its own literal style rather
  /// than reading this token; kept in case a future call site wants the
  /// stub-specific sizing/weight instead of ExternalLink's shared look.
  static const ticketStubLink = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: navy,
  );

  /// Small caps-style mono labels — section headings, and anywhere else a
  /// "field label" tone is wanted. **Recolored this pass**: [inkSoft], not
  /// the old `ticketRust`/[gold] — the mockup's `.s-label` uses its muted
  /// `--ink-3` tone, not the warm accent (see [gold]'s doc comment on why
  /// that accent is reserved for specific elements, not every label).
  static const sectionLabel = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: inkSoft,
  );

  /// Shared list-row title — city names, advisory issuing authority, visa
  /// nationality line, best-time months. **Recolored this pass**: Libre
  /// Baskerville bold, not Public Sans — every one of these is a
  /// "heading/proper-noun" role the mockup consistently gives to Libre
  /// Baskerville (`.city-name`, `.s-head`, `.wotd-word`, `.tk-name`).
  static const listRowTitle = TextStyle(
    fontFamily: _libreBaskerville,
    fontWeight: FontWeight.w700,
    fontSize: 14.5,
    color: ink,
  );

  /// Shared list-row meta — population counts, city sub-labels.
  /// **Recolored this pass**: Courier Prime, matching `.city-meta`.
  static const listRowMeta = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 11.5,
    color: inkSoft,
  );

  /// Small mono index/footer text (city numbering, the "Verified `<date>`
  /// · Source" line). A shared muted-mono default — some call sites (the
  /// city star, a future emergency-stamp red) intentionally override the
  /// color per-instance rather than this token trying to cover every one
  /// of the mockup's more differentiated label colors (`--rule` for city
  /// numbers, `--ink-3` for "Verified", `--red` for a prohibited-item
  /// label) — same pattern the code already used before this pass.
  static const listRowIndex = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 10,
    color: inkSoft,
  );

  /// Body copy — advisory and visa summaries, prohibited-item notes,
  /// best-time reasons. **Recolored this pass**: [inkBody], not [inkSoft]
  /// — this is real paragraph text (the mockup's `--ink-2`), not a
  /// label/meta tone; [inkSoft] stays reserved for the muted/secondary
  /// role most other tokens above use it for.
  static const listRowDetail = TextStyle(
    fontFamily: _publicSans,
    fontSize: 13.5,
    color: inkBody,
  );

  /// Tab pill label text. **Recolored this pass** (font family only, to
  /// Courier Prime) — the mockup's single-tab comp doesn't show tab pills
  /// at all, so this is an extrapolation to keep the mono-label language
  /// consistent, not a direct match.
  static const pillLabel = TextStyle(
    fontFamily: _courierPrime,
    fontSize: 11.5,
    height: 1,
  );
}
