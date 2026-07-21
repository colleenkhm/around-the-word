import 'package:flutter/material.dart';

import '../data/vocab_data.dart';
import '../models/vocab_category.dart';
import 'phrase_list_screen.dart';
import 'subject_list_screen.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Around the Word')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vocabCategories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = vocabCategories[index];
          return ListTile(
            title: Text(category.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCategory(context, category),
          );
        },
      ),
    );
  }

  void _openCategory(BuildContext context, Category category) {
    // Categories with a single subject skip straight to the phrase list.
    if (category.subjects.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              PhraseListScreen(subject: category.subjects.first),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubjectListScreen(category: category),
        ),
      );
    }
  }
}
