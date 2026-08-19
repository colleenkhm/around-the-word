import 'package:flutter/material.dart';

import '../../models/country.dart';
import '../../theme/accordion_theme.dart';

/// The "Neighbors" [AccordionSection]'s expanded content — every country
/// this one shares a land border with, each row linking to that
/// country's own page.
class NeighborsSection extends StatelessWidget {
  final List<String> borderingCountryCodes;

  /// Full country list, used to resolve each code to a display name/[Country].
  /// An unresolved code still renders, as its raw ISO code.
  final List<Country> allCountries;

  /// This section's flag color.
  final Color tint;

  /// Black or white, whichever reads on [tint].
  final Color textColor;

  /// Called with the matched [Country] when a resolvable row is tapped.
  /// Navigation is the caller's job, not this widget's.
  final void Function(Country country) onTapNeighbor;

  const NeighborsSection({
    super.key,
    required this.borderingCountryCodes,
    required this.allCountries,
    required this.tint,
    required this.textColor,
    required this.onTapNeighbor,
  });

  @override
  Widget build(BuildContext context) {
    if (borderingCountryCodes.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: tint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < borderingCountryCodes.length; i++)
            _NeighborRow(
              code: borderingCountryCodes[i],
              country: _resolve(borderingCountryCodes[i]),
              isLast: i == borderingCountryCodes.length - 1,
              textColor: textColor,
              onTap: onTapNeighbor,
            ),
        ],
      ),
    );
  }

  Country? _resolve(String code) {
    for (final country in allCountries) {
      if (country.countryCode == code) return country;
    }
    return null;
  }
}

class _NeighborRow extends StatelessWidget {
  final String code;
  final Country? country;
  final bool isLast;
  final Color textColor;
  final void Function(Country country) onTap;

  const _NeighborRow({
    required this.code,
    required this.country,
    required this.isLast,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final country = this.country;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: textColor.withValues(alpha: 0.15)),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              country?.name ?? code,
              style: AccordionTheme.rowTitle.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (country != null)
            Icon(
              Icons.chevron_right,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
        ],
      ),
    );

    // Only a resolvable neighbor is tappable.
    if (country == null) return content;
    return InkWell(onTap: () => onTap(country), child: content);
  }
}
