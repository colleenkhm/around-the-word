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

  const DashedDivider({super.key, this.height = 1.5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(painter: const _DashedLinePainter()),
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
