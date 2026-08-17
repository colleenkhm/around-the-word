import 'package:flutter/material.dart';

import '../../models/country_guide.dart';
import '../../theme/country_theme.dart';
import 'divided_card.dart';
import 'section_heading.dart';

/// The Overview tab's Practical notes section — every [NormItem] on
/// [CountryGuide.practicalNorms] (tipping, punctuality, recommended
/// transport app, ...; see the data architecture doc's `practical_norms`
/// section), rendered generically by type.
///
/// New this pass. `trip-dashboard-v3.html` only shows one example —
/// `transport_norm`, as a "Getting around" card — but `tipping_norm`/
/// `punctuality_norm` already have real curated mock data with no UI
/// anywhere before this (confirmed against the Costa Rica bundle). Rather
/// than build only the one type the mockup happens to show, this renders
/// every `NormItem` the same way, keyed off [NormItem.type] rather than a
/// hardcoded case per type — a new norm type added later needs no widget
/// change, same reasoning [NormItem.type] itself is free-text/open-ended
/// for.
///
/// **No color-coding by [NormItem.severity]** — the mockup has no severity
/// treatment on its one example to copy, and inventing a red/amber/green
/// scheme here risks reading as an advisory-level warning, which this
/// isn't. Severity is available on the model if a real design for it comes
/// later; this pass just renders title + body.
class PracticalNormsSection extends StatelessWidget {
  final List<NormItem> norms;

  const PracticalNormsSection({super.key, required this.norms});

  @override
  Widget build(BuildContext context) {
    if (norms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Practical notes'),
        // aged — no dedicated mockup tone for this section (unlike
        // Advisories/Visa's mint/cool), so it gets the theme's spare
        // generic alternate rather than the page-matching default
        // (2026-08-17, see CountryTheme.aged's doc comment).
        DividedCard(
          color: CountryTheme.aged,
          children: [for (final norm in norms) _NormRow(norm: norm)],
        ),
      ],
    );
  }
}

class _NormRow extends StatelessWidget {
  final NormItem norm;

  const _NormRow({required this.norm});

  /// "transport_norm" -> "TRANSPORT". Best-effort label from the
  /// open-ended [NormItem.type] string — strips a trailing "_norm" if
  /// present rather than assuming every type follows that suffix exactly,
  /// since new types are free-text by design (see class doc).
  String get _typeLabel {
    final stripped = norm.type.endsWith('_norm')
        ? norm.type.substring(0, norm.type.length - '_norm'.length)
        : norm.type;
    return stripped.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_typeLabel, style: CountryTheme.listRowIndex),
          const SizedBox(height: 4),
          Text(norm.title, style: CountryTheme.listRowTitle),
          const SizedBox(height: 4),
          Text(norm.body, style: CountryTheme.listRowDetail),
        ],
      ),
    );
  }
}
