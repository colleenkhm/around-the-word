import 'package:flutter/material.dart';

import '../../models/country.dart';
import '../../theme/accordion_theme.dart';

/// The "Neighbors" [AccordionSection]'s expanded content — a list of every
/// country this one shares a land border with (`CountryFacts.borderingCountryCodes`),
/// each row linking to that country's own page. Added 2026-08-19 per
/// Colleen. Modeled on [CitiesSection]'s row style (numbered list,
/// full-bleed [tint] fill), minus the numbering/star, which are specific
/// to Cities' "featured city" concept and don't apply here.
///
/// **Resolves codes against the already-loaded country list, doesn't
/// fetch anything new** — [allCountries] is `TripSelection.countries`
/// (the same 219-country list `DestinationScreen`'s search already reads),
/// passed in rather than watched here so this stays a plain, data-in
/// widget like every other section — see [onTapNeighbor] for why
/// navigation itself is the caller's job, not this widget's.
class NeighborsSection extends StatelessWidget {
  final List<String> borderingCountryCodes;

  /// The full country list, used only to resolve each code in
  /// [borderingCountryCodes] to a display name (and, if [onTapNeighbor] is
  /// given, a [Country] to navigate to). A code with no match in this list
  /// still renders — as its raw ISO code, not tappable — rather than being
  /// silently dropped; that's a real gap worth seeing, not hiding.
  final List<Country> allCountries;

  /// This section's flag color — see [SectionPalette]'s class doc.
  final Color tint;

  /// Black or white, whichever reads on [tint] — see
  /// [SectionColors.textColor].
  final Color textColor;

  /// Called with the matched [Country] when a resolvable row is tapped.
  /// This widget doesn't navigate itself — same reasoning `SiteHeader`/
  /// `CountryHeader` take navigation as callbacks rather than importing a
  /// screen directly (see those classes' docs): keeps this a
  /// presentational widget, with `CountryHeaderPreviewScreen` (which
  /// already owns the `Navigator.push` to another country's page, from
  /// `DestinationScreen`'s pattern) as the one place that logic lives.
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
              // Falls back to the raw code — see class doc on why an
              // unresolved neighbor still shows up rather than vanishing.
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

    // Only a resolvable neighbor is tappable — no ripple/chevron
    // affordance suggesting a tap does something it can't (same rule
    // CitiesSection's own rows follow for their still-unbuilt city page).
    if (country == null) return content;
    return InkWell(onTap: () => onTap(country), child: content);
  }
}
