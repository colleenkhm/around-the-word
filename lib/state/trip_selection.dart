import 'package:flutter/foundation.dart';

import '../data/content_repository.dart';
import '../models/country.dart';
import '../models/subject.dart';
import '../models/vocab_entry.dart';

/// Holds the selection state threaded across the map -> categories ->
/// personalizing -> learn/use flow (language-app-system-design.md section 2).
class TripSelection extends ChangeNotifier {
  TripSelection({ContentRepository? repository})
      : _repository = repository ?? ContentRepository();

  final ContentRepository _repository;

  List<Country> countries = [];
  List<Subject> subjects = [];
  bool loadingReferenceData = true;

  String? selectedContinent;
  Country? selectedCountry;
  final Set<String> selectedCategoryIds = {};

  bool personalizing = false;
  Map<String, List<VocabEntry>>? personalizedContent;

  Future<void> loadReferenceData() async {
    countries = await _repository.loadCountries();
    subjects = await _repository.loadSubjects();
    loadingReferenceData = false;
    notifyListeners();
  }

  List<Country> countriesInContinent(String continent) =>
      countries.where((c) => c.continent == continent).toList();

  /// A continent shows as active if at least one of its countries is active
  /// — no separate continent-level flag to maintain.
  bool isContinentActive(String continent) =>
      countriesInContinent(continent).any((c) => c.active);

  void selectContinent(String continent) {
    selectedContinent = continent;
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

  /// Cosmetic in V1 — the delay is artificial, but this is written as a real
  /// async step so a future backend call can replace the body without a UI
  /// rework (language-app-system-design.md section 5).
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
