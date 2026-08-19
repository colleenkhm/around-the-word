import 'package:flutter/material.dart';

import '../../models/travel_info.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_date.dart';
import 'external_link.dart';

/// The "Travel Advisory" [AccordionSection]'s expanded content — matches
/// `trip-dashboard-v5.html`'s `.sec-advisory` card, including the
/// top-right "Emergency / 112" stamp. See [VisaSection]'s class doc for
/// why this is now a standalone section rather than sharing a card (and a
/// source line) with visa/entry.
class TravelAdvisorySection extends StatelessWidget {
  final List<TravelAdvisory> advisories;

  /// From `CountryFacts.emergencyNumber` — top-right stamp, omitted when
  /// unknown.
  final String? emergencyNumber;

  /// This section's dark accent — 2026-08-18, colors the "Full advisory"
  /// link instead of the fixed `AccordionTheme.skyDark` (a leftover from
  /// before the Visa/Advisory split — this section's own link had no
  /// reason to be sky-blue in the first place). See [SectionPalette]'s
  /// class doc.
  final Color accent;

  const TravelAdvisorySection({
    super.key,
    required this.advisories,
    required this.accent,
    this.emergencyNumber,
  });

  /// Pulls the leading digit out of a level string like "Level 2" so it
  /// can be matched against [AccordionTheme.advisoryColor]. Not every
  /// government publishes a numbered level — the colored heading is
  /// simply omitted (falls back to plain ink) rather than guessed at.
  int? _levelNumber(TravelAdvisory a) {
    final match = RegExp(r'(\d+)').firstMatch(a.level ?? '');
    return match == null ? null : int.parse(match.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          // Right padding widens to make room for the emergency stamp
          // (`Positioned` at the same top-right corner) — per Colleen,
          // 2026-08-19: it was bleeding into the first advisory's level
          // text, which otherwise has no reason to know the stamp exists
          // and just uses the full row width up to the base 20px.
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            emergencyNumber != null ? 88 : 20,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < advisories.length; i++) ...[
                if (i != 0) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: AccordionTheme.rule),
                  const SizedBox(height: 14),
                ],
                _AdvisoryRow(
                  advisory: advisories[i],
                  level: _levelNumber(advisories[i]),
                  accent: accent,
                ),
              ],
            ],
          ),
        ),
        if (emergencyNumber != null)
          Positioned(
            top: 16,
            right: 20,
            child: _EmergencyStamp(number: emergencyNumber!),
          ),
      ],
    );
  }
}

class _AdvisoryRow extends StatelessWidget {
  final TravelAdvisory advisory;
  final int? level;
  final Color accent;

  const _AdvisoryRow({
    required this.advisory,
    required this.level,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = level == null ? null : AccordionTheme.advisoryColor(level!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(advisory.issuingAuthority, style: AccordionTheme.sLabel),
        if (advisory.level != null || advisory.levelLabel != null) ...[
          const SizedBox(height: 5),
          Text(
            [advisory.level, advisory.levelLabel].nonNulls.join(' — '),
            style: AccordionTheme.sHead.copyWith(
              color: color ?? AccordionTheme.ink,
            ),
          ),
        ],
        if (advisory.summary != null) ...[
          const SizedBox(height: 6),
          Text(advisory.summary!, style: AccordionTheme.sBody),
        ],
        const SizedBox(height: 10),
        // Dates on one line, "Full advisory" right-aligned on its own
        // line below — same pattern [VisaSection]'s footer uses for
        // "Source" now, per Colleen, 2026-08-19, for consistency between
        // the two sections' source/citation rows.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            if (advisory.issuedAt != null)
              Text(
                'Issued ${formatShortDate(advisory.issuedAt!)}',
                style: AccordionTheme.srcRow,
              ),
            Text(
              'Checked ${formatShortDate(advisory.lastVerifiedAt)}',
              style: AccordionTheme.srcRow,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: ExternalLink(
            label: 'Full advisory',
            url: advisory.officialUrl,
            color: accent,
            fontFamily: AccordionTheme.dmMono,
          ),
        ),
      ],
    );
  }
}

/// `.emerg-stamp` — "EMERGENCY / 112".
class _EmergencyStamp extends StatelessWidget {
  final String number;

  const _EmergencyStamp({required this.number});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EMERGENCY', style: AccordionTheme.sLabel.copyWith(fontSize: 8)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call, size: 11, color: AccordionTheme.danger),
            const SizedBox(width: 4),
            Text(
              number,
              style: const TextStyle(
                fontFamily: AccordionTheme.fraunces,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AccordionTheme.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
