import 'package:flutter/material.dart';

import '../screens/about_screen.dart';
import '../theme/accordion_theme.dart';

/// Small copyright line at the bottom of page content, plus the
/// "Sources & credits" link that source licenses need findable from
/// every page showing their data. Placeholder text until the real
/// notice is settled — see HANDOFF.md.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AccordionTheme.dmMono,
      fontSize: 10.5,
      color: AccordionTheme.ink3.withValues(alpha: 0.7),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('built by Colleen Murray', style: style),
            Text('  ·  ', style: style),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              child: Text(
                'Sources & credits',
                style: style.copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
