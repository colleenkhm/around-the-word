import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/category.dart';
import '../models/phrase.dart';
import '../models/place.dart';
import '../state/location_settings.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import '../widgets/pt_search_field.dart';
import 'category_screen.dart';

// Matches the mockup's .cat-tile.r1..r6 — a small alternating tilt per
// tile so the grid reads as hand-placed tags, not a rigid grid.
const _tileTilts = [-0.6, 0.5, -0.4, 0.6, -0.5, 0.4];

/// The curated phrasebook: everything hand-written for this language,
/// scoped to where the user is, browsable by category. Search here filters
/// that set and nothing more — anything not in it is the Translate tab's
/// job, which [onTranslate] hands off to.
class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key, required this.onTranslate});

  final ValueChanged<String> onTranslate;

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
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

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final place = context.watch<LocationSettings>().place;

    return Scaffold(
      appBar: const PTAppBar.mark(title: 'Phrasebook'),
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
              PTSearchField(
                controller: _searchController,
                hint: 'Search your phrasebook',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: searching ? _buildResults(place) : _buildGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(Place place) {
    final results = _searchResults(place);
    if (results.isEmpty) return _buildNoMatch();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => PhraseFlipCard(
        key: ValueKey(results[index].id),
        phrase: results[index],
      ),
    );
  }

  /// Nothing curated matches. Rather than a dead end, hand the query to the
  /// Translate tab, which can look up anything.
  Widget _buildNoMatch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing in your phrasebook matches that.',
              textAlign: TextAlign.center,
              style: ptMono(size: 12.5),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: PTColors.ink,
                side: const BorderSide(color: PTColors.ink, width: 1.4),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => widget.onTranslate(_query.trim()),
              child: Text('Translate it instead', style: ptBody(size: 13.5)),
            ),
          ],
        ),
      ),
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
      itemBuilder: (context, index) => _CategoryTile(
        category: categories[index],
        tiltDegrees: _tileTilts[index % _tileTilts.length],
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
                  children: [
                    // Takes the space above the label so the icon sits in
                    // the middle of it, rather than pinned to the top.
                    Expanded(
                      child: Center(
                        child: Icon(
                          category.icon,
                          color: category.tint.ink,
                          size: 19,
                        ),
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
