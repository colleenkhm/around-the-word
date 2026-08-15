import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';
import 'dashed_divider.dart';

/// A section label with a trailing perforated "tear line" rule — shared by
/// every Overview-tab section ("Right now", "Advisories", "Cities", ...),
/// not just this one. The dashed line itself is [DashedDivider].
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
          const Expanded(child: DashedDivider(height: 8)),
        ],
      ),
    );
  }
}
