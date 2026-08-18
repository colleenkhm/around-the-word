import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/accordion_theme.dart';

/// The "Practical Norms" [AccordionSection]'s expanded content — matches
/// `trip-dashboard-v5.html`'s `.sec-norms` card (a peach-tinted list of
/// icon + title + detail rows, `.norm-row`). Content-only, no card chrome
/// or heading.
///
/// Every [NormItem] on [CountryGuide.practicalNorms] (tipping,
/// punctuality, recommended transport app, ...) renders generically by
/// [NormItem.type] rather than a hardcoded case per type — a new norm
/// type added later needs no widget change beyond [_iconFor]'s fallback,
/// same reasoning [NormItem.type] itself is free-text/open-ended for.
class PracticalNormsSection extends StatelessWidget {
  final List<NormItem> norms;

  const PracticalNormsSection({super.key, required this.norms});

  @override
  Widget build(BuildContext context) {
    if (norms.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: AccordionTheme.peach,
      child: Column(
        children: [
          for (var i = 0; i < norms.length; i++)
            _NormRow(norm: norms[i], showTopBorder: i != 0),
        ],
      ),
    );
  }
}

/// Best-effort icon from [NormItem.type]'s open-ended string — falls back
/// to a generic info glyph for a type this doesn't recognize, rather than
/// leaving the row iconless.
IconData _iconFor(String type) => switch (type) {
      'tipping_norm' => Icons.payments_outlined,
      'punctuality_norm' => Icons.schedule_outlined,
      'transport_norm' => Icons.directions_car_outlined,
      _ => Icons.info_outline,
    };

class _NormRow extends StatelessWidget {
  final NormItem norm;
  final bool showTopBorder;

  const _NormRow({required this.norm, required this.showTopBorder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: showTopBorder
          ? BoxDecoration(border: Border(top: BorderSide(color: AccordionTheme.ink.withValues(alpha: 0.07))))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(_iconFor(norm.type), size: 18, color: AccordionTheme.ink2),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(norm.title, style: AccordionTheme.rowTitle.copyWith(fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(norm.body, style: AccordionTheme.sBody.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
