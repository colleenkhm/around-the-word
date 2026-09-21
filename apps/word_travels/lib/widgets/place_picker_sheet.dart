import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../state/location_settings.dart';
import '../theme/pocket_talk_theme.dart';

/// Bottom sheet for changing the country and settings the user is using the
/// language in. Choices apply immediately; dismiss the sheet when done.
Future<void> showPlacePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PTColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _PlacePickerSheet(),
  );
}

class _PlacePickerSheet extends StatelessWidget {
  const _PlacePickerSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LocationSettings>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Where are you using $targetLanguage?', style: ptHeading(size: 18)),
            const SizedBox(height: 4),
            Text(
              'You\'ll see $targetLanguage that works everywhere, plus vocab for your country and settings.',
              style: ptBody(size: 12.5, color: PTColors.inkSoft),
            ),
            const SizedBox(height: 14),
            Text('COUNTRY', style: ptMono(size: 10.5, color: PTColors.inkSoft)),
            for (final c in spanishCountries)
              OptionTile(
                label: c,
                selected: settings.country == c,
                onTap: () => context.read<LocationSettings>().selectCountry(c),
              ),
            const SizedBox(height: 10),
            Text('SETTING (PICK ANY)', style: ptMono(size: 10.5, color: PTColors.inkSoft)),
            for (final e in environmentOptions)
              OptionTile(
                label: e.name,
                description: e.description,
                selected: settings.environments?.contains(e.name) ?? false,
                onTap: () => context.read<LocationSettings>().toggleEnvironment(e.name),
              ),
          ],
        ),
      ),
    );
  }
}

/// One selectable row (a country, or a setting), shared by the picker sheet
/// and the first-launch screens.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ptBody(size: 14.5, weight: selected ? FontWeight.w600 : FontWeight.w400),
                  ),
                  if (description != null)
                    Text(description!, style: ptBody(size: 12, color: PTColors.inkSoft)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check, size: 18, color: PTColors.teal),
          ],
        ),
      ),
    );
  }
}
