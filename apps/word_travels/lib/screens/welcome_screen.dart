import 'package:flutter/material.dart';

import '../theme/pocket_talk_theme.dart';

/// First-launch splash, matching the mockup's welcome screen: the postal
/// cancellation-stamp mark, tagline, feature pills, and one CTA.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              const _Stamp(),
              const SizedBox(height: 20),
              Text('Pocket Talk', style: ptHeading(size: 26)),
              const SizedBox(height: 10),
              Text(
                'The words you already know, right when you need them.',
                textAlign: TextAlign.center,
                style: ptBody(size: 14, color: PTColors.inkSoft).copyWith(height: 1.55),
              ),
              const SizedBox(height: 22),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _Pill(label: 'Works offline', background: PTColors.tealTint, foreground: PTColors.tealInk),
                  _Pill(label: 'No ads, ever', background: PTColors.postalTint, foreground: PTColors.postalInk),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PTColors.postal,
                    foregroundColor: const Color(0xFFFBE9E2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                  onPressed: onGetStarted,
                  child: const Text('Get started'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'A companion to language classes, not a replacement for them.',
                textAlign: TextAlign.center,
                style: ptBody(size: 12, color: PTColors.inkSoft).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -4 * 3.1415926535 / 180,
      child: Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: PTColors.ink, width: 2.5),
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: PTColors.line, style: BorderStyle.none),
          ),
          child: CustomPaint(
            painter: _DashedCirclePainter(),
            child: Center(child: Text('PT', style: ptHeading(size: 15))),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = PTColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashCount = 28;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * 3.1415926535;
      final sweep = (2 * 3.1415926535 / dashCount) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(label, style: ptMono(size: 11, color: foreground)),
        ],
      ),
    );
  }
}
