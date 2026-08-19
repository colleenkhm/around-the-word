import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/country_theme.dart';

/// A small "Label ↗" tappable link that opens [url] in the system
/// browser — shared visual language for every external link on the
/// country page.
class ExternalLink extends StatelessWidget {
  final String label;
  final String url;
  final Color color;
  final String fontFamily;

  const ExternalLink({
    super.key,
    required this.label,
    required this.url,
    this.color = CountryTheme.navy,
    this.fontFamily = 'Public Sans',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_outward, size: 11, color: color),
        ],
      ),
    );
  }
}
