import 'package:flutter/material.dart';

import '../theme/pocket_talk_theme.dart';

/// The mockup's `.ticket-row`: a card-row panel with two small circular
/// notches cut into its left/right edges (colored to match the surface
/// behind it), like a torn ticket stub. Tinted like the home grid's
/// category tiles (soft tint background, bold ink border) rather than a
/// plain cream row, so it doesn't read as flat cream-on-cream.
class TicketRow extends StatelessWidget {
  const TicketRow({super.key, required this.tint, required this.child, this.showNotches = true});

  final PTTint tint;
  final Widget child;

  /// The ticket-stub notches read fine in a full-width row, but in the
  /// narrow "recently looked up" cards they eat into already-tight
  /// horizontal space and just clutter the card — so callers there opt out.
  final bool showNotches;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PTColors.ink, width: 1.4),
            ),
            child: child,
          ),
          if (showNotches) ...[
            const Positioned(left: -6, top: 0, bottom: 0, child: Center(child: _Notch())),
            const Positioned(right: -6, top: 0, bottom: 0, child: Center(child: _Notch())),
          ],
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PTColors.card,
        border: Border.all(color: PTColors.line),
      ),
    );
  }
}
