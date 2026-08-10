import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A bordered, rounded card whose children are separated by thin rule
/// dividers — no divider after the last child (.cardbox + .cities in the
/// mockup). Shared by the best-times list and the cities list, which use
/// the identical visual pattern for what are otherwise unrelated content
/// types.
class DividedCard extends StatelessWidget {
  final List<Widget> children;

  const DividedCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CountryTheme.rule),
        borderRadius: BorderRadius.circular(10),
        color: CountryTheme.card,
      ),
      clipBehavior: Clip.antiAlias,
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
