import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../models/travel_info.dart';

/// Travel Advisory card front: the level plus its label.
class AdvisoryLevelFacts extends StatelessWidget {
  final TravelAdvisory advisory;

  /// Text color — the card's on-tint color.
  final Color ink;

  const AdvisoryLevelFacts({
    super.key,
    required this.advisory,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final level = advisory.levelNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // White pill keeps the level's risk color legible on any flag tint.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AccordionTheme.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AccordionTheme.ink, width: 1),
          ),
          child: _BigValue(
            level == null ? (advisory.level ?? '—') : 'Level $level',
            color: level == null
                ? AccordionTheme.ink
                : AccordionTheme.advisoryColor(level),
            fontSize: 24,
          ),
        ),
        if (advisory.levelLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            advisory.levelLabel!,
            style: _subStyle(ink).copyWith(height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Travel Advisory card back: the start of the summary, plus "Read more".
class AdvisorySummaryBack extends StatelessWidget {
  final TravelAdvisory advisory;
  final Color accent;
  final VoidCallback onReadMore;

  const AdvisorySummaryBack({
    super.key,
    required this.advisory,
    required this.accent,
    required this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            advisory.summary ??
                'See the full advisory from the ${advisory.issuingAuthority}.',
            style: AccordionTheme.sBody.copyWith(fontSize: 13, height: 1.4),
            overflow: TextOverflow.fade,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onReadMore,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Read more',
                style: AccordionTheme.srcRow.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.open_in_full, size: 11, color: accent),
            ],
          ),
        ),
      ],
    );
  }
}

TextStyle _subStyle(Color ink) =>
    AccordionTheme.tfSub.copyWith(color: ink.withValues(alpha: 0.75));

class _BigValue extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _BigValue(
    this.text, {
    this.color = AccordionTheme.ink,
    this.fontSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    // Scales down rather than wrapping on a narrow card.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AccordionTheme.tfVal.copyWith(fontSize: fontSize, color: color),
      ),
    );
  }
}
