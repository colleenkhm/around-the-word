import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/country_theme.dart';
import '../../utils/flag_url.dart';
import 'dashed_divider.dart';
import 'split_flap_text.dart';

const _tabLabels = {
  CountryTab.overview: 'OVERVIEW',
  CountryTab.explore: 'EXPLORE',
  CountryTab.guide: 'GUIDE',
  CountryTab.language: 'LANGUAGE',
};

/// The country-page header/chrome: flag, name, native name, the
/// content_status pill, the tab-pill row, and the passport-style MRZ
/// strip. Built against country-page-mockups.html (2026-08-10 spec), with
/// several deliberate deviations from it since — most recently
/// (2026-08-11) the header container itself moved from a dark navy bar to
/// the same light [CountryTheme.card] surface every other card on the
/// page uses; only the MRZ strip at the bottom keeps a dark board panel.
/// See [CountryTheme]'s class doc for the full reasoning.
///
/// **Two separate pills, not one merged into the other** (corrected
/// 2026-08-10 — an earlier version of this widget replaced the
/// content_status text pill with the tab-pill row, reasoning that a
/// shorter row already signals partial content for free; turned out that
/// conflated two different things). The status pill is exactly what the
/// mockup shows — content *depth*. The tab-pill row is navigation, and is
/// deliberately **not** derived from [CountryBundle] content presence —
/// [tabs] is passed in by the caller and only grows as each tab actually
/// gets built (Explore, Guide, Language, one at a time), independent of
/// whether the data for it already exists.
///
/// **Two known data gaps, not yet fixed:**
/// - Native name + its romanization (the mockup's "Ελλάδα · Ellàda") isn't
///   in `country_facts`/[CountryFacts] at all yet — REST Countries returns
///   the native-script name (already noted as a bonus field in
///   `tools/commodity_importer`), but not a romanization, which would need
///   to be curated. Both are optional constructor params here rather than
///   pulled from the bundle, so this renders correctly once that's decided
///   without another widget change.
/// - The MRZ strip's `VISA:` segment needs a short status code
///   ("NONE"/"REQUIRED"/"SEE SOURCE") that doesn't exist on [VisaInfo] —
///   only a free-text `summary`. Omitted from the strip for now rather
///   than guessed from the summary text.
class CountryHeader extends StatelessWidget {
  final CountryBundle bundle;

  /// Which tabs to show as pills — driven by what's actually been built
  /// so far, not by [CountryBundle] content presence. See class doc.
  final List<CountryTab> tabs;
  final CountryTab activeTab;
  final ValueChanged<CountryTab> onTabSelected;
  final String? nativeName;
  final String? nativeNameRomanized;

  /// Fires when the MRZ strip's advisory/verification segment is tapped —
  /// null-safe no-op until the Advisory section exists on the page for it
  /// to scroll to.
  final VoidCallback? onAdvisorySegmentTap;

  const CountryHeader({
    super.key,
    required this.bundle,
    required this.tabs,
    required this.activeTab,
    required this.onTabSelected,
    this.nativeName,
    this.nativeNameRomanized,
    this.onAdvisorySegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      // A small rounded bottom edge — softened from a flat square bar
      // 2026-08-11 (read as an official banner). clipBehavior keeps the
      // MRZ strip's own dark panel and the flag's corners from poking
      // past the curve.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CountryTheme.card,
        border: Border.all(color: CountryTheme.rule),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(CountryTheme.cardRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // Bottom padding stops at the MRZ strip — that panel is
            // full-bleed (its own [CountryTheme.boardBg] block, not
            // padded content), so it's a sibling of this Padding rather
            // than a child inside it. See the class doc on why: it reads
            // as a physical board mounted in the header, not just more
            // header content.
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Flag(isoCode: bundle.country.isoCode, desktop: isDesktop),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SplitFlapText(
                            text: bundle.country.nameCommon,
                            fontSize: isDesktop ? 42 : 31,
                          ),
                          if (nativeName != null) ...[
                            const SizedBox(height: 7),
                            Text.rich(
                              TextSpan(
                                style: CountryTheme.nativeName,
                                children: [
                                  TextSpan(text: nativeName),
                                  if (nativeNameRomanized != null) ...[
                                    const TextSpan(text: '   '),
                                    TextSpan(
                                      text: nativeNameRomanized,
                                      style: CountryTheme.nativeNameRomanized
                                          .copyWith(
                                              color: CountryTheme.inkSoft
                                                  .withValues(alpha: 0.75)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // Both the status pill and the tab-pill row are about
                // signaling unevenness *across tabs* ("some sections are
                // further along than others" / a row of tabs to jump
                // between) — neither means anything with a single tab
                // built. Gated on tabs.length > 1 (2026-08-11) rather than
                // removed outright, so both come back on their own once
                // Explore/Guide/Language join the tabs list, with nothing
                // to remember to re-add.
                if (bundle.country.contentStatus == ContentStatus.partial &&
                    tabs.length > 1)
                  _StatusPill(countryName: bundle.country.nameCommon),
                if (tabs.length > 1) ...[
                  const SizedBox(height: 12),
                  _TabPillRow(
                    tabs: tabs,
                    active: activeTab,
                    onSelected: onTabSelected,
                  ),
                ],
              ],
            ),
          ),
          _MrzStrip(bundle: bundle, onAdvisoryTap: onAdvisorySegmentTap),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String isoCode;
  final bool desktop;

  const _Flag({required this.isoCode, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final width = desktop ? 62.0 : 46.0;
    final height = desktop ? 42.0 : 32.0;
    final placeholder = ColoredBox(color: CountryTheme.rule);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CountryTheme.rule),
      ),
      child: Image.network(
        flagPngUrl(isoCode),
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Flag fetch failed for $isoCode: $error');
          return placeholder;
        },
      ),
    );
  }
}

/// The content-depth signal (.pill in the mockup) — shown only when
/// `content_status = 'partial'`. `'complete'` gets no badge at all:
/// silence signals trust, per the client design doc's reasoning against
/// training users to read a "✓ Complete" label's *absence* as a warning.
class _StatusPill extends StatelessWidget {
  final String countryName;

  const _StatusPill({required this.countryName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: CountryTheme.paper,
        border: Border.all(color: CountryTheme.rule),
      ),
      child: Text(
        'Building out $countryName — some sections are further along than others',
        style: CountryTheme.pillLabel.copyWith(color: CountryTheme.inkSoft),
      ),
    );
  }
}

class _TabPillRow extends StatelessWidget {
  final List<CountryTab> tabs;
  final CountryTab active;
  final ValueChanged<CountryTab> onSelected;

  const _TabPillRow({
    required this.tabs,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tab in tabs)
            _TabPill(
              label: _tabLabels[tab]!,
              selected: tab == active,
              onTap: () => onSelected(tab),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // Selected fill is boardAmber — dark `ink` text on top rather than
      // a light color, since light text on a bright amber fill fails
      // contrast (checked: ~2.2:1); dark text on amber is the classic
      // high-contrast pairing real tickets and caution tags use.
      // Unselected uses `paper`/`rule` now, not a white-alpha overlay —
      // the header sits on a light `card` surface (2026-08-11), not a
      // dark one, so a white wash no longer reads as a subtle pill.
      color: selected ? CountryTheme.boardAmber : CountryTheme.paper,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : CountryTheme.rule,
            ),
          ),
          child: Text(
            label,
            style: CountryTheme.pillLabel.copyWith(
              color: selected ? CountryTheme.ink : CountryTheme.inkSoft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The passport-style "machine readable zone" strip — sits directly on
/// the header's light [CountryTheme.card] surface, set off from the
/// name/flag row above by a perforated [DashedDivider] rather than a
/// solid dark background (see [CountryTheme]'s class doc: an earlier
/// version was its own full-bleed dark panel, which read as a stray
/// leftover once the rest of the header went light). Segments are built
/// from whatever real data is available and cleanly derivable; see the
/// class doc on [CountryHeader] for the one segment (VISA) left out.
class _MrzStrip extends StatelessWidget {
  final CountryBundle bundle;
  final VoidCallback? onAdvisoryTap;

  const _MrzStrip({required this.bundle, required this.onAdvisoryTap});

  @override
  Widget build(BuildContext context) {
    final officialName = bundle.country.nameOfficial
        .toUpperCase()
        .replaceAll(' ', '<');
    final advisory = bundle.advisories.isEmpty ? null : bundle.advisories.first;
    final advisoryCode = advisory == null ? null : _shortLevel(advisory.level);

    final segments = <_MrzSegment>[
      _MrzSegment.plain('ATW<<'),
      _MrzSegment.strong('${bundle.country.isoCode}<<'),
      _MrzSegment.plain('$officialName<<'),
      if (advisoryCode != null)
        _MrzSegment.strong('ADV:$advisoryCode<<', onTap: onAdvisoryTap),
      if (bundle.visa != null)
        _MrzSegment.strong(
          'VERIFIED:${_isoDate(bundle.visa!.lastVerifiedAt)}<<',
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const DashedDivider(),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in segments)
                  GestureDetector(
                    onTap: s.onTap,
                    child: Text(
                      s.text,
                      style: s.strong ? CountryTheme.mrzStrong : CountryTheme.mrz,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// "Level 1" -> "L1". Best-effort — falls back to null (segment omitted)
  /// for advisory levels that don't follow that pattern, since `level` is
  /// free text set by whichever government issued it (data architecture
  /// doc), not a guaranteed enum.
  static String? _shortLevel(String? level) {
    if (level == null) return null;
    final match = RegExp(r'\d+').firstMatch(level);
    return match == null ? null : 'L${match.group(0)}';
  }
}

class _MrzSegment {
  final String text;
  final bool strong;
  final VoidCallback? onTap;

  _MrzSegment.plain(this.text)
      : strong = false,
        onTap = null;
  _MrzSegment.strong(this.text, {this.onTap}) : strong = true;
}
