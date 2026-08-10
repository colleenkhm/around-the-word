import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/country_theme.dart';
import 'divided_card.dart';
import 'section_heading.dart';

/// The Overview tab's "Best time to go" section. **Never renders a bare
/// month** — every [BestTime.months] is always paired with its
/// [BestTime.whyShort] in parentheses right next to it, per the client
/// design doc: without the reason, this section is indistinguishable from
/// a weather average anyone could look up. The `why_short`/`why` split
/// exists specifically so that reason is always there to show.
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
        DividedCard(
          children: [
            for (final bestTime in bestTimes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: bestTime.months, style: CountryTheme.listRowTitle),
                      TextSpan(
                        text: ' (${bestTime.whyShort})',
                        style: CountryTheme.listRowDetail,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
