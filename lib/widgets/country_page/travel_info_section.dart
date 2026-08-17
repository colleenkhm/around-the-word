import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/travel_info.dart';
import '../../theme/country_theme.dart';
import '../../utils/format_date.dart';
import 'divided_card.dart';
import 'external_link.dart';
import 'section_heading.dart';

/// The Overview tab's Travel Info section: advisories (one per issuing
/// government) and visa/entry info. Lives in Overview, not a separate tab —
/// the client design doc still describes a standalone "Travel Info" tab,
/// but that was folded into Overview per the 2026-08-10 mockup spec (see
/// [CountryBundle]'s `CountryTab` doc comment); this section is the part of
/// that fold that hadn't been built yet.
///
/// **Side by side on desktop** (per Colleen, 2026-08-11): advisories on the
/// left, visa/entry on the right, at the same >=900 breakpoint
/// [CountryHeader] uses. Stacked (advisories above visa) below that.
/// Falls back to whichever half has data if only one does, rather than
/// leaving an empty column next to it. When both sit side by side, they're
/// forced to the same box height (the taller one's) via `IntrinsicHeight`
/// + stretch — otherwise a short advisories list next to a long visa
/// writeup looks like a layout bug rather than just "less content."
///
/// Every field here carries a required source link and verified date —
/// never rendered as the app's own assessment. See the data architecture
/// doc's "Legally sensitive" section and [TravelAdvisory]/[VisaInfo]'s doc
/// comments.
///
/// **One shared "Source" for advisories + visa, not two** (changed
/// 2026-08-11, per Colleen: for Costa Rica, the advisory and the entry/exit
/// summary are both actually published on the same US State Department
/// page — showing "Verified · Source" once per card repeated an
/// attribution that was never really two different sources to begin with.
/// `_shareSource` covers that case (advisories present *and* visa
/// present); each row's own footer is hidden and one connecting
/// `_SharedSourceFooter` runs below both cards instead, citing the
/// advisory's `officialUrl`/`lastVerifiedAt` as the shared citation. Visa
/// keeps its own separate "Apply" link (`VisaInfo.applicationUrl` — the
/// embassy site, not State Dept) since that's a genuinely different
/// resource, not a citation. **This assumes the one State Dept advisory is
/// the shared source** — correct for the current US-only advisory filter
/// (see `CountryHeaderPreviewScreen._usAdvisories`), but would need
/// revisiting (which advisory, if several, actually matches the visa's
/// source?) if a second government's advisory shows up later. Falls back
/// to each card citing its own source independently — the pre-2026-08-11
/// behavior — whenever only one of advisories/visa is present, since
/// there's nothing to share in that case.
///
/// **2026-08-15 restyle**, built against `trip-dashboard-v3.html`:
/// - Each advisory row gets a colored left accent bar
///   ([CountryTheme.advisoryColor]) and its level renders as one bold
///   heading line ("Level 1 — Exercise Normal Precautions") instead of a
///   separate pill badge. The mockup puts this bar on the whole card
///   (single-advisory comp); it's per-*row* here since this list can hold
///   more than one government's advisory at once.
/// - [emergencyNumber] (new — [CountryFacts.emergencyNumber], hand-curated,
///   see its doc comment) renders as a badge next to the "Advisories"
///   heading when known.
/// - [RegionalNote.summary] now renders as a highlighted warning box
///   ([CountryTheme.amber]) rather than a plain paragraph, and
///   [RegionalNote.groupSlug] renders as a rotated corner stamp — both map
///   onto data that already existed, no new fields. The visa's own
///   `summary` stays the single paragraph it always was; a separate bold
///   headline (the mockup's "No visa required") has no backing field
///   ([VisaInfo] only has one `summary` string) and isn't fabricated here
///   — flagged as an open idea in the data architecture doc instead.
class TravelInfoSection extends StatelessWidget {
  final List<TravelAdvisory> advisories;
  final VisaInfo? visa;
  final RegionalNote? regionalNote;

  /// From `CountryFacts.emergencyNumber` — badge next to the Advisories
  /// heading, omitted entirely when unknown.
  final String? emergencyNumber;

  const TravelInfoSection({
    super.key,
    required this.advisories,
    this.visa,
    this.regionalNote,
    this.emergencyNumber,
  });

  @override
  Widget build(BuildContext context) {
    final showAdvisories = advisories.isNotEmpty;
    final showVisa = visa != null;
    if (!showAdvisories && !showVisa) return const SizedBox.shrink();

    final shareSource = showAdvisories && showVisa;

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final sideBySide = showAdvisories && showVisa && isDesktop;

    final advisoriesColumn = showAdvisories
        ? _AdvisoriesColumn(
            advisories: advisories,
            matchHeight: sideBySide,
            hideOwnSource: shareSource,
            emergencyNumber: emergencyNumber,
          )
        : null;
    final visaColumn = showVisa
        ? _VisaColumn(
            visa: visa!,
            regionalNote: regionalNote,
            matchHeight: sideBySide,
            hideOwnSource: shareSource,
          )
        : null;

    final cards = sideBySide
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: advisoriesColumn!),
                const SizedBox(width: 16),
                Expanded(child: visaColumn!),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ?advisoriesColumn,
              if (advisoriesColumn != null && visaColumn != null)
                const SizedBox(height: 18),
              ?visaColumn,
            ],
          );

    if (!shareSource) return cards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cards,
        const SizedBox(height: 10),
        _SharedSourceFooter(
          officialUrl: advisories.first.officialUrl,
          lastVerifiedAt: advisories.first.lastVerifiedAt,
        ),
      ],
    );
  }
}

class _AdvisoriesColumn extends StatelessWidget {
  final List<TravelAdvisory> advisories;
  final bool matchHeight;
  final bool hideOwnSource;
  final String? emergencyNumber;

  const _AdvisoriesColumn({
    required this.advisories,
    this.matchHeight = false,
    this.hideOwnSource = false,
    this.emergencyNumber,
  });

  @override
  Widget build(BuildContext context) {
    // cardMint, per CountryTheme.cardMint's doc comment ("Travel Advisory
    // in the mockup") — wired up 2026-08-17, previously left on the
    // page-matching default (see Colleen's "looks very AI-esque" note).
    final card = DividedCard(
      color: CountryTheme.cardMint,
      children: [
        for (final advisory in advisories)
          _AdvisoryRow(advisory: advisory, hideSource: hideOwnSource),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          'Advisories',
          trailing: emergencyNumber == null ? null : _EmergencyBadge(number: emergencyNumber!),
        ),
        matchHeight ? Expanded(child: card) : card,
      ],
    );
  }
}

/// "EMERGENCY / 112"-style badge next to the Advisories heading — only
/// rendered when [CountryFacts.emergencyNumber] is known. See that field's
/// doc comment: hand-curated, no importer wired yet.
class _EmergencyBadge extends StatelessWidget {
  final String number;

  const _EmergencyBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EMERGENCY',
          style: CountryTheme.sectionLabel.copyWith(fontSize: 8, letterSpacing: 1.0),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call, size: 11, color: CountryTheme.stampRed),
            const SizedBox(width: 4),
            Text(
              number,
              style: const TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: CountryTheme.stampRed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdvisoryRow extends StatelessWidget {
  final TravelAdvisory advisory;

  /// True when [TravelInfoSection] is showing one connecting
  /// `_SharedSourceFooter` below both cards instead — see its doc comment.
  final bool hideSource;

  const _AdvisoryRow({required this.advisory, this.hideSource = false});

  /// Pulls the leading digit out of a level string like "Level 2" so it
  /// can be matched against [CountryTheme.advisoryColor]. Not every
  /// government publishes a numbered level (the UK FCDO entries in the
  /// mock data use a level-less summary label instead) — the accent bar
  /// and colored heading are simply omitted rather than guessed at when
  /// this comes back null.
  int? _levelNumber() {
    final match = RegExp(r'(\d+)').firstMatch(advisory.level ?? '');
    return match == null ? null : int.parse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    final level = _levelNumber();
    final color = level == null ? null : CountryTheme.advisoryColor(level);

    // A left-border decoration, not a `Row`+`stretch` sibling bar — this
    // row sits inside `DividedCard` -> `IntrinsicHeight` on desktop (see
    // `TravelInfoSection`'s side-by-side layout), and `stretch` needs a
    // bounded height there that intrinsic-height computation can't supply
    // (the exact failure mode `section_heading_test.dart` already guards
    // against for `LayoutBuilder` — same underlying conflict, different
    // widget). A border paints along its box's own edge regardless, so it
    // doesn't have that dependency.
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color ?? Colors.transparent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(advisory.issuingAuthority, style: CountryTheme.listRowIndex),
          if (advisory.level != null || advisory.levelLabel != null) ...[
            const SizedBox(height: 3),
            Text(
              [advisory.level, advisory.levelLabel].nonNulls.join(' — '),
              style: CountryTheme.listRowTitle.copyWith(color: color ?? CountryTheme.ink),
            ),
          ],
          if (advisory.summary != null) ...[
            const SizedBox(height: 6),
            Text(advisory.summary!, style: CountryTheme.listRowDetail),
          ],
          if (!hideSource) ...[
            const SizedBox(height: 8),
            _SourceFooter(
              officialUrl: advisory.officialUrl,
              lastVerifiedAt: advisory.lastVerifiedAt,
            ),
          ],
        ],
      ),
    );
  }
}

class _VisaColumn extends StatelessWidget {
  final VisaInfo visa;
  final RegionalNote? regionalNote;
  final bool matchHeight;

  /// True when [TravelInfoSection] is showing one connecting
  /// `_SharedSourceFooter` below both cards instead of this card citing
  /// its own `officialUrl`/`lastVerifiedAt` — see that class's doc
  /// comment. `applicationUrl` (the embassy site — where to actually
  /// apply, not a citation) still shows either way.
  final bool hideOwnSource;

  const _VisaColumn({
    required this.visa,
    this.regionalNote,
    this.matchHeight = false,
    this.hideOwnSource = false,
  });

  @override
  Widget build(BuildContext context) {
    // cardCool, per CountryTheme.cardCool's doc comment ("Visa/Entry in
    // the mockup") — wired up 2026-08-17, same pass as _AdvisoriesColumn's
    // cardMint above.
    final cardContent = DividedCard(
      color: CountryTheme.cardCool,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For ${visa.nationalityIsoCode} passport holders',
                style: CountryTheme.listRowTitle,
              ),
              const SizedBox(height: 6),
              Text(visa.summary, style: CountryTheme.listRowDetail),
              if (visa.prohibitedOnEntry != null || visa.prohibitedOnExit != null)
                Container(
                  margin: const EdgeInsets.only(top: 11),
                  padding: const EdgeInsets.only(top: 11),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: CountryTheme.rule)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visa.prohibitedOnEntry != null)
                        _ProhibitedNote(label: 'Prohibited on entry', body: visa.prohibitedOnEntry!),
                      if (visa.prohibitedOnEntry != null && visa.prohibitedOnExit != null)
                        const SizedBox(height: 8),
                      if (visa.prohibitedOnExit != null)
                        _ProhibitedNote(label: 'Prohibited on exit', body: visa.prohibitedOnExit!),
                    ],
                  ),
                ),
              if (hideOwnSource) ...[
                if (visa.applicationUrl != null) ...[
                  const SizedBox(height: 8),
                  ExternalLink(label: 'Apply', url: visa.applicationUrl!),
                ],
              ] else ...[
                const SizedBox(height: 8),
                _SourceFooter(
                  officialUrl: visa.officialUrl,
                  lastVerifiedAt: visa.lastVerifiedAt,
                  applicationUrl: visa.applicationUrl,
                ),
              ],
            ],
          ),
        ),
        if (regionalNote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RegionalNoteWarning(summary: regionalNote!.summary),
                const SizedBox(height: 8),
                _SourceFooter(
                  officialUrl: regionalNote!.officialUrl,
                  lastVerifiedAt: regionalNote!.lastVerifiedAt,
                ),
              ],
            ),
          ),
      ],
    );

    // The rotated group-membership stamp (e.g. "SCHENGEN") overlays the
    // card's bottom-right corner — only when there's a regionalNote to
    // name. A Stack rather than baking this into DividedCard itself, since
    // no other DividedCard user wants a corner overlay.
    final card = regionalNote == null
        ? cardContent
        : Stack(
            children: [
              cardContent,
              Positioned(
                bottom: 12,
                right: 12,
                child: _RegionalStamp(groupSlug: regionalNote!.groupSlug),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Visa & entry'),
        matchHeight ? Expanded(child: card) : card,
      ],
    );
  }
}

/// The visa card's "upcoming requirement" highlight box — maps onto
/// [RegionalNote.summary], which used to render as a plain paragraph.
/// [CountryTheme.amber], not [CountryTheme.gold] — see that token's doc
/// comment on why the mockup keeps them distinct.
class _RegionalNoteWarning extends StatelessWidget {
  final String summary;

  const _RegionalNoteWarning({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: CountryTheme.amber.withValues(alpha: 0.06),
        border: Border.all(color: CountryTheme.amber.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 12,
          color: CountryTheme.amber,
          height: 1.5,
        ),
      ),
    );
  }
}

/// The rotated corner stamp naming [RegionalNote.groupSlug] (e.g.
/// "schengen") — matches `.visa-stamp`.
class _RegionalStamp extends StatelessWidget {
  final String groupSlug;

  const _RegionalStamp({required this.groupSlug});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -5 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: CountryTheme.navy.withValues(alpha: 0.22), width: 1.5),
        ),
        child: Text(
          groupSlug.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Courier Prime',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: CountryTheme.navy.withValues(alpha: 0.32),
          ),
        ),
      ),
    );
  }
}

/// The connecting footer shown once, below both cards, when advisories and
/// visa share one real-world source (State Dept covers both for Costa
/// Rica) — see [TravelInfoSection]'s doc comment. Same visual language as
/// [_SourceFooter], just not tied to either card individually — centered
/// and given a bit more breathing room so it reads as belonging to both
/// boxes above it rather than as a stray extra line.
class _SharedSourceFooter extends StatelessWidget {
  final String officialUrl;
  final DateTime lastVerifiedAt;

  const _SharedSourceFooter({required this.officialUrl, required this.lastVerifiedAt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _SourceFooter(officialUrl: officialUrl, lastVerifiedAt: lastVerifiedAt),
    );
  }
}

class _ProhibitedNote extends StatelessWidget {
  final String label;
  final String body;

  const _ProhibitedNote({required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          // Red, not the shared muted default — matches `.vb-lbl`
          // (CountryTheme.advisoryLevel4 already equals the mockup's
          // `--red`, so this reuses it rather than adding a duplicate
          // token for the same color).
          style: CountryTheme.listRowIndex.copyWith(
            color: CountryTheme.advisoryLevel4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(body, style: CountryTheme.listRowDetail),
      ],
    );
  }
}

/// The "Verified `<date>` · Source (see latest) ↗" line shared by advisory
/// rows and the visa card — an optional second link for visa's
/// `applicationUrl`, which nothing else in [TravelAdvisory]/[RegionalNote]
/// has.
class _SourceFooter extends StatelessWidget {
  final String officialUrl;
  final DateTime lastVerifiedAt;
  final String? applicationUrl;

  const _SourceFooter({
    required this.officialUrl,
    required this.lastVerifiedAt,
    this.applicationUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          'Verified ${formatShortDate(lastVerifiedAt)}',
          style: CountryTheme.listRowIndex,
        ),
        ExternalLink(label: 'Source (see latest)', url: officialUrl),
        if (applicationUrl != null) ExternalLink(label: 'Apply', url: applicationUrl!),
      ],
    );
  }
}
