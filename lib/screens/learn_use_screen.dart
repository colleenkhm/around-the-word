import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_selection.dart';
import 'category_list_screen.dart';
import 'flashcard_screen.dart';

/// Screen 5: the Learn/Use fork.
class LearnUseScreen extends StatelessWidget {
  const LearnUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();

    return Scaffold(
      appBar: AppBar(title: Text(trip.selectedCountry?.name ?? '')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.style),
              label: const Text('Learn'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FlashcardScreen(
                      title: 'Learn',
                      deck: trip.mixedDeck,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Use'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategoryListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
