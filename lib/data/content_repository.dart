import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/country.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/vocab_entry.dart';

/// Loads static JSON bundled as Flutter assets. No backend, no database.
class ContentRepository {
  Future<List<Country>> loadCountries() async {
    final raw = await rootBundle.loadString('assets/data/countries.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Subject>> loadSubjects() async {
    final raw = await rootBundle.loadString('assets/data/subjects.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generic links, one set reused everywhere, not curated per country.
  Future<List<Resource>> loadResources() async {
    final raw = await rootBundle.loadString('assets/data/resources.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Resource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All vocab for [countryCode], keyed by subject id. Missing file
  /// resolves to an empty map rather than throwing.
  Future<Map<String, List<VocabEntry>>> loadContent(String countryCode) async {
    final path =
        'assets/data/content/${countryCode.toLowerCase()}.json';
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (_) {
      return const {};
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (subjectId, entries) => MapEntry(
        subjectId,
        (entries as List<dynamic>)
            .map((e) => VocabEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  /// [selectedTopLevelIds] (and sub-subjects) filtered from the full content map.
  Future<Map<String, List<VocabEntry>>> personalize({
    required String countryCode,
    required List<Subject> allSubjects,
    required Set<String> selectedTopLevelIds,
  }) async {
    final content = await loadContent(countryCode);
    final result = <String, List<VocabEntry>>{};
    for (final topId in selectedTopLevelIds) {
      for (final id in allSubjects.idAndDescendantIds(topId)) {
        final entries = content[id];
        if (entries != null) {
          result[id] = entries;
        }
      }
    }
    return result;
  }
}
