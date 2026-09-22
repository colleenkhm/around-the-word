import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/location_settings.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import 'practice_screen.dart';

class VocabBankScreen extends StatelessWidget {
  const VocabBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final place = context.watch<LocationSettings>().place;
    final saved = context
        .watch<VocabBank>()
        .savedPhrases
        .where((p) => p.appliesTo(place))
        .toList();

    return Scaffold(
      appBar: const PTAppBar.mark(title: 'Saved'),
      body: SafeArea(
        top: false,
        child: saved.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Bookmark phrases from any category to build your practice deck.',
                    textAlign: TextAlign.center,
                    style: ptMono(size: 12.5),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${saved.length} saved', style: ptMono(size: 12)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: saved.length,
                        itemBuilder: (context, index) => PhraseFlipCard(
                          key: ValueKey(saved[index].id),
                          phrase: saved[index],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      // Always visible, even with nothing saved yet — a button that only
      // appears once you've cleared its own precondition means there's
      // nothing on screen to tell you practice exists at all. Muted and
      // still tappable while empty, so tapping it is how you find out what
      // unlocks it, rather than a dead end.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: saved.isEmpty ? PTColors.cardRow : PTColors.postal,
        foregroundColor: saved.isEmpty
            ? PTColors.inkSoft
            : const Color(0xFFFBE9E2),
        elevation: saved.isEmpty ? 0 : null,
        shape: saved.isEmpty
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: PTColors.line),
              )
            : null,
        icon: const Icon(Icons.edit_note),
        label: const Text('Practice'),
        onPressed: () {
          if (saved.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bookmark a phrase first to unlock practice.'),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PracticeScreen()),
          );
        },
      ),
    );
  }
}
