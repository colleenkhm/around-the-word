import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/accordion_theme.dart';

/// The "Practical Norms" [AccordionSection]'s expanded content — icon +
/// title + detail rows, one per [NormItem]. Icon is generic by
/// [NormItem.type], so a new type needs no widget change.
class PracticalNormsSection extends StatelessWidget {
  final List<NormItem> norms;

  /// This section's flag color.
  final Color tint;

  /// Black or white, whichever reads on [tint].
  final Color textColor;

  const PracticalNormsSection({
    super.key,
    required this.norms,
    required this.tint,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (norms.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: tint,
      child: Column(
        children: [
          for (var i = 0; i < norms.length; i++)
            _NormRow(norm: norms[i], showTopBorder: i != 0, textColor: textColor),
        ],
      ),
    );
  }
}

// Falls back to a generic info glyph for an unrecognized type.
IconData _iconFor(String type) => switch (type) {
      'tipping_norm' => Icons.payments_outlined,
      'punctuality_norm' => Icons.schedule_outlined,
      'transport_norm' => Icons.directions_car_outlined,
      _ => Icons.info_outline,
    };

class _NormRow extends StatelessWidget {
  final NormItem norm;
  final bool showTopBorder;
  final Color textColor;

  const _NormRow({required this.norm, required this.showTopBorder, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: showTopBorder
          ? BoxDecoration(border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.12))))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(_iconFor(norm.type), size: 18, color: textColor.withValues(alpha: 0.85)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(norm.title, style: AccordionTheme.rowTitle.copyWith(fontSize: 13.5, color: textColor)),
                const SizedBox(height: 2),
                Text(
                  norm.body,
                  style: AccordionTheme.sBody.copyWith(fontSize: 12.5, color: textColor.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
