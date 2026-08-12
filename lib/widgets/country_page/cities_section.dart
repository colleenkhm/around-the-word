import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/country_theme.dart';
import '../../utils/format_population.dart';
import 'divided_card.dart';
import 'section_heading.dart';

/// The Overview tab's Cities section — informational only in V1, not yet
/// linking to a dedicated city page (client design doc). The chevron on
/// each row is a visual affordance for that future page; tapping does
/// nothing right now (confirmed 2026-08-10), so rows are deliberately
/// plain `Row`s rather than wrapped in `InkWell`/`GestureDetector` — no
/// ripple feedback that would suggest a tap does something it doesn't.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Cities'),
        DividedCard(
          children: [
            for (var i = 0; i < sorted.length; i++)
              _CityRow(
                index: i + 1,
                city: sorted[i],
                isCapital: sorted[i].name == capital,
              ),
          ],
        ),
      ],
    );
  }
}

class _CityRow extends StatelessWidget {
  final int index;
  final City city;
  final bool isCapital;

  const _CityRow({
    required this.index,
    required this.city,
    required this.isCapital,
  });

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (isCapital) 'Capital',
      if (city.population != null) formatPopulation(city.population!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(index.toString().padLeft(2, '0'), style: CountryTheme.listRowIndex),
          ),
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
                      Text('★', style: TextStyle(color: CountryTheme.boardAmber, fontSize: 10)),
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
          Icon(Icons.chevron_right, size: 18, color: CountryTheme.inkSoft),
        ],
      ),
    );
  }
}
