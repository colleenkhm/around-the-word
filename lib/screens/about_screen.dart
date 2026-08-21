import 'package:flutter/material.dart';

import '../theme/accordion_theme.dart';
import '../widgets/site_footer.dart';

/// Placeholder destination for the "About" link. Content not written yet.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccordionTheme.page,
      appBar: AppBar(title: const Text('About')),
      body: const Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Coming soon.',
                style: TextStyle(
                  fontFamily: AccordionTheme.dmSans,
                  color: AccordionTheme.ink3,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SiteFooter(),
        ],
      ),
    );
  }
}
