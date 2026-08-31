import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_date.dart';

/// The "Holidays" [AccordionSection]'s expanded content — upcoming public
/// holidays, on the section's plain white background. Commodity, Tier A
/// (Nager.Date) — deliberately not [CountryGuide.festivals]'s hand-curated
/// named events; this is the "most businesses closed" fact instead. See
/// [PublicHoliday]'s class doc.
class HolidaysSection extends StatelessWidget {
  final List<PublicHoliday> holidays;

  /// A version of this section's flag color guaranteed to read on white —
  /// the only place that color shows up here, on the "Regional" tag.
  final Color accent;

  const HolidaysSection({super.key, required this.holidays, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (holidays.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final upcoming = holidays.where((h) => !h.date.isBefore(startOfToday)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Every date on record has already passed (data only spans the current
    // year plus the next) — show the full list rather than an empty body.
    final display = upcoming.isNotEmpty
        ? upcoming
        : ([...holidays]..sort((a, b) => a.date.compareTo(b.date)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < display.length; i++)
          _HolidayRow(
            holiday: display[i],
            isLast: i == display.length - 1,
            accent: accent,
          ),
      ],
    );
  }
}

class _HolidayRow extends StatelessWidget {
  final PublicHoliday holiday;
  final bool isLast;
  final Color accent;

  const _HolidayRow({required this.holiday, required this.isLast, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(border: Border(bottom: BorderSide(color: AccordionTheme.rule))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(holiday.name, style: AccordionTheme.rowTitle),
                if (holiday.localName != holiday.name) ...[
                  const SizedBox(height: 1),
                  Text(
                    holiday.localName,
                    style: AccordionTheme.rowMeta.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatShortDate(holiday.date), style: AccordionTheme.rowMeta),
              if (!holiday.isNational) ...[
                const SizedBox(height: 2),
                Text(
                  'Regional',
                  style: AccordionTheme.rowMeta.copyWith(color: accent, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
