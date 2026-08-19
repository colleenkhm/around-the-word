import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';
import 'ticket_panel.dart';

/// A ticket-stub-shaped panel whose children are separated by thin rule
/// dividers, none after the last child.
class DividedCard extends StatelessWidget {
  final List<Widget> children;

  /// Forwarded to [TicketPanel.color].
  final Color color;

  const DividedCard({super.key, required this.children, this.color = CountryTheme.card});

  @override
  Widget build(BuildContext context) {
    return TicketPanel(
      color: color,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Container(height: 1, color: CountryTheme.rule),
          ],
        ],
      ),
    );
  }
}
