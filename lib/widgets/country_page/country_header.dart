import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/country_theme.dart';
import '../../utils/flag_url.dart';

const _tabLabels = {
  CountryTab.overview: 'OVERVIEW',
  CountryTab.explore: 'EXPLORE',
  CountryTab.guide: 'GUIDE',
  CountryTab.language: 'LANGUAGE',
};

/// The country-page header/chrome: flag, name, native name, the
/// content_status pill, the tab-pill row, and the passport-style MRZ
/// strip. Built against country-page-mockups.html (2026-08-10 spec) —
/// **with one deliberate deviation from it**: the mockup's flat,
/// square-cornered dark bar was rounded at the bottom and given a soft
/// shadow 2026-08-11 (see the color/radius/shadow tokens' doc comments in
/// `CountryTheme`) because it read as an official banner rather than a
/// page header. The mockup is still the source of truth for everything
/// else here.
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
      // Rounded bottom edge + a soft shadow (added 2026-08-11, per
      // Colleen: the flat full-width dark bar read as an official banner
      // rather than a page header) — the header now reads as a card
      // sitting on top of the page rather than an institutional strip
      // it's bolted to. clipBehavior keeps the MRZ strip's own border and
      // the flag's corners from poking past the curve.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CountryTheme.ink,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: CountryTheme.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
                    Text(
                      bundle.country.nameCommon,
                      style: CountryTheme.countryName(isDesktop ? 42 : 31),
                    ),
                    if (nativeName != null) ...[
                      const SizedBox(height: 5),
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
                                        color: CountryTheme.headerNative
                                            .withValues(alpha: 0.62)),
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
          // Both the status pill and the tab-pill row are about signaling
          // unevenness *across tabs* ("some sections are further along
          // than others" / a row of tabs to jump between) — neither means
          // anything with a single tab built. Gated on tabs.length > 1
          // (2026-08-11) rather than removed outright, so both come back
          // on their own once Explore/Guide/Language join the tabs list,
          // with nothing to remember to re-add.
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
    final placeholder = ColoredBox(color: CountryTheme.inkSoft);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
        color: Colors.white.withValues(alpha: 0.11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Building out $countryName — some sections are further along than others',
        style: CountryTheme.pillLabel.copyWith(color: CountryTheme.pillInactiveText),
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
      color: selected ? CountryTheme.stamp : Colors.white.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: CountryTheme.pillLabel.copyWith(
              color: selected ? CountryTheme.headerText : CountryTheme.pillInactiveText,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The passport-style "machine readable zone" strip. Segments are built
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
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in segments)
              GestureDetector(
                onTap: s.onTap,
                child: Text(s.text, style: s.strong ? CountryTheme.mrzStrong : CountryTheme.mrz),
              ),
          ],
        ),
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
