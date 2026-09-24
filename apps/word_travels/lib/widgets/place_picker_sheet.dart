import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/trip.dart';
import '../state/trips.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';

/// Switch between trips, or start a new one. Each trip keeps its own
/// vocabulary, so this is also what decides where a lookup gets saved.
Future<void> showTripPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PTColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _TripPickerSheet(),
  );
}

class _TripPickerSheet extends StatelessWidget {
  const _TripPickerSheet();

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<Trips>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your trips', style: ptHeading(size: 18)),
            const SizedBox(height: 4),
            Text(
              'Each trip keeps its own vocabulary. Anything you look up is saved to the one you\'re on.',
              style: ptBody(size: 12.5, color: PTColors.inkSoft),
            ),
            const SizedBox(height: 6),
            for (final trip in trips.trips)
              OptionTile(
                label: trip.name,
                description: trip.environments.isEmpty
                    ? trip.country
                    : '${trip.country} · ${trip.environments.join(', ')}',
                selected: trips.active?.id == trip.id,
                onTap: () => context.read<Trips>().setActive(trip.id),
                onEdit: () async {
                  Navigator.of(context).pop();
                  await showTripEditor(context, trip: trip);
                },
                onDelete: trips.trips.length > 1
                    ? () => _confirmDelete(context, trip)
                    : null,
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await showTripEditor(context);
              },
              icon: const Icon(Icons.add, size: 18, color: PTColors.ink),
              label: Text('New trip', style: ptBody(size: 13.5)),
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
    this.onEdit,
    this.onDelete,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  /// Trip rows carry these; country and setting rows don't.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
            if (onEdit != null)
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 17),
                color: PTColors.inkSoft,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, size: 17),
                color: PTColors.inkSoft,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// Deleting a trip takes the vocabulary saved only to it; anything also
/// saved to another trip stays there, with its practice history intact.
Future<void> _confirmDelete(BuildContext context, Trip trip) async {
  final trips = context.read<Trips>();
  final bank = context.read<VocabBank>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: PTColors.card,
      title: Text('Delete ${trip.name}?', style: ptHeading(size: 17)),
      content: Text(
        'Vocabulary saved only to this trip goes with it. Anything also saved to another trip stays.',
        style: ptBody(size: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: ptBody(size: 13.5)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete', style: ptBody(size: 13.5, color: PTColors.postal)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  bank.removeTrip(trip.id);
  trips.remove(trip.id);
}

/// Create a trip, or change an existing one's name, destination and settings.
Future<void> showTripEditor(BuildContext context, {Trip? trip}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PTColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _TripEditorSheet(trip: trip),
  );
}

class _TripEditorSheet extends StatefulWidget {
  const _TripEditorSheet({this.trip});

  final Trip? trip;

  @override
  State<_TripEditorSheet> createState() => _TripEditorSheetState();
}

class _TripEditorSheetState extends State<_TripEditorSheet> {
  late String? _country = widget.trip?.country;
  late final Set<String> _environments = {...?widget.trip?.environments};
  late final _nameController = TextEditingController(text: widget.trip?.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final trips = context.read<Trips>();
    final existing = widget.trip;
    if (existing == null) {
      trips.add(
        Trip.create(
          languageCode: currentLanguage.code,
          country: _country!,
          name: _nameController.text,
          environments: _environments,
        ),
      );
    } else {
      final name = _nameController.text.trim();
      trips.update(
        existing.copyWith(
          name: name.isEmpty ? _country! : name,
          country: _country,
          environments: _environments,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trip == null ? 'New trip' : 'Edit trip',
                style: ptHeading(size: 18),
              ),
              const SizedBox(height: 14),
              Text('NAME', style: ptMono(size: 10.5, color: PTColors.inkSoft)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: ptBody(size: 13.5),
                decoration: InputDecoration(
                  hintText: _country ?? 'Optional — defaults to the country',
                  hintStyle: const TextStyle(color: PTColors.inkSoft),
                  filled: true,
                  fillColor: PTColors.cardRow,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: PTColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('COUNTRY', style: ptMono(size: 10.5, color: PTColors.inkSoft)),
              for (final c in currentLanguage.countries)
                OptionTile(
                  label: c,
                  selected: _country == c,
                  onTap: () => setState(() => _country = c),
                ),
              const SizedBox(height: 10),
              Text(
                'SETTING (PICK ANY)',
                style: ptMono(size: 10.5, color: PTColors.inkSoft),
              ),
              for (final e in environmentOptions)
                OptionTile(
                  label: e.name,
                  description: e.description,
                  selected: _environments.contains(e.name),
                  onTap: () => setState(() {
                    if (!_environments.remove(e.name)) _environments.add(e.name);
                  }),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PTColors.postal,
                    foregroundColor: const Color(0xFFFBE9E2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                  onPressed: _country == null ? null : _save,
                  child: Text(widget.trip == null ? 'Create trip' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
