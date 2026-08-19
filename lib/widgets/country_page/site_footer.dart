import 'package:flutter/material.dart';

import '../../theme/accordion_theme.dart';

/// A small copyright line at the bottom of scrollable page content.
///
/// **Placeholder text, not a real copyright notice** — added 2026-08-19,
/// per Colleen: "I want to say like copyright 2026 whereabout like a lot
/// of footers but I can't say that yet." Shows the shape she wants
/// eventually (`© 2026 Whereabout`) with "— placeholder" appended so it's
/// obvious in the running app that this isn't a final legal notice yet,
/// rather than silently shipping unverified text that reads as final.
/// Swap [SiteFooter] for the real line (drop the "— placeholder" suffix,
/// update the year) once that's settled — everything else about this
/// widget stays the same.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '© 2026 Whereabout — placeholder',
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
