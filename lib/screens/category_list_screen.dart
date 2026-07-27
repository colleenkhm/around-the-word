import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../state/trip_selection.dart';
import 'vocab_list_screen.dart';

/// Use mode: category list -> (sub-subjects, if any) -> vocab list.
/// Reused recursively for sub-subject screens (e.g. Food -> Cooking /
/// Grocery Shopping) rather than being a separate widget.
class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key, this.subjectsToShow, this.title});

  /// Defaults to the selected top-level categories when omitted (i.e. the
  /// screen reached directly from Learn/Use, not a sub-subject drill-down).
  final List<Subject>? subjectsToShow;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();
    final subjects = subjectsToShow ??
        trip.subjects
            .where((s) => trip.selectedCategoryIds.contains(s.id))
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Categories')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: subjects.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final children = trip.subjects.childrenOf(subject.id);
          return ListTile(
            title: Text(subject.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => children.isNotEmpty
                      ? CategoryListScreen(
                          subjectsToShow: children,
                          title: subject.name,
                        )
                      : VocabListScreen(subject: subject),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
