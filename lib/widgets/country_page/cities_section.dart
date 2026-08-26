import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_population.dart';

/// The "Cities" [AccordionSection]'s expanded content — a numbered list
/// of cities on the section's plain white background. No chevron/tap
/// affordance — there's no dedicated city page to link to yet.
class CitiesSection extends StatelessWidget {
  final List<City> cities;

  /// Matched against [City.name] to render the "Capital" meta label.
  final String? capital;

  /// A version of this section's flag color guaranteed to read on white —
  /// the only place that color shows up here, on the index numbers.
  /// Featured-city star stays fixed gold.
  final Color accent;

  const CitiesSection({
    super.key,
    required this.cities,
    required this.accent,
    this.capital,
  });

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();

    // Featured cities first.
    final sorted = [...cities]
      ..sort((a, b) => a.isFeatured == b.isFeatured ? 0 : (a.isFeatured ? -1 : 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sorted.length; i++)
          _CityRow(
            index: i + 1,
            city: sorted[i],
            isCapital: sorted[i].name == capital,
            isLast: i == sorted.length - 1,
            accent: accent,
          ),
      ],
    );
  }
}

class _CityRow extends StatelessWidget {
  final int index;
  final City city;
  final bool isCapital;
  final bool isLast;
  final Color accent;

  const _CityRow({
    required this.index,
    required this.city,
    required this.isCapital,
    required this.isLast,
    required this.accent,
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
          : const BoxDecoration(border: Border(bottom: BorderSide(color: AccordionTheme.rule))),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: AccordionTheme.rowMeta.copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    city.name,
                    style: AccordionTheme.rowTitle,
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
          if (metaParts.isNotEmpty)
            Text(metaParts.join(' · '), style: AccordionTheme.rowMeta),
        ],
      ),
    );
  }
}
