import 'package:flutter/material.dart';

import '../theme/pocket_talk_theme.dart';

/// The mockup's `.ticket-row`: a card-row panel with two small circular
/// notches cut into its left/right edges (colored to match the surface
/// behind it), like a torn ticket stub.
class TicketRow extends StatelessWidget {
  const TicketRow({super.key, required this.child});

  final Widget child;

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
              color: PTColors.cardRow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PTColors.line),
            ),
            child: child,
          ),
          const Positioned(left: -6, top: 0, bottom: 0, child: Center(child: _Notch())),
          const Positioned(right: -6, top: 0, bottom: 0, child: Center(child: _Notch())),
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
