import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/resource.dart';
import '../../theme/accordion_theme.dart';

/// The "Additional Resources" [AccordionSection]'s expanded content —
/// generic, non-country-specific links (Google Translate, Wikitravel).
class AdditionalResourcesSection extends StatelessWidget {
  final List<Resource> resources;

  /// A version of this section's flag color guaranteed to read on white.
  final Color accent;

  const AdditionalResourcesSection({super.key, required this.resources, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < resources.length; i++)
          _ResourceRow(resource: resources[i], accent: accent, isLast: i == resources.length - 1),
      ],
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final Resource resource;
  final Color accent;
  final bool isLast;

  const _ResourceRow({required this.resource, required this.accent, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(resource.url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: isLast
            ? null
            : const BoxDecoration(border: Border(bottom: BorderSide(color: AccordionTheme.rule))),
        child: Row(
          children: [
            Expanded(
              child: Text(resource.label, style: AccordionTheme.rowTitle.copyWith(color: accent)),
            ),
            Icon(Icons.arrow_outward, size: 16, color: accent),
          ],
        ),
      ),
    );
  }
}
