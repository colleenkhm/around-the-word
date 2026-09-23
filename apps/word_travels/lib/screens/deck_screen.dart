import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';
import '../state/location_settings.dart';
import '../state/practice_scores.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import 'practice_screen.dart';

/// The practice tab: what drilling is available right now, then the deck it
/// draws from. Practice leads rather than sitting behind a button on a list,
/// because drilling is the point of saving anything.
///
/// The session itself stays a separate pushed screen rather than running
/// inline here — the deck below lists every answer, so an inline exercise
/// would be sitting directly above its own answer key.
class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final place = context.watch<LocationSettings>().place;
    final deck = context
        .watch<VocabBank>()
        .savedPhrasesForLanguage(currentLanguage.code)
        .where((p) => p.appliesTo(place))
        .toList();

    // Same signal practice sorts by: anything missed more than it's been
    // got right sits negative until it's actually learned.
    final scores = context.watch<PracticeScores>();
    final needWork = deck.where((p) => scores.scoreFor(p.id) < 0).length;

    return Scaffold(
      appBar: const PTAppBar.mark(title: 'Practice'),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StartCard(deckSize: deck.length, needWork: needWork),
              const SizedBox(height: 18),
              if (deck.isNotEmpty) ...[
                Text(
                  'YOUR DECK',
                  style: ptMono(size: 10.5, color: PTColors.inkSoft),
                ),
                const SizedBox(height: 8),
                Expanded(child: _DeckList(deck: deck)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.deckSize, required this.needWork});

  final int deckSize;
  final int needWork;

  bool get _ready => deckSize > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _ready ? PTColors.postalTint : PTColors.cardRow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _ready ? PTColors.ink : PTColors.line,
          width: _ready ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ready ? 'Ready to practice' : 'Nothing to practice yet',
            style: ptHeading(
              size: 17,
              color: _ready ? PTColors.postalInk : PTColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _subtitle,
            style: ptMono(
              size: 11.5,
              color: _ready ? PTColors.postalInk : PTColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _ready ? PTColors.postal : PTColors.cardRow,
                foregroundColor: _ready
                    ? const Color(0xFFFBE9E2)
                    : PTColors.inkSoft,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: _ready
                      ? BorderSide.none
                      : const BorderSide(color: PTColors.line),
                ),
              ),
              // Still tappable while empty, on purpose: a button that only
              // appears once you've cleared its own precondition can't tell
              // you what that precondition was.
              onPressed: () => _start(context),
              child: const Text('Start practice'),
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    if (!_ready) {
      return 'Bookmark a phrase, or look one up — anything you translate is added here automatically.';
    }
    final phrases = '$deckSize ${deckSize == 1 ? 'phrase' : 'phrases'}';
    if (needWork == 0) return '$phrases ready';
    return '$phrases · $needWork ${needWork == 1 ? 'needs' : 'need'} work';
  }

  void _start(BuildContext context) {
    if (!_ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save or look up a phrase first to unlock practice.'),
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PracticeScreen()));
  }
}

class _DeckList extends StatelessWidget {
  const _DeckList({required this.deck});

  final List<Phrase> deck;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: deck.length,
      itemBuilder: (context, index) =>
          PhraseFlipCard(key: ValueKey(deck[index].id), phrase: deck[index]),
    );
  }
}
