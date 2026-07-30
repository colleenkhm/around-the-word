import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/country.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/vocab_entry.dart';

/// Loads the static JSON bundled as Flutter assets. No backend, no
/// database — see language-app-system-design.md section 5 for why.
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

  /// The shared, generic links shown on the coming-soon screen for
  /// countries without content yet (language-app-system-design.md section
  /// 3) — one set reused everywhere, not curated per country.
  Future<List<Resource>> loadResources() async {
    final raw = await rootBundle.loadString('assets/data/resources.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Resource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All vocab for [countryCode], keyed by subject id, straight from
  /// assets/data/content/{countryCode}.json. Only `active` countries reach
  /// this in the normal flow (inactive ones dead-end at the coming-soon
  /// screen before content is ever loaded), so a missing file here means
  /// `active` was flipped without the content file existing yet — resolves
  /// to an empty map rather than throwing, as a safety net for that case.
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

  /// The "personalized dictionary" — not new data, just [selectedTopLevelIds]
  /// (and their sub-subjects) filtered out of the country's full content map.
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
