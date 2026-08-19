import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';
import 'dashed_divider.dart';

/// A section label with a trailing dashed "tear line" rule. [trailing],
/// if given, renders after the rule.
class SectionHeading extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const SectionHeading(this.label, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(label, style: CountryTheme.sectionLabel),
          const SizedBox(width: 9),
          const Expanded(child: DashedDivider(height: 8)),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
