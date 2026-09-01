import 'package:flutter/material.dart';

import '../theme/accordion_theme.dart';

/// App's persistent site-wide nav bar — "Forin" wordmark next to a globe
/// icon on the left, the tagline on the right. One fixed look by default;
/// see [backgroundColor]. No "About" link — per direction received
/// 2026-08-31, the wordmark (home) is the only nav needed; navigation
/// doesn't need to be more complicated than that right now.
class SiteHeader extends StatelessWidget {
  final VoidCallback? onHomeTap;
  final Color? backgroundColor;

  const SiteHeader({
    super.key,
    this.onHomeTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Owns status-bar/notch clearance, capped at 32.
    final topInset = MediaQuery.paddingOf(context).top.clamp(0.0, 32.0);
    final background = backgroundColor ?? AccordionTheme.ink;
    final iconColor = Colors.white.withValues(alpha: 0.85);
    final wordmarkStyle = const TextStyle(
      fontFamily: AccordionTheme.fraunces,
      fontWeight: FontWeight.w700,
      fontSize: 17,
      letterSpacing: -0.1,
      color: Colors.white,
    );
    final taglineStyle = TextStyle(
      fontFamily: AccordionTheme.dmSans,
      fontSize: 11,
      fontStyle: FontStyle.italic,
      color: Colors.white.withValues(alpha: 0.65),
    );

    return Container(
      color: background,
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 10),
      child: Row(
        children: [
          _tappable(
            onTap: onHomeTap,
            tooltip: 'Home',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 22, color: iconColor),
                const SizedBox(width: 8),
                Text('Forin', style: wordmarkStyle),
              ],
            ),
          ),
          const Spacer(),
          Text('making the foreign familiar', style: taglineStyle),
        ],
      ),
    );
  }

  // Tappable when onTap is set, plain otherwise — same shape either way.
  Widget _tappable({
    required VoidCallback? onTap,
    required String tooltip,
    required Widget child,
  }) {
    if (onTap == null) return child;
    return Tooltip(
      message: tooltip,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
