import 'package:flutter/material.dart';

import '../theme/accordion_theme.dart';

/// Placeholder destination for the country header's "About" link.
/// Intentionally blank — content isn't written yet. Standard `AppBar` back
/// button handles returning to whatever screen pushed this, no custom nav
/// needed here.
///
/// **Themed to match the rest of the app** (2026-08-17, per Colleen: "all
/// pages follow the same general stylings/theme as the country page") —
/// the app-wide `AppBarTheme`/`ThemeData` (`main.dart`) gives this the
/// same identity without needing its own bespoke chrome; there's no
/// content here yet to justify more.
///
/// **2026-08-18: repointed to `AccordionTheme`**, following `main.dart`'s
/// app-wide theme repoint — `PaperTexture` (a warm-parchment-era texture
/// that doesn't fit the flat accordion-page look) dropped along with it,
/// matching the plain page background `DestinationScreen`/
/// `CountryHeaderPreviewScreen` both already use.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccordionTheme.page,
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Text(
          'Coming soon.',
          style: TextStyle(fontFamily: AccordionTheme.dmSans, color: AccordionTheme.ink3, fontSize: 14),
        ),
      ),
    );
  }
}
