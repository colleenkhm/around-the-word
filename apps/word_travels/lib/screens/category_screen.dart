import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/category.dart';
import '../state/location_settings.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/phrase_flip_card.dart';
import '../widgets/pt_app_bar.dart';

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
    final place = context.watch<LocationSettings>().place;
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
              _SearchField(
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
                        itemBuilder: (context, index) =>
                            PhraseFlipCard(phrase: phrases[index]),
                      ),
              ),
            ],
          ),
        ),
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
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13.5,
              ),
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
