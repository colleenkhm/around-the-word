import 'dart:math';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Phrase> _searchResults(Place place) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return phrasesForPlace(place).where((p) => p.matches(q, place.country)).toList();
  }

  /// Recently viewed phrases that still apply to [place], most recent first.
  List<Phrase> _recentPhrases(Place place) {
    final ids = context.watch<RecentPhrases>().ids;
    return ids
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
              if (!searching && recent.isNotEmpty) _RecentSection(phrases: recent),
              const SizedBox(height: 16),
              Expanded(child: searching ? _buildResults(place) : _buildGrid()),
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
      itemBuilder: (context, index) => PhraseFlipCard(phrase: results[index]),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        return _CategoryTile(
          category: categories[index],
          tiltDegrees: _tileTilts[index % _tileTilts.length],
        );
      },
    );
  }
}

/// A horizontal strip of the last few phrases the user actually looked at —
/// the fastest way back to what they needed a minute ago, without re-typing
/// a search or re-opening a category. No fixed height: a country-flagged
/// phrase's card can run taller than most, and this only needs to fit the
/// tallest one currently shown, not clip to a guess.
class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.phrases});

  final List<Phrase> phrases;

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
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final phrase in phrases)
                  SizedBox(
                    width: 230,
                    child: PhraseFlipCard(phrase: phrase),
                  ),
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
