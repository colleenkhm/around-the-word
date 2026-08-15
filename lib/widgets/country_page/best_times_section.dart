import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/country_theme.dart';
import 'section_heading.dart';

/// The Overview tab's "Best time to go" section. **Never renders a bare
/// month** — every [BestTime.months] is always paired with its
/// [BestTime.whyShort] right below it, per the client design doc: without
/// the reason, this section is indistinguishable from a weather average
/// anyone could look up. The `why_short`/`why` split exists specifically
/// so that reason is always there to show.
///
/// **2026-08-15**: replaced the single-column [DividedCard] list with a
/// [Wrap]-based multi-up layout inside one [CountryTheme.cardWarm] card,
/// matching `trip-dashboard-v3.html`'s `.bt-cols`. That mockup only shows
/// two entries in a fixed side-by-side pair — [Wrap] instead of a fixed
/// 2-column `Row`, so this still degrades cleanly for a [bestTimes] list
/// of any length (one entry, or five).
class BestTimesSection extends StatelessWidget {
  final List<BestTime> bestTimes;

  const BestTimesSection({super.key, required this.bestTimes});

  @override
  Widget build(BuildContext context) {
    if (bestTimes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Best time to go'),
        Container(
          decoration: const BoxDecoration(boxShadow: CountryTheme.cardShadow),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
            child: ColoredBox(
              color: CountryTheme.cardWarm,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Wrap(
                  spacing: 22,
                  runSpacing: 14,
                  children: [
                    for (final bestTime in bestTimes) _BestTimeItem(bestTime: bestTime),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BestTimeItem extends StatelessWidget {
  final BestTime bestTime;

  const _BestTimeItem({required this.bestTime});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(bestTime.months, style: CountryTheme.listRowTitle),
          const SizedBox(height: 3),
          Text(
            bestTime.whyShort,
            style: CountryTheme.listRowDetail.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
