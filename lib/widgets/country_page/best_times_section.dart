import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/accordion_theme.dart';

/// The "When to Visit" [AccordionSection]'s expanded content — matches
/// `trip-dashboard-v5.html`'s `.sec-times` card (`.bt-cols`: a butter-
/// tinted row of month columns divided by vertical rules). Content-only,
/// no card chrome or heading — [AccordionSection] owns those now.
///
/// **Never renders a bare month** — every [BestTime.months] is always
/// paired with its [BestTime.whyShort] right below it, per the client
/// design doc: without the reason, this section is indistinguishable from
/// a weather average anyone could look up. The `why_short`/`why` split
/// exists specifically so that reason is always there to show.
class BestTimesSection extends StatelessWidget {
  final List<BestTime> bestTimes;

  const BestTimesSection({super.key, required this.bestTimes});

  @override
  Widget build(BuildContext context) {
    if (bestTimes.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: AccordionTheme.butter,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < bestTimes.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: i == bestTimes.length - 1
                    ? null
                    : const BoxDecoration(
                        border: Border(right: BorderSide(color: AccordionTheme.rule)),
                      ),
                child: _BestTimeItem(bestTime: bestTimes[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _BestTimeItem extends StatelessWidget {
  final BestTime bestTime;

  const _BestTimeItem({required this.bestTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(bestTime.months, style: AccordionTheme.sHead.copyWith(fontSize: 15)),
        const SizedBox(height: 3),
        Text(bestTime.whyShort, style: AccordionTheme.sBody.copyWith(fontSize: 12.5)),
      ],
    );
  }
}
