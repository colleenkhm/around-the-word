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

  /// This section's flag color — 2026-08-18, replaces the fixed
  /// `AccordionTheme.butter`. See [SectionPalette]'s class doc.
  final Color tint;

  /// Black or white, whichever reads on [tint] — see
  /// [SectionColors.textColor]. This section's body is a full-bleed
  /// [tint] fill, so every column's text needs this, not a fixed ink
  /// color.
  final Color textColor;

  const BestTimesSection({
    super.key,
    required this.bestTimes,
    required this.tint,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (bestTimes.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: tint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < bestTimes.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: i == bestTimes.length - 1
                    ? null
                    : BoxDecoration(
                        border: Border(right: BorderSide(color: textColor.withValues(alpha: 0.15))),
                      ),
                child: _BestTimeItem(bestTime: bestTimes[i], textColor: textColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _BestTimeItem extends StatelessWidget {
  final BestTime bestTime;
  final Color textColor;

  const _BestTimeItem({required this.bestTime, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(bestTime.months, style: AccordionTheme.sHead.copyWith(fontSize: 15, color: textColor)),
        const SizedBox(height: 3),
        Text(
          bestTime.whyShort,
          style: AccordionTheme.sBody.copyWith(fontSize: 12.5, color: textColor.withValues(alpha: 0.85)),
        ),
      ],
    );
  }
}
