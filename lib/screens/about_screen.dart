import 'package:flutter/material.dart';

/// Placeholder — linked from the landing screen's header nav. Content TBD.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Around the Word — coming soon.')),
    );
  }
}
