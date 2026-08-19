import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocab_entry.dart';

/// Flip-card flashcards, shuffled once per session. Takes any phrase
/// list, serving both Learn and single-category decks.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, required this.title, required this.deck});

  final String title;
  final List<VocabEntry> deck;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final List<VocabEntry> _shuffled;
  int _index = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _shuffled = List.of(widget.deck)..shuffle(Random());
  }

  void _next() {
    if (_index >= _shuffled.length - 1) return;
    setState(() {
      _index++;
      _flipped = false;
    });
  }

  void _previous() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffled.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No vocab selected yet.')),
      );
    }

    final entry = _shuffled[_index];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${_index + 1} / ${_shuffled.length}'),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      _flipped ? entry.translation : entry.phrase,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  onPressed: _index > 0 ? _previous : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton.filledTonal(
                  onPressed: _index < _shuffled.length - 1 ? _next : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
