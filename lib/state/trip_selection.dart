import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../models/country.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/vocab_entry.dart';

/// Selection state threaded across destination -> categories ->
/// personalizing -> learn/use.
class TripSelection extends ChangeNotifier {
  TripSelection({ContentRepository? repository})
      : _repository = repository ?? ContentRepository();

  final ContentRepository _repository;

  List<Country> countries = [];
  List<Subject> subjects = [];
  List<Resource> resources = [];
  bool loadingReferenceData = true;

  Country? selectedCountry;
  final Set<String> selectedCategoryIds = {};

  bool personalizing = false;
  Map<String, List<VocabEntry>>? personalizedContent;

  Future<void> loadReferenceData() async {
    countries = await _repository.loadCountries();
    subjects = await _repository.loadSubjects();
    resources = await _repository.loadResources();
    loadingReferenceData = false;
    notifyListeners();
  }

  void selectCountry(Country country) {
    selectedCountry = country;
    selectedCategoryIds.clear();
    personalizedContent = null;
    notifyListeners();
  }

  void toggleCategory(String subjectId) {
    if (!selectedCategoryIds.remove(subjectId)) {
      selectedCategoryIds.add(subjectId);
    }
    notifyListeners();
  }

  /// Cosmetic in V1 (artificial delay), written as a real async step.
  Future<void> personalize() async {
    final country = selectedCountry;
    if (country == null || selectedCategoryIds.isEmpty) return;

    personalizing = true;
    notifyListeners();

    final results = await Future.wait([
      _repository.personalize(
        countryCode: country.countryCode,
        allSubjects: subjects,
        selectedTopLevelIds: selectedCategoryIds,
      ),
      Future.delayed(const Duration(milliseconds: 900)),
    ]);

    personalizedContent = results[0] as Map<String, List<VocabEntry>>;
    personalizing = false;
    notifyListeners();
  }

  /// All personalized entries mixed into one deck, for Learn mode.
  List<VocabEntry> get mixedDeck =>
      personalizedContent?.values.expand((e) => e).toList() ?? const [];
}
