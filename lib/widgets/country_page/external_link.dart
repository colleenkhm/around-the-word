import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/country_theme.dart';

/// A small "Label ↗" tappable link that opens [url] in the system
/// browser — shared visual language for every external link on the
/// country page (Travel Info's Source/Apply links, Right Now's currency
/// converter link). Extracted 2026-08-11 from what was a Travel-Info-only
/// private `_LinkLabel`, once a second call site needed the identical
/// look rather than a second copy of it.
///
/// Color is [CountryTheme.navy], not an accent — matches
/// `trip-dashboard-v3.html`'s `.tk-f-link`/`.src-row a`, both navy (2026-08-15;
/// see [CountryTheme.gold]'s doc comment on why gold isn't the default link
/// color in the new palette).
class ExternalLink extends StatelessWidget {
  final String label;
  final String url;

  const ExternalLink({super.key, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Public Sans',
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: CountryTheme.navy,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_outward, size: 11, color: CountryTheme.navy),
        ],
      ),
    );
  }
}
