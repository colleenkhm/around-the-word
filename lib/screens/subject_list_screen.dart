import 'package:flutter/material.dart';

import '../models/vocab_category.dart';
import 'phrase_list_screen.dart';

class SubjectListScreen extends StatelessWidget {
  final Category category;

  const SubjectListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: category.subjects.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final subject = category.subjects[index];
          return ListTile(
            title: Text(subject.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PhraseListScreen(subject: subject),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
