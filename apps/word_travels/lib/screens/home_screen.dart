import 'dart:math';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/category.dart';
import '../models/phrase.dart';
import '../models/place.dart';
import '../state/location_settings.dart';
import '../state/recent_phrases.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import 'category_screen.dart';

// Matches the mockup's .cat-tile.r1..r6 — a small alternating tilt per
// tile so the grid reads as hand-placed tags, not a rigid grid.
const _tileTilts = [-0.6, 0.5, -0.4, 0.6, -0.5, 0.4];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void dispose() {
    _searchController.dispose();
    _recentScrollController.dispose();
    super.dispose();
  }

  List<Phrase> _searchResults(Place place) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return phrasesForPlace(place).where((p) => p.matches(q, place.country)).toList();
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
        .map(phraseById)
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
              Text('Ready when you are', style: ptHeading(size: 19)),
              const SizedBox(height: 4),
              Text(
                '${phrasesForPlace(place).length} phrases across ${categories.length} categories',
                style: ptBody(size: 12.5, color: PTColors.inkSoft),
              ),
              const SizedBox(height: 14),
              _SearchField(
                controller: _searchController,
                hint: 'Search a word or phrase',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: searching
                    ? _buildResults(place)
                    : _buildBrowse(recent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(Place place) {
    final results = _searchResults(place);
    if (results.isEmpty) {
      return Center(
        child: Text('No phrases match that search.', style: ptMono(size: 12.5)),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => PhraseFlipCard(
        key: ValueKey(results[index].id),
        phrase: results[index],
      ),
    );
  }

  Widget _buildBrowse(List<Phrase> recent) {
    return CustomScrollView(
      slivers: [
        if (recent.isNotEmpty)
          SliverToBoxAdapter(
            child: _RecentSection(
              phrases: recent,
              scrollController: _recentScrollController,
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _CategoryTile(
                category: categories[index],
                tiltDegrees: _tileTilts[index % _tileTilts.length],
              ),
              childCount: categories.length,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(top: 14),
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
                        centerEnglish: true,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PTColors.cardRow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PTColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: PTColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: ptBody(size: 13.5),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: PTColors.inkSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.tiltDegrees});

  final Category category;
  final double tiltDegrees;

  @override
  Widget build(BuildContext context) {
    final place = context.watch<LocationSettings>().place;
    final count = phrasesForCategory(category.id, place).length;

    return Transform.rotate(
      angle: tiltDegrees * pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: category.tint.background,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: category),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PTColors.ink, width: 1.4),
                ),
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: Icon(
                        category.icon,
                        color: category.tint.ink,
                        size: 19,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: ptHeading(size: 14, color: category.tint.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count phrases',
                          style: ptMono(size: 10, color: category.tint.ink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -5,
            left: 14,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PTColors.card,
                border: Border.all(color: PTColors.ink, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
