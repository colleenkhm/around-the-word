import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/category.dart';
import '../state/trips.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';
import '../widgets/pt_search_field.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = context.watch<Trips>().activePlace;
    final q = _query.trim().toLowerCase();
    final phrases = phrasesForCategory(widget.category.id, place)
        .where((p) => q.isEmpty || p.matches(q, place.country))
        .toList();

    return Scaffold(
      appBar: PTAppBar.back(title: widget.category.name),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PTSearchField(
                controller: _searchController,
                hint: 'Search ${widget.category.name.toLowerCase()}',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap a card to flip between Spanish and English.',
                style: ptMono(size: 11.5),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: phrases.isEmpty
                    ? Center(
                        child: Text(
                          'No phrases match that search.',
                          style: ptMono(size: 12.5),
                        ),
                      )
                    : ListView.builder(
                        itemCount: phrases.length,
                        itemBuilder: (context, index) => PhraseFlipCard(
                          key: ValueKey(phrases[index].id),
                          phrase: phrases[index],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
