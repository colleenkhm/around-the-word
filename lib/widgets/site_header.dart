import 'package:flutter/material.dart';

import '../theme/accordion_theme.dart';

/// App's persistent site-wide nav bar — "whereabout" wordmark next to a
/// globe icon. One fixed look by default; see [backgroundColor]. No "About"
/// link — per direction received 2026-08-31, the wordmark (home) is the
/// only nav needed; navigation doesn't need to be more complicated than
/// that right now.
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
    return Container(
      color: background,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _tappable(
          onTap: onHomeTap,
          tooltip: 'Home',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 22, color: iconColor),
              const SizedBox(width: 8),
              Text('whereabout', style: wordmarkStyle),
            ],
          ),
        ),
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
