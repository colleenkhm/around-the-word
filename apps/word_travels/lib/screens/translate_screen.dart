import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';
import '../models/place.dart';
import '../services/translation_service.dart';
import '../state/location_settings.dart';
import '../state/recent_phrases.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import '../widgets/pt_search_field.dart';
import '../widgets/ticket_row.dart';

/// How long to wait after the user stops typing before treating an
/// unmatched query as a translation lookup rather than a curated search —
/// avoids hitting the API on every keystroke.
const _lookupDebounceDelay = Duration(milliseconds: 500);

/// Look anything up. A curated phrase wins when one matches — it has a real
/// pronunciation guide and a hand-picked practice word, and costs no API
/// call. Anything else is translated live and saved to the practice deck on
/// the spot.
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key, this.incomingQuery});

  /// A query handed over from another tab (the phrasebook's empty search).
  /// Changing it re-runs the lookup; see [didUpdateWidget].
  final String? incomingQuery;

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // The order the "recently looked up" strip is currently showing. Flipping
  // a card in the strip re-records that phrase as most recent, which would
  // otherwise re-sort the strip out from under the user's finger the moment
  // they tap it — visually a different card than the one they tapped ends
  // up in that spot. So this only adopts a fresh order when the *set* of
  // recent phrases changes (a genuinely new lookup came in from elsewhere);
  // re-ranking an already-shown phrase doesn't reshuffle what's on screen.
  List<String> _recentOrder = const [];

  // Scrolls the strip back to its start whenever _recentOrder gets a fresh
  // set — otherwise, if the user had scrolled the strip over, the new
  // primary card could land off to the left instead of being the one
  // actually on screen, which defeats the point of it being the primary one.
  final _recentScrollController = ScrollController();

  // The live-translation lookup that kicks in once a query has no curated
  // matches. _lookupQuery is the (trimmed) query the current loading/result/
  // error state belongs to — so a query change can tell "still waiting on
  // this" apart from "stale, belongs to what was typed before", and so
  // re-typing an already-resolved query re-shows its result without
  // re-hitting the API.
  Timer? _lookupDebounce;
  String? _lookupQuery;
  Phrase? _lookupResult;
  String? _lookupError;

  @override
  void initState() {
    super.initState();
    if (widget.incomingQuery != null) _adoptIncomingQuery();
  }

  @override
  void didUpdateWidget(TranslateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another tab handed over a query to look up. This screen stays alive in
    // the tab bar's IndexedStack, so a new one arrives as a prop change
    // rather than a fresh build.
    if (widget.incomingQuery != oldWidget.incomingQuery &&
        widget.incomingQuery != null) {
      _adoptIncomingQuery();
    }
  }

  void _adoptIncomingQuery() {
    final query = widget.incomingQuery!;
    _searchController.text = query;
    _onQueryChanged(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recentScrollController.dispose();
    _lookupDebounce?.cancel();
    super.dispose();
  }

  List<Phrase> _searchResults(Place place) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return phrasesForPlace(place).where((p) => p.matches(q, place.country)).toList();
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      _query = value;
      if (_lookupQuery != trimmed) {
        _lookupQuery = null;
        _lookupResult = null;
        _lookupError = null;
      }
    });
    _lookupDebounce?.cancel();
    if (trimmed.length < 2) return;
    _lookupDebounce = Timer(_lookupDebounceDelay, () {
      if (!mounted) return;
      final place = context.read<LocationSettings>().place;
      // A curated match beats a live translation — don't bother looking one
      // up if the search already found something.
      if (_searchResults(place).isNotEmpty) return;
      _runLookup(trimmed);
    });
  }

  Future<void> _runLookup(String query) async {
    setState(() {
      _lookupQuery = query;
      _lookupError = null;
      _lookupResult = null;
    });
    try {
      final target = await context.read<TranslationProvider>().translate(
        query,
        from: 'en',
        to: currentLanguage.code,
      );
      if (!mounted || _query.trim() != query) return;
      final phrase = Phrase.fromLookup(
        english: query,
        target: target,
        language: currentLanguage,
      );
      // Looking it up is the save — no extra tap.
      context.read<VocabBank>().saveLookup(phrase);
      context.read<RecentPhrases>().recordView(phrase.id);
      setState(() => _lookupResult = phrase);
    } catch (_) {
      if (!mounted || _query.trim() != query) return;
      setState(
        () => _lookupError =
            "Couldn't translate that — check your connection and tap to retry.",
      );
    }
  }

  /// Recently viewed phrases that still apply to [place], most recent first.
  List<Phrase> _recentPhrases(Place place) {
    final liveIds = context.watch<RecentPhrases>().ids;
    if (!setEquals(liveIds.toSet(), _recentOrder.toSet())) {
      _recentOrder = liveIds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_recentScrollController.hasClients) {
          _recentScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
    return _recentOrder
        .map((id) => resolvePhrase(context, id))
        .whereType<Phrase>()
        .where((p) => p.appliesTo(place))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final place = context.watch<LocationSettings>().place;
    final recent = _recentPhrases(place);

    return Scaffold(
      appBar: const PTAppBar.mark(title: 'Pocket Talk'),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PTSearchField(
                controller: _searchController,
                hint: 'Translate a word or phrase',
                onChanged: _onQueryChanged,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: searching ? _buildResults(place) : _buildIdle(recent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nothing typed yet: whatever they looked up recently, and a line saying
  /// what this screen does.
  Widget _buildIdle(List<Phrase> recent) {
    return CustomScrollView(
      slivers: [
        if (recent.isNotEmpty)
          SliverToBoxAdapter(
            child: _RecentSection(
              phrases: recent,
              scrollController: _recentScrollController,
            ),
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Align(
              alignment: recent.isEmpty ? Alignment.center : Alignment.topCenter,
              child: Text(
                'Type anything. We\'ll translate it and add it to your practice deck.',
                textAlign: TextAlign.center,
                style: ptMono(size: 12.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(Place place) {
    final results = _searchResults(place);
    if (results.isNotEmpty) {
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) => PhraseFlipCard(
          key: ValueKey(results[index].id),
          phrase: results[index],
        ),
      );
    }
    return _buildLookup();
  }

  /// What shows once a query has no curated match: too short to bother
  /// translating yet, translating, a result (auto-saved the moment it
  /// loads), or an error the user can tap to retry.
  Widget _buildLookup() {
    final trimmed = _query.trim();
    if (trimmed.length < 2) {
      return Center(
        child: Text('Keep typing to translate.', style: ptMono(size: 12.5)),
      );
    }

    if (_lookupQuery == trimmed && _lookupError != null) {
      return Center(
        child: GestureDetector(
          onTap: () => _runLookup(trimmed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _lookupError!,
              textAlign: TextAlign.center,
              style: ptMono(size: 12.5),
            ),
          ),
        ),
      );
    }

    if (_lookupQuery == trimmed && _lookupResult != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 4),
        child: _LiveTranslationCard(phrase: _lookupResult!),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 10),
          Text('Translating...', style: ptMono(size: 12.5)),
        ],
      ),
    );
  }
}

/// The in-the-moment result of a live translation lookup. Deliberately not
/// a [PhraseFlipCard]: the English and translated text are both visible at
/// once, no tap/flip needed. Once it's saved (already happened by the time
/// this is on screen) and shown anywhere else — the recent strip, Saved,
/// Practice — it's the normal flip flashcard.
class _LiveTranslationCard extends StatelessWidget {
  const _LiveTranslationCard({required this.phrase});

  final Phrase phrase;

  @override
  Widget build(BuildContext context) {
    final saved = context.select<VocabBank, bool>((bank) => bank.isSaved(phrase.id));
    const tint = PTTints.basics;

    return TicketRow(
      tint: tint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(phrase.english, style: ptBody(size: 13, color: tint.ink)),
                const SizedBox(height: 4),
                Text(phrase.target, style: ptHeading(size: 16.5, color: tint.ink)),
                const SizedBox(height: 6),
                Text(
                  saved ? 'Saved to your practice deck' : 'Removed from your practice deck',
                  style: ptMono(size: 10.5, color: tint.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.read<VocabBank>().toggle(phrase.id),
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? PTColors.mustard : PTColors.inkSoft,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal strip of the last few phrases the user actually looked at —
/// the fastest way back to what they needed a minute ago, without re-typing
/// a search or re-opening a category. Every card shares [_cardHeight]
/// regardless of how much content it holds, so the strip reads as one row
/// of even tiles rather than a jagged skyline; a card whose content would
/// run taller (e.g. a country-flagged phrase, with one row per country)
/// scrolls internally instead of growing past it.
class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.phrases, required this.scrollController});

  final List<Phrase> phrases;
  final ScrollController scrollController;

  // The most recent lookup (first in the list) reads as the primary one —
  // a bit larger than the rest, which all share one size.
  static const _primaryWidth = 250.0;
  static const _width = 210.0;
  static const _gap = 10.0;
  static const _cardHeight = 128.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECENTLY LOOKED UP', style: ptMono(size: 10.5, color: PTColors.inkSoft)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < phrases.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  // Keyed by phrase id, and on this SizedBox specifically —
                  // it's the direct Row child, so this is the widget Flutter
                  // actually looks at to decide whether to move an element
                  // (preserving its state) versus unmount/remount it. A key
                  // one level down, on PhraseFlipCard alone, isn't visible
                  // to that decision.
                  SizedBox(
                    key: ValueKey(phrases[i].id),
                    width: i == 0 ? _primaryWidth : _width,
                    height: _cardHeight,
                    child: SingleChildScrollView(
                      child: PhraseFlipCard(
                        phrase: phrases[i],
                        showNotches: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
