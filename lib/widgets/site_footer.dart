import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

/// Small copyright line at the bottom of page content. Placeholder text
/// until the real notice is settled — see HANDOFF.md.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'built by Colleen Murray',
          style: TextStyle(
            fontFamily: AccordionTheme.dmMono,
            fontSize: 10.5,
            color: AccordionTheme.ink3.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
