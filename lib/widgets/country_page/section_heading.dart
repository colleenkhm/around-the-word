import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// A section label with a trailing rule line (.shead in the mockup) —
/// shared by every Overview-tab section ("Right now", "Best time to go",
/// "Cities", ...), not just this one.
class SectionHeading extends StatelessWidget {
  final String label;

  const SectionHeading(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(label, style: CountryTheme.sectionLabel),
          const SizedBox(width: 9),
          Expanded(child: Container(height: 1, color: CountryTheme.rule)),
        ],
      ),
    );
  }
}
