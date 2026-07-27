import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../state/trip_selection.dart';
import 'personalizing_screen.dart';

/// Screen 3: multi-select checkboxes for top-level categories only —
/// sub-subjects are handled inside Learn/Use, not here.
class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();
    final topLevel = trip.subjects.topLevel;

    return Scaffold(
      appBar: AppBar(title: Text('What do you want to learn?')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: topLevel.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final subject = topLevel[index];
          final selected = trip.selectedCategoryIds.contains(subject.id);
          return CheckboxListTile(
            title: Text(subject.name),
            value: selected,
            onChanged: (_) => trip.toggleCategory(subject.id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: trip.selectedCategoryIds.isEmpty
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PersonalizingScreen(),
                  ),
                );
              },
        label: const Text('Continue'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
