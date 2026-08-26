import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/accordion_theme.dart';
import '../../theme/section_palette.dart';

/// The "When to Visit" [AccordionSection]'s expanded content — a two-up
/// grid of month squares, each a different flag-derived color (cycling
/// through [SectionPalette.cycle]) and styled after the "Word of the day"
/// card: bold headline, parenthetical short reason, fuller prose below.
/// A [BestTime] naming several comma-separated months ("June, September")
/// becomes one square per month, each sharing that entry's reasoning —
/// never a bare month.
class BestTimesSection extends StatelessWidget {
  final List<BestTime> bestTimes;

  /// The per-country accent cycle each square draws its color from.
  final List<SectionColors> palette;

  const BestTimesSection({super.key, required this.bestTimes, required this.palette});

  @override
  Widget build(BuildContext context) {
    if (bestTimes.isEmpty) return const SizedBox.shrink();

    final squares = <_MonthSquare>[
      for (final bestTime in bestTimes)
        for (final month in bestTime.months.split(','))
          _MonthSquare(month: month.trim(), bestTime: bestTime),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (var row = 0; row * 2 < squares.length; row++) ...[
            if (row != 0) const SizedBox(height: 10),
            _MonthRow(
              first: squares[row * 2],
              firstColors: palette[(row * 2) % palette.length],
              second: row * 2 + 1 < squares.length ? squares[row * 2 + 1] : null,
              secondColors: palette[(row * 2 + 1) % palette.length],
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthSquare {
  final String month;
  final BestTime bestTime;

  const _MonthSquare({required this.month, required this.bestTime});
}

class _MonthRow extends StatelessWidget {
  final _MonthSquare first;
  final SectionColors firstColors;

  /// Null for a trailing odd square — its slot stays empty.
  final _MonthSquare? second;
  final SectionColors secondColors;

  const _MonthRow({
    required this.first,
    required this.firstColors,
    required this.second,
    required this.secondColors,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _MonthCard(square: first, colors: firstColors)),
          const SizedBox(width: 10),
          Expanded(
            child: second == null
                ? const SizedBox.shrink()
                : _MonthCard(square: second!, colors: secondColors),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final _MonthSquare square;
  final SectionColors colors;

  const _MonthCard({required this.square, required this.colors});

  @override
  Widget build(BuildContext context) {
    final textColor = colors.textColor;
    final bestTime = square.bestTime;
    return Container(
      color: colors.tint,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(square.month, style: AccordionTheme.sHead.copyWith(fontSize: 17, color: textColor)),
          const SizedBox(height: 3),
          Text(
            '(${bestTime.whyShort})',
            style: AccordionTheme.sBody.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bestTime.why,
            style: AccordionTheme.sBody.copyWith(fontSize: 12.5, color: textColor.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
