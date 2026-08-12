import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A bordered panel shaped like a physical ticket stub — rounded corners
/// plus a semicircular "notch" bitten out of the left and right edges at
/// vertical center, where a real ticket would be perforated for tearing.
/// Added 2026-08-11 (per Colleen: plain rounded-rect cards with a border
/// and no shadow read as generic/AI-default UI, not an actual ticket) —
/// replaces [DividedCard]/[RightNowStrip]'s plain `Container` decoration.
///
/// Two layers, not one `BoxDecoration` — `Container`'s border always
/// follows the box's own rect/rrect, never an arbitrary clip path, so the
/// notched outline needs its own stroke. [_TicketEdgePainter] traces the
/// exact same [Path] the [ClipPath] uses to clip the fill, so the two
/// stay pixel-consistent by construction, not by two numbers kept in
/// sync by hand.
///
/// Deliberately **not** applied to [CountryHeader] — its shape (rounded
/// bottom, full-bleed MRZ panel) is already distinct, and a notch at
/// vertical center would land somewhere in the middle of the flag/name
/// row rather than a clean edge.
class TicketPanel extends StatelessWidget {
  final Widget child;

  const TicketPanel({super.key, required this.child});

  static const _cornerRadius = CountryTheme.cardRadius;
  static const _notchRadius = 7.0;

  @override
  Widget build(BuildContext context) {
    const clipper = _TicketEdgeClipper(cornerRadius: _cornerRadius, notchRadius: _notchRadius);
    return Stack(
      children: [
        ClipPath(
          clipper: clipper,
          child: ColoredBox(color: CountryTheme.card, child: child),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _TicketEdgePainter(clipper: clipper, color: CountryTheme.rule),
          ),
        ),
      ],
    );
  }
}

class _TicketEdgeClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;

  const _TicketEdgeClipper({required this.cornerRadius, required this.notchRadius});

  Path path(Size size) {
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cornerRadius)));
    final midY = size.height / 2;
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, midY), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(size.width, midY), radius: notchRadius));
    return Path.combine(PathOperation.difference, base, notches);
  }

  @override
  Path getClip(Size size) => path(size);

  @override
  bool shouldReclip(covariant _TicketEdgeClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius || oldClipper.notchRadius != notchRadius;
}

class _TicketEdgePainter extends CustomPainter {
  final _TicketEdgeClipper clipper;
  final Color color;

  const _TicketEdgePainter({required this.clipper, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(clipper.path(size), paint);
  }

  @override
  bool shouldRepaint(covariant _TicketEdgePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.clipper.cornerRadius != clipper.cornerRadius ||
      oldDelegate.clipper.notchRadius != clipper.notchRadius;
}
