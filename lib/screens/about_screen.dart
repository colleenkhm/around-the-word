import 'package:flutter/material.dart';

/// Placeholder destination for the country header's "About" link.
/// Intentionally blank — content isn't written yet. Standard `AppBar` back
/// button handles returning to whatever screen pushed this, no custom nav
/// needed here.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('Coming soon.')),
    );
  }
}
