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
///
/// **2026-08-18: reintroduced on the accordion country page**, one of a
/// few concrete answers to Colleen's "what else could help this look less
/// AI/like anyone could make it" — this widget already existed for
/// exactly that reason and just wasn't wired up anywhere yet (nothing
/// referenced it). Added an optional [color] so the country page can pass
/// [AccordionTheme.ink] instead of this file's original [CountryTheme.ink]
/// default — kept as a param rather than a second hardcoded reference so
/// the two themes don't quietly drift if either `ink` tone changes later.
/// At this alpha (0.035/0.02) the exact hue barely reads regardless — it's
/// there for grain, not color — but matching the caller's own ink is
/// still the more correct default than an unrelated theme's.
class PaperTexture extends StatelessWidget {
  final Widget child;

  /// Defaults to [CountryTheme.ink] — this widget's original, only caller
  /// before 2026-08-18. Pass [AccordionTheme.ink] from accordion-themed
  /// screens.
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
    final rng = math.Random(7); // fixed seed — see class doc
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

    // A handful of short, faintly visible fibers alongside the flecks —
    // real kraft paper has both, and fibers read as "paper" in a way
    // uniform dots alone don't.
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
