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
class TravelInfoSection extends StatelessWidget {
  final List<TravelAdvisory> advisories;
  final VisaInfo? visa;
  final RegionalNote? regionalNote;

  const TravelInfoSection({
    super.key,
    required this.advisories,
    this.visa,
    this.regionalNote,
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

  const _AdvisoriesColumn({
    required this.advisories,
    this.matchHeight = false,
    this.hideOwnSource = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = DividedCard(
      children: [
        for (final advisory in advisories)
          _AdvisoryRow(advisory: advisory, hideSource: hideOwnSource),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Advisories'),
        matchHeight ? Expanded(child: card) : card,
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
  /// mock data use a level-less summary label instead) — the badge is
  /// simply omitted rather than guessed at when this comes back null.
  int? _levelNumber() {
    final match = RegExp(r'(\d+)').firstMatch(advisory.level ?? '');
    return match == null ? null : int.parse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    final level = _levelNumber();

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(advisory.issuingAuthority, style: CountryTheme.listRowTitle),
              ),
              if (level != null) ...[
                const SizedBox(width: 8),
                _LevelBadge(level: level, label: advisory.level!),
              ],
            ],
          ),
          if (advisory.levelLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              advisory.levelLabel!,
              style: CountryTheme.listRowDetail.copyWith(fontWeight: FontWeight.w600),
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

class _LevelBadge extends StatelessWidget {
  final int level;
  final String label; // e.g. "Level 2" — shown verbatim, not reworded

  const _LevelBadge({required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = CountryTheme.advisoryColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: color,
        ),
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
    final card = DividedCard(
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
              if (visa.prohibitedOnEntry != null) ...[
                const SizedBox(height: 8),
                _ProhibitedNote(label: 'Prohibited on entry', body: visa.prohibitedOnEntry!),
              ],
              if (visa.prohibitedOnExit != null) ...[
                const SizedBox(height: 8),
                _ProhibitedNote(label: 'Prohibited on exit', body: visa.prohibitedOnExit!),
              ],
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
                Text(regionalNote!.summary, style: CountryTheme.listRowDetail),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Visa & entry'),
        matchHeight ? Expanded(child: card) : card,
      ],
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
        Text(label.toUpperCase(), style: CountryTheme.listRowIndex),
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
