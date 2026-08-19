import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_population.dart';

/// The "Cities" [AccordionSection]'s expanded content — a numbered list
/// of cities. Chevron is a visual affordance for a future dedicated city
/// page; tapping does nothing yet, so rows aren't wrapped in `InkWell`.
class CitiesSection extends StatelessWidget {
  final List<City> cities;

  /// Matched against [City.name] to render the "Capital" meta label.
  final String? capital;

  /// This section's flag color. Featured-city star stays fixed gold.
  final Color tint;

  /// Black or white, whichever reads on [tint].
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

    // Featured cities first.
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
