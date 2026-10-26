import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_theme/shared_theme.dart';

import '../data/phrases.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../state/trips.dart';
import '../state/vocab_bank.dart';
import '../theme/word_travels_theme.dart';

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
                description: tripSummary(trip),
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

/// How many things a trip has switched off, counting a muted setting as one
/// rather than as itself plus each of its activities — the number is there
/// to say "you've narrowed this trip", so the honest unit is the tap.
int mutedGroupCount(Set<String> muted) {
  var count = 0;
  for (final e in environmentOptions) {
    if (muted.contains(e.name)) {
      count++;
    } else {
      count += e.activities.where(muted.contains).length;
    }
  }
  return count;
}

/// Where a trip is going, and whether it's been narrowed — said only when
/// something is actually off, so an untouched trip reads as just its
/// destination.
String tripSummary(Trip trip) {
  final off = mutedGroupCount(trip.mutedTags);
  if (off == 0) return trip.country;
  return '${trip.country} · $off ${off == 1 ? 'topic' : 'topics'} off';
}

/// One selectable row (a country, a setting or an activity), shared by the
/// picker sheet and the first-launch screens.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.partial = false,
    this.indent = false,
    this.expanded,
    this.onToggleExpanded,
    this.onEdit,
    this.onDelete,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  /// Some but not all of what this row stands for is on — a setting whose
  /// activities disagree with it. Drawn as a dash rather than a tick, so
  /// "partly on" doesn't read as "on".
  final bool partial;

  /// Nested under the row above it (an activity under its setting).
  final bool indent;

  /// Non-null on a row that has activities of its own: whether they're
  /// showing, and how to flip that. Collapsed by default, so the resting
  /// state of the list is four settings rather than thirteen rows.
  final bool? expanded;
  final VoidCallback? onToggleExpanded;

  /// Trip rows carry these; country and setting rows don't.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: indent ? 7 : 11,
          bottom: indent ? 7 : 11,
          left: indent ? 22 : 0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ptBody(
                      size: indent ? 13.5 : 14.5,
                      weight: selected && !indent ? FontWeight.w600 : FontWeight.w400,
                      color: selected || partial ? PTColors.ink : PTColors.inkSoft,
                    ),
                  ),
                  if (description != null)
                    Text(description!, style: ptBody(size: 12, color: PTColors.inkSoft)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: PTColors.teal)
            else if (partial)
              const Icon(Icons.remove, size: 18, color: PTColors.teal),
            if (expanded != null)
              IconButton(
                tooltip: expanded! ? 'Hide activities' : 'Show activities',
                icon: Icon(
                  expanded! ? Icons.expand_less : Icons.expand_more,
                  size: 19,
                ),
                color: PTColors.inkSoft,
                onPressed: onToggleExpanded,
              ),
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
  late final Set<String> _muted = {...?widget.trip?.mutedTags};
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
          mutedTags: _muted,
        ),
      );
    } else {
      final name = _nameController.text.trim();
      trips.update(
        existing.copyWith(
          name: name.isEmpty ? _country! : name,
          country: _country,
          mutedTags: _muted,
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
              const SizedBox(height: 14),
              Text(
                'WHAT YOU\'LL PRACTICE',
                style: ptMono(size: 10.5, color: PTColors.inkSoft),
              ),
              const SizedBox(height: 2),
              Text(
                'All on to start. Switch off what this trip won\'t involve and it stays out of practice — phrases you\'ve saved yourself are never affected.',
                style: ptBody(size: 12, color: PTColors.inkSoft).copyWith(height: 1.4),
              ),
              TagMutePicker(muted: _muted, onChanged: () => setState(() {})),
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
                      fontFamily: AccordionTheme.dmSans,
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

/// The settings-and-activities list, shared by trip setup and the trip
/// editor: every tag on to begin with, switched off by tapping.
///
/// Mutates [muted] in place and calls [onChanged], rather than handing back
/// a new set, because both callers hold the set they're going to save and
/// only need to know it moved.
class TagMutePicker extends StatefulWidget {
  const TagMutePicker({
    super.key,
    required this.muted,
    required this.onChanged,
  });

  final Set<String> muted;
  final VoidCallback onChanged;

  @override
  State<TagMutePicker> createState() => _TagMutePickerState();
}

class _TagMutePickerState extends State<TagMutePicker> {
  /// Settings whose activities are showing. One whose activities already
  /// disagree with it starts open, since that's the state you can't read off
  /// a collapsed row.
  late final Set<String> _expanded = {
    for (final e in environmentOptions)
      if (e.activities.any(
        (a) => widget.muted.contains(a) != widget.muted.contains(e.name),
      ))
        e.name,
  };

  bool _isOn(String tag) => !widget.muted.contains(tag);

  /// Partly on when a setting and its activities disagree — either it's off
  /// with an activity switched back on, or on with one switched off.
  bool _isPartlyOn(EnvironmentOption e) {
    final states = [_isOn(e.name), ...e.activities.map(_isOn)];
    return states.contains(true) && states.contains(false);
  }

  /// Tapping a setting takes its activities with it, which is the point of
  /// the nesting — "I'm not going near the coast" shouldn't cost four taps.
  /// A partly-on setting switches fully off first, so tapping twice is
  /// always the way back to everything on.
  void _toggleSetting(EnvironmentOption e) {
    final turnOff = _isOn(e.name) || _isPartlyOn(e);
    setState(() {
      if (turnOff) {
        widget.muted.addAll([e.name, ...e.activities]);
      } else {
        widget.muted.removeAll([e.name, ...e.activities]);
      }
    });
    widget.onChanged();
  }

  /// An activity switches on its own without dragging its setting back with
  /// it: muting Coastal but keeping Surfing is a legal state, and means the
  /// surf phrases stay while the rest of the seaside vocabulary goes.
  void _toggleActivity(String activity) {
    setState(() {
      if (!widget.muted.remove(activity)) widget.muted.add(activity);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in environmentOptions) ...[
          OptionTile(
            label: e.name,
            description: e.description,
            selected: _isOn(e.name) && !_isPartlyOn(e),
            partial: _isPartlyOn(e),
            expanded: e.activities.isEmpty ? null : _expanded.contains(e.name),
            onToggleExpanded: () => setState(() {
              if (!_expanded.remove(e.name)) _expanded.add(e.name);
            }),
            onTap: () => _toggleSetting(e),
          ),
          if (_expanded.contains(e.name))
            for (final a in e.activities)
              OptionTile(
                label: a,
                indent: true,
                selected: _isOn(a),
                onTap: () => _toggleActivity(a),
              ),
        ],
      ],
    );
  }
}
