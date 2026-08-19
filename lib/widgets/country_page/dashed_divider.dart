import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A thin horizontal dashed line — the perforated "tear line" motif.
/// `CustomPaint`, not `LayoutBuilder`, since some call sites need
/// intrinsic dimensions.
class DashedDivider extends StatelessWidget {
  final double height;

  /// Defaults to [CountryTheme.rule].
  final Color color;

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
