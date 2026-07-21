import 'package:flutter/material.dart';

import '../models/vocab_category.dart';

class PhraseListScreen extends StatelessWidget {
  final Subject subject;

  const PhraseListScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: subject.phrases.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final phrase = subject.phrases[index];
          return ListTile(
            title: Text(phrase.text, style: const TextStyle(fontSize: 16)),
          );
        },
      ),
    );
  }
}
