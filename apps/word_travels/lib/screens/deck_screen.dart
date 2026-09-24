import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';
import '../models/place.dart';
import '../state/practice_scores.dart';
import '../state/trips.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import 'practice_screen.dart';

/// The practice tab. With one trip there's only one deck, so it opens
/// straight into it; with several, they're listed separately by trip — plus
/// an umbrella deck per language once two or more trips share one, for
/// drilling all your Spanish rather than one destination's worth.
class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<Trips>();

    if (trips.trips.length <= 1) {
      final trip = trips.active;
      return _DeckDetail(
        title: 'Practice',
        deck: trip == null ? const [] : context.watch<VocabBank>().deckFor(trip.id),
        place: trips.activePlace,
        showBack: false,
      );
    }

    return Scaffold(
      appBar: const PTAppBar.mark(title: 'Practice'),
      body: SafeArea(top: false, child: _DeckList(trips: trips)),
    );
  }
}

/// One card per trip, and one per language whose trips number more than one.
class _DeckList extends StatelessWidget {
  const _DeckList({required this.trips});

  final Trips trips;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<VocabBank>();
    final scores = context.watch<PracticeScores>();

    final languages = <String>{for (final t in trips.trips) t.languageCode};
    final umbrellas = languages
        .where((code) => trips.tripsForLanguage(code).length > 1)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text('YOUR DECKS', style: ptMono(size: 10.5, color: PTColors.inkSoft)),
        const SizedBox(height: 8),
        for (final trip in trips.trips)
          _DeckCard(
            title: trip.name,
            subtitle: trip.country,
            deck: bank.deckFor(trip.id),
            place: Place(trip.country, trip.environments),
            scores: scores,
          ),
        if (umbrellas.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'EVERYTHING',
            style: ptMono(size: 10.5, color: PTColors.inkSoft),
          ),
          const SizedBox(height: 8),
          for (final code in umbrellas)
            _DeckCard(
              title: _languageName(code),
              subtitle: 'All ${trips.tripsForLanguage(code).length} trips',
              deck: bank.deckForTrips(
                trips.tripsForLanguage(code).map((t) => t.id),
              ),
              place: trips.activePlace,
              scores: scores,
              accent: true,
            ),
        ],
      ],
    );
  }

  String _languageName(String code) =>
      code == currentLanguage.code ? currentLanguage.name : code.toUpperCase();
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.title,
    required this.subtitle,
    required this.deck,
    required this.place,
    required this.scores,
    this.accent = false,
  });

  final String title;
  final String subtitle;
  final List<Phrase> deck;
  final Place place;
  final PracticeScores scores;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final needWork = deck.where((p) => scores.scoreFor(p.id) < 0).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: accent ? PTColors.postalTint : PTColors.cardRow,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _DeckDetail(
                title: title,
                deck: deck,
                place: place,
                showBack: true,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PTColors.ink, width: 1.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ptHeading(size: 16)),
                      const SizedBox(height: 3),
                      Text(
                        _summary(deck.length, needWork, subtitle),
                        style: ptMono(size: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: PTColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summary(int size, int needWork, String subtitle) {
    if (size == 0) return '$subtitle · empty';
    final phrases = '$size ${size == 1 ? 'phrase' : 'phrases'}';
    if (needWork == 0) return '$subtitle · $phrases';
    return '$subtitle · $phrases · $needWork ${needWork == 1 ? 'needs' : 'need'} work';
  }
}

/// One deck: what's drillable right now, then the phrases it holds.
///
/// The session itself is a pushed screen rather than running inline, because
/// the deck below lists every answer — an inline exercise would be sitting
/// directly above its own answer key.
class _DeckDetail extends StatelessWidget {
  const _DeckDetail({
    required this.title,
    required this.deck,
    required this.place,
    required this.showBack,
  });

  final String title;
  final List<Phrase> deck;
  final Place place;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final scores = context.watch<PracticeScores>();
    final visible = deck.where((p) => p.appliesTo(place)).toList();
    final needWork = visible.where((p) => scores.scoreFor(p.id) < 0).length;

    return Scaffold(
      appBar: showBack
          ? PTAppBar.back(title: title)
          : PTAppBar.mark(title: title),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StartCard(
                deck: visible,
                place: place,
                needWork: needWork,
                title: title,
              ),
              const SizedBox(height: 18),
              if (visible.isNotEmpty) ...[
                Text(
                  'YOUR DECK',
                  style: ptMono(size: 10.5, color: PTColors.inkSoft),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) => PhraseFlipCard(
                      key: ValueKey(visible[index].id),
                      phrase: visible[index],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.deck,
    required this.place,
    required this.needWork,
    required this.title,
  });

  final List<Phrase> deck;
  final Place place;
  final int needWork;
  final String title;

  bool get _ready => deck.isNotEmpty;

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
    final phrases = '${deck.length} ${deck.length == 1 ? 'phrase' : 'phrases'}';
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PracticeScreen(phrases: deck, place: place, title: title),
      ),
    );
  }
}
