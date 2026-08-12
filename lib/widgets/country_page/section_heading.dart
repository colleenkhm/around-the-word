import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A section label with a trailing perforated "tear line" rule — shared by
/// every Overview-tab section ("Right now", "Advisories", "Cities", ...),
/// not just this one.
///
/// **Dashed, not solid** (changed 2026-08-11) — a separate
/// `TicketPerforation` divider used to run between whole sections *in
/// addition to* this heading's own solid trailing line, two different
/// divider styles doing the same job right next to each other. Now
/// consolidated into one: this heading's line is the perforated one,
/// `TicketPerforation` was removed rather than kept alongside it.
///
/// **Painted, not built with `LayoutBuilder`** — a first attempt at this
/// used `LayoutBuilder` to space the dashes across the available width,
/// and broke `TravelInfoSection`'s desktop layout: `_AdvisoriesColumn`/
/// `_VisaColumn` (which both contain a `SectionHeading`) sit inside an
/// `IntrinsicHeight` there (see [TravelInfoSection]'s doc comment on the
/// equal-box-height behavior), and `LayoutBuilder` explicitly does not
/// support being asked for intrinsic dimensions — it throws rather than
/// answering. `CustomPaint` has no such restriction (it just paints
/// within whatever size layout gives it), so the dash line is drawn with
/// a `CustomPainter` instead, using the actual final width at paint time
/// rather than needing to know it during build.
class SectionHeading extends StatelessWidget {
  final String label;

  const SectionHeading(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(label, style: CountryTheme.sectionLabel),
          const SizedBox(width: 9),
          const Expanded(
            child: SizedBox(
              height: 8,
              child: CustomPaint(painter: _DashedLinePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  static const _dashWidth = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CountryTheme.rule
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + _dashWidth, y), paint);
      x += _dashWidth + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
