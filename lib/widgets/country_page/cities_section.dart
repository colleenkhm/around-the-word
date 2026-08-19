import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_population.dart';

/// The "Cities" [AccordionSection]'s expanded content — matches
/// `trip-dashboard-v5.html`'s `.sec-cities` card-group (a lavender-tinted
/// list of numbered rows). Content-only, no card chrome: the count
/// ("4 destinations") lives in the accordion row's own meta line now, not
/// a repeated header bar inside this card — see
/// `CountryHeaderPreviewScreen`'s `_citiesMeta`.
///
/// **2026-08-18**: dropped the navy `CITIES · N destinations` header bar
/// the 2026-08-15 restyle added — redundant now that
/// [AccordionSection]'s own row already shows the section name and that
/// count while collapsed.
///
/// The chevron on each row is a visual affordance for a future dedicated
/// city page (client design doc); tapping does nothing right now
/// (confirmed 2026-08-10), so rows are deliberately plain, not wrapped in
/// an `InkWell` — no ripple feedback that would suggest a tap does
/// something it doesn't.
class CitiesSection extends StatelessWidget {
  final List<City> cities;

  /// From `CountryFacts.capital` — matched against [City.name] to render
  /// the "Capital" meta label. The client `City` model has no `isCapital`
  /// flag of its own; this is the only signal available to derive it.
  final String? capital;

  /// This section's flag color — 2026-08-18, replaces the fixed
  /// `AccordionTheme.lavender`. See [SectionPalette]'s class doc. The
  /// featured-city star stays a fixed gold (`AccordionTheme.butterDark`)
  /// regardless — a "gold star" is its own recognizable motif, not this
  /// section's color family (see design-preferences.md).
  final Color tint;

  /// Black or white, whichever reads on [tint] — see
  /// [SectionColors.textColor]. This section's body is a full-bleed
  /// [tint] fill, so every row's text needs this, not a fixed ink color.
  final Color textColor;

  const CitiesSection({
    super.key,
    required this.cities,
    required this.tint,
    required this.textColor,
    this.capital,
  });

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();

    // Featured first — the star already carries this signal too, but the
    // ordering itself is part of it (client design doc: "featured/major
    // cities", featured named first).
    final sorted = [...cities]
      ..sort((a, b) => a.isFeatured == b.isFeatured ? 0 : (a.isFeatured ? -1 : 1));

    return ColoredBox(
      color: tint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < sorted.length; i++)
            _CityRow(
              index: i + 1,
              city: sorted[i],
              isCapital: sorted[i].name == capital,
              isLast: i == sorted.length - 1,
              textColor: textColor,
            ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  final int index;
  final City city;
  final bool isCapital;
  final bool isLast;
  final Color textColor;

  const _CityRow({
    required this.index,
    required this.city,
    required this.isCapital,
    required this.isLast,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (isCapital) 'Capital',
      if (city.population != null) formatPopulation(city.population!),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.15))),
            ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AccordionTheme.rowMeta.copyWith(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    city.name,
                    style: AccordionTheme.rowTitle.copyWith(color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (city.isFeatured) ...[
                  const SizedBox(width: 5),
                  const Text('★', style: TextStyle(color: AccordionTheme.butterDark, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (metaParts.isNotEmpty) ...[
            Text(
              metaParts.join(' · '),
              style: AccordionTheme.rowMeta.copyWith(color: textColor.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right, size: 16, color: textColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
