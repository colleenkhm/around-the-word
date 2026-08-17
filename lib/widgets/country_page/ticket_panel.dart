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
/// **Dashed, not solid** (changed 2026-08-11, alongside the notches
/// themselves being pushed further per Colleen: the theme still read as
/// "half leaning in") — a solid 1px border around a rounded rect is the
/// one shape every plain card component defaults to; a perforated outline
/// reads as the same tear-line language as [DashedDivider] and the
/// notches, not a generic border.
///
/// Deliberately **not** applied to [CountryHeader] — its shape (rounded
/// bottom, full-bleed MRZ panel) is already distinct, and a notch at
/// vertical center would land somewhere in the middle of the flag/name
/// row rather than a clean edge.
class TicketPanel extends StatelessWidget {
  final Widget child;

  /// Fill color. Defaults to [CountryTheme.card] — which, notably, is the
  /// *same hex as [CountryTheme.paper]* (see that token's doc comment), so
  /// the default alone doesn't visually separate a panel from the page
  /// behind it. Override with one of the alternate tones
  /// ([CountryTheme.cardWarm]/[cardCool]/[cardMint]/[aged]) for a panel
  /// that should read as sitting on the page, not flush with it — per
  /// Colleen, 2026-08-17: an exact color match with "no texture" reads as
  /// generic/AI-esque. See `DividedCard` callers for the actual mapping.
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
    // Walk each contour of the (already-notched) outline and stroke it in
    // dash/gap segments, rather than the whole path at once — dashing a
    // `Path` isn't a builtin, but `PathMetrics` gives exact-length
    // sub-paths to alternate between drawing and skipping.
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
