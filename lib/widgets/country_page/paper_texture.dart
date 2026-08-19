import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A faint fleck/fiber texture painted behind [child] — kraft/recycled
/// paper stock, not a flat color fill. Deterministic (fixed seed), sized
/// to [child].
class PaperTexture extends StatelessWidget {
  final Widget child;

  /// Defaults to [CountryTheme.ink]; pass [AccordionTheme.ink] from
  /// accordion-themed screens.
  final Color color;

  const PaperTexture({
    super.key,
    required this.child,
    this.color = CountryTheme.ink,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PaperTexturePainter(color), child: child);
  }
}

class _PaperTexturePainter extends CustomPainter {
  final Color inkColor;

  const _PaperTexturePainter(this.inkColor);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7); // fixed seed
    final fleckPaint = Paint()..color = inkColor.withValues(alpha: 0.035);
    final fiberPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    final fleckCount = (size.width * size.height / 700).round();
    for (var i = 0; i < fleckCount; i++) {
      final center = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      canvas.drawCircle(center, 0.4 + rng.nextDouble() * 0.8, fleckPaint);
    }

    // Short faint fibers alongside the flecks.
    final fiberCount = (size.width * size.height / 9000).round();
    for (var i = 0; i < fiberCount; i++) {
      final start = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      final angle = rng.nextDouble() * math.pi * 2;
      final length = 6 + rng.nextDouble() * 10;
      final end = start + Offset(math.cos(angle), math.sin(angle)) * length;
      canvas.drawLine(start, end, fiberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) =>
      oldDelegate.inkColor != inkColor;
}
