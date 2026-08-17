import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';
import 'ticket_panel.dart';

/// A ticket-stub-shaped panel whose children are separated by thin rule
/// dividers — no divider after the last child (.cardbox + .cities in the
/// mockup, though the ticket-notch shape itself is a 2026-08-11 addition
/// past what the mockup shows). Shared by the best-times list, cities
/// list, and Travel Info section, which use the identical visual pattern
/// for what are otherwise unrelated content types.
class DividedCard extends StatelessWidget {
  final List<Widget> children;

  /// Forwarded to [TicketPanel.color] — see that param's doc comment for
  /// why the default is worth overriding per section.
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
