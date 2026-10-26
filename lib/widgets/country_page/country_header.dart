import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../../models/country_bundle.dart';
import '../../theme/section_palette.dart';
import '../../utils/flag_url.dart';

/// Country-page masthead: flag stamp, name, native name. Local time and
/// currency live on their own cards below it.
class CountryHeader extends StatelessWidget {
  final CountryBundle bundle;
  final String? nativeName;
  final String? nativeNameRomanized;

  /// Masthead's own colors — a deepened flag color.
  final SectionColors header;

  const CountryHeader({
    super.key,
    required this.bundle,
    required this.header,
    this.nativeName,
    this.nativeNameRomanized,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final onHeaderSoft = header.textColor.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      color: header.tint,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Stack(
        children: [
          Padding(
            // Room for the flag, positioned absolutely.
            padding: EdgeInsets.only(right: isDesktop ? 94 : 74),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION',
                  style: AccordionTheme.tkEyebrow.copyWith(color: onHeaderSoft),
                ),
                const SizedBox(height: 12),
                Text(
                  bundle.country.nameCommon,
                  style: AccordionTheme.tkName(
                    isDesktop ? 50 : 36,
                  ).copyWith(color: header.textColor),
                ),
                if (nativeName != null) ...[
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: AccordionTheme.tkNative.copyWith(
                        color: onHeaderSoft,
                      ),
                      children: [
                        TextSpan(text: nativeName),
                        if (nativeNameRomanized != null) ...[
                          const TextSpan(text: '   ·   '),
                          TextSpan(text: nativeNameRomanized),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Stretched top/bottom so Center has room to work with.
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: _Flag(isoCode: bundle.country.isoCode, desktop: isDesktop),
            ),
          ),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String isoCode;
  final bool desktop;

  const _Flag({required this.isoCode, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final imageWidth = desktop ? 68.0 : 50.0;
    final imageHeight = desktop ? 46.0 : 34.0;
    // White mat around the image (postage-stamp motif).
    const matPadding = 3.0;
    // Perforated-edge tooth size.
    const toothSize = 3.0;
    final matWidth = imageWidth + matPadding * 2;
    final matHeight = imageHeight + matPadding * 2;
    final totalWidth = matWidth + toothSize * 2;
    final totalHeight = matHeight + toothSize * 2;
    final placeholder = ColoredBox(color: Colors.white.withValues(alpha: 0.15));

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(totalWidth, totalHeight),
            painter: _StampEdgePainter(
              matRect: Rect.fromLTWH(toothSize, toothSize, matWidth, matHeight),
              toothSize: toothSize,
              color: Colors.white,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: Image.network(
              flagPngUrl(isoCode),
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Flag fetch failed for $isoCode: $error');
                return placeholder;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a white postage-stamp perforated edge around [matRect].
class _StampEdgePainter extends CustomPainter {
  final Rect matRect;
  final double toothSize;
  final Color color;

  const _StampEdgePainter({
    required this.matRect,
    required this.toothSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(matRect.left, matRect.top);
    _zigzagTo(path, matRect.topLeft, matRect.topRight, const Offset(0, -1));
    _zigzagTo(path, matRect.topRight, matRect.bottomRight, const Offset(1, 0));
    _zigzagTo(
      path,
      matRect.bottomRight,
      matRect.bottomLeft,
      const Offset(0, 1),
    );
    _zigzagTo(path, matRect.bottomLeft, matRect.topLeft, const Offset(-1, 0));
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 1.2, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  // Alternates baseline/outward points to form triangle teeth.
  void _zigzagTo(Path path, Offset start, Offset end, Offset outward) {
    final delta = end - start;
    final length = delta.distance;
    final steps = (length / toothSize).round().clamp(2, 200);
    final dir = Offset(delta.dx / length, delta.dy / length);
    final stepLength = length / steps;
    for (var i = 1; i <= steps; i++) {
      final base = start + dir * (stepLength * i);
      final point = i.isOdd ? base + outward * toothSize : base;
      path.lineTo(point.dx, point.dy);
    }
  }

  @override
  bool shouldRepaint(covariant _StampEdgePainter oldDelegate) =>
      oldDelegate.matRect != matRect ||
      oldDelegate.toothSize != toothSize ||
      oldDelegate.color != color;
}
