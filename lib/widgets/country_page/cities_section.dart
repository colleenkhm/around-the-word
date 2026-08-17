import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/country_theme.dart';
import '../../utils/format_population.dart';

/// The Overview tab's Cities section — informational only in V1, not yet
/// linking to a dedicated city page (client design doc). The chevron on
/// each row is a visual affordance for that future page; tapping does
/// nothing right now (confirmed 2026-08-10, reconfirmed during the
/// 2026-08-15 restyle), so rows are deliberately plain `Row`s rather than
/// wrapped in `InkWell`/`GestureDetector` — no ripple feedback that would
/// suggest a tap does something it doesn't.
///
/// **2026-08-15**: replaced the shared [SectionHeading]/[DividedCard]
/// composition every other Overview section still uses with a
/// self-contained card — a navy "CITIES · N destinations" header bar
/// above the row list, matching `trip-dashboard-v3.html`'s
/// `.cities-card`/`.cities-hdr`. Cities is the only section the mockup
/// gives this dark-header treatment to; the rest keep the plain
/// [SectionHeading] label as their own restyles land.
class CitiesSection extends StatelessWidget {
  final List<City> cities;

  /// From `CountryFacts.capital` — matched against [City.name] to render
  /// the "Capital" meta label. The client `City` model has no `isCapital`
  /// flag of its own; this is the only signal available to derive it.
  final String? capital;

  const CitiesSection({super.key, required this.cities, this.capital});

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();

    // Featured first — the star already carries this signal too, but the
    // ordering itself is part of it (client design doc: "featured/major
    // cities", featured named first).
    final sorted = [...cities]
      ..sort((a, b) => a.isFeatured == b.isFeatured ? 0 : (a.isFeatured ? -1 : 1));

    // Outer Container carries the shadow undipped; the inner ClipRRect
    // does the actual corner/header clipping — combining both in one
    // BoxDecoration would clip the shadow away along with the corners.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(boxShadow: CountryTheme.cardShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CitiesHeader(count: sorted.length),
            // aged, not card — card is the exact same hex as the page
            // background (see its doc comment), which read as flat/
            // AI-esque with only the shadow above to separate this from
            // the page (2026-08-17, per Colleen).
            ColoredBox(
              color: CountryTheme.aged,
              child: Column(
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    _CityRow(
                      index: i + 1,
                      city: sorted[i],
                      isCapital: sorted[i].name == capital,
                      isLast: i == sorted.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitiesHeader extends StatelessWidget {
  final int count;

  const _CitiesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CountryTheme.navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CITIES',
            style: CountryTheme.sectionLabel.copyWith(
              color: CountryTheme.onNavySoft,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$count destination${count == 1 ? '' : 's'}',
            style: CountryTheme.listRowMeta.copyWith(
              color: CountryTheme.onNavyMuted,
              letterSpacing: 0.4,
            ),
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

  const _CityRow({
    required this.index,
    required this.city,
    required this.isCapital,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (isCapital) 'Capital',
      if (city.population != null) formatPopulation(city.population!),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: CountryTheme.ink.withValues(alpha: 0.07))),
            ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(index.toString().padLeft(2, '0'), style: CountryTheme.listRowIndex),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(city.name, style: CountryTheme.listRowTitle),
                    if (city.isFeatured) ...[
                      const SizedBox(width: 5),
                      Text('★', style: TextStyle(color: CountryTheme.gold, fontSize: 11)),
                    ],
                  ],
                ),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(metaParts.join(' · '), style: CountryTheme.listRowMeta),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: CountryTheme.rule),
        ],
      ),
    );
  }
}
