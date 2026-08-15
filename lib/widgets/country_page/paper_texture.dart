import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A faint fleck texture painted behind [child] — kraft/recycled paper
/// stock, not a flat color fill. Added 2026-08-11 (per Colleen: a single
/// flat page color with slightly-lighter flat cards on top is the exact
/// "AI-default" look she was pointing at — texture is one thing a plain
/// CSS-variable color swap never has).
///
/// **Deterministic, not random-per-frame** — the flecks are generated
/// once from a fixed seed, not re-rolled on every repaint, so the
/// texture doesn't shimmer/jitter as the page scrolls or rebuilds.
/// Sized to whatever [child] occupies (typically the full screen, via
/// wrapping `Scaffold.body`), not the scrollable content's full height —
/// keeps the fleck count bounded regardless of how long the page gets.
class PaperTexture extends StatelessWidget {
  final Widget child;

  const PaperTexture({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _PaperTexturePainter(),
      child: child,
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7); // fixed seed — see class doc
    final fleckPaint = Paint()..color = CountryTheme.ink.withValues(alpha: 0.035);
    final fiberPaint = Paint()
      ..color = CountryTheme.ink.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    final fleckCount = (size.width * size.height / 700).round();
    for (var i = 0; i < fleckCount; i++) {
      final center = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      canvas.drawCircle(center, 0.4 + rng.nextDouble() * 0.8, fleckPaint);
    }

    // A handful of short, faintly visible fibers alongside the flecks —
    // real kraft paper has both, and fibers read as "paper" in a way
    // uniform dots alone don't.
    final fiberCount = (size.width * size.height / 9000).round();
    for (var i = 0; i < fiberCount; i++) {
      final start = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final angle = rng.nextDouble() * math.pi * 2;
      final length = 6 + rng.nextDouble() * 10;
      final end = start + Offset(math.cos(angle), math.sin(angle)) * length;
      canvas.drawLine(start, end, fiberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) => false;
}
