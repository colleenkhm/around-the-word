import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A bordered panel shaped like a physical ticket stub — rounded corners
/// plus a semicircular notch bitten out of the left/right edges at
/// vertical center. Dashed outline, not solid.
class TicketPanel extends StatelessWidget {
  final Widget child;

  /// Fill color. Defaults to [CountryTheme.card]; override with an
  /// alternate tone for a panel that should read as sitting on the page.
  final Color color;

  const TicketPanel({super.key, required this.child, this.color = CountryTheme.card});

  static const _cornerRadius = CountryTheme.cardRadius;
  static const _notchRadius = 7.0;

  @override
  Widget build(BuildContext context) {
    const clipper = _TicketEdgeClipper(cornerRadius: _cornerRadius, notchRadius: _notchRadius);
    return Stack(
      children: [
        ClipPath(
          clipper: clipper,
          child: ColoredBox(color: color, child: child),
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

  static const _dashLength = 4.0;
  static const _gapLength = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Walk each contour, stroking in dash/gap segments via PathMetrics.
    for (final metric in clipper.path(size).computeMetrics()) {
      var distance = 0.0;
      var drawing = true;
      while (distance < metric.length) {
        final next = distance + (drawing ? _dashLength : _gapLength);
        if (drawing) {
          canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        }
        distance = next;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TicketEdgePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.clipper.cornerRadius != clipper.cornerRadius ||
      oldDelegate.clipper.notchRadius != clipper.notchRadius;
}
