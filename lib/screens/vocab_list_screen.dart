import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../state/trip_selection.dart';
import 'flashcard_screen.dart';

class VocabListScreen extends StatelessWidget {
  const VocabListScreen({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();
    final entries = trip.personalizedContent?[subject.id] ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            title: Text(entry.phrase),
            subtitle: Text(entry.translation),
          );
        },
      ),
      floatingActionButton: entries.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.style),
              label: const Text('Flashcards'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FlashcardScreen(
                      title: subject.name,
                      deck: entries,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
