import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/country.dart';
import '../state/trip_selection.dart';

/// Retired dead end, kept for history — see HANDOFF.md.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.country});

  final Country country;

  @override
  Widget build(BuildContext context) {
    final resources = context.watch<TripSelection>().resources;

    return Scaffold(
      appBar: AppBar(title: Text(country.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We're working on content for ${country.name} — here in the meantime:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            for (final resource in resources)
              Card(
                child: ListTile(
                  title: Text(resource.label),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => launchUrl(
                    Uri.parse(resource.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
