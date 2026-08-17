import 'package:flutter/material.dart';

import '../theme/country_theme.dart';
import '../widgets/country_page/paper_texture.dart';

/// Placeholder destination for the country header's "About" link.
/// Intentionally blank — content isn't written yet. Standard `AppBar` back
/// button handles returning to whatever screen pushed this, no custom nav
/// needed here.
///
/// **Themed to match the country page** (2026-08-17, per Colleen: "all
/// pages follow the same general stylings/theme as the country page") —
/// `PaperTexture` background plus the app-wide `AppBarTheme` (navy,
/// `main.dart`) gives this the same navy/cream identity without needing
/// its own bespoke chrome; there's no content here yet to justify more.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const PaperTexture(
        child: Center(
          child: Text(
            'Coming soon.',
            style: TextStyle(fontFamily: 'Public Sans', color: CountryTheme.inkSoft, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
