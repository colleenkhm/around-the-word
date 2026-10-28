import 'package:flutter/material.dart';

import '../theme/accordion_theme.dart';

/// Shared placeholder for any section with no data yet.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Text(
        "Coming soon — we haven't curated this yet.",
        style: AccordionTheme.sBody.copyWith(
          color: AccordionTheme.ink3,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
