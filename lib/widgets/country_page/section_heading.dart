import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';
import 'dashed_divider.dart';

/// A section label with a trailing perforated "tear line" rule — shared by
/// every Overview-tab section ("Advisories", "Cities", ...), not just this
/// one. The dashed line itself is [DashedDivider].
///
/// [trailing], if given, renders after the dashed rule — added 2026-08-15
/// for the Travel Info restyle's emergency-number badge (mockup's advisory
/// card header has "Travel advisory" on the left, an emergency number on
/// the right). `null` by default, so every existing call site is
/// unaffected.
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
