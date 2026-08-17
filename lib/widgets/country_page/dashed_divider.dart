import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A thin horizontal dashed line — the perforated "tear line" motif used
/// across the page ([SectionHeading]'s trailing rule, the MRZ strip's top
/// edge). Extracted 2026-08-11 once a second call site needed the exact
/// same painter [SectionHeading] already had privately.
///
/// **Painted, not built with `LayoutBuilder`** — using `LayoutBuilder` to
/// space the dashes across the available width broke `SectionHeading`
/// once already: it sits inside `TravelInfoSection`'s `IntrinsicHeight`
/// on desktop, and `LayoutBuilder` explicitly does not support being
/// asked for intrinsic dimensions — it throws rather than answering.
/// `CustomPaint` has no such restriction; it just paints within whatever
/// size layout gives it at paint time.
class DashedDivider extends StatelessWidget {
  final double height;

  /// Defaults to [CountryTheme.rule] (the light-surface tan tone). Override
  /// for a call site on a dark surface — `_TicketStub` (2026-08-17) passes
  /// [CountryTheme.onNavyMuted] now that it sits on navy, not [card].
  final Color color;

  /// Line thickness. Defaults to 1.5, matching every existing call site;
  /// `_TicketStub` (2026-08-17, per Colleen: "thinner divider please")
  /// passes 1.0.
  final double strokeWidth;

  const DashedDivider({
    super.key,
    this.height = 1.5,
    this.color = CountryTheme.rule,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(painter: _DashedLinePainter(color: color, strokeWidth: strokeWidth)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _DashedLinePainter({required this.color, required this.strokeWidth});

  static const _dashWidth = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + _dashWidth, y), paint);
      x += _dashWidth + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
