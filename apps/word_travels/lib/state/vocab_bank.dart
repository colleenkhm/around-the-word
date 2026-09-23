import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';

/// The set of phrases a user has saved to practice: curated phrases by id
/// (the phrases themselves stay in the static seed data), plus phrases the
/// user looked up live via translation, which carry their own content since
/// they're not in the static seed data. Persisted locally so it survives
/// app restarts; no account, no backend.
class VocabBank extends ChangeNotifier {
  static const _prefsKey = 'vocab_bank_phrase_ids';
  static const _lookedUpPrefsKey = 'vocab_bank_lookup_phrases';

  final Set<String> _savedIds = {};
  final Map<String, Phrase> _lookedUp = {};
  SharedPreferences? _prefs;

  Set<String> get savedIds => Set.unmodifiable(_savedIds);

  List<Phrase> get savedPhrases => [
    ...allPhrases.where((p) => _savedIds.contains(p.id)),
    ..._lookedUp.values,
  ];

  /// [savedPhrases] scoped to one language — every entry self-describes its
  /// [Phrase.languageCode], so this is real filtering once a second
  /// language exists, even though it's a no-op today.
  List<Phrase> savedPhrasesForLanguage(String languageCode) =>
      savedPhrases.where((p) => p.languageCode == languageCode).toList();

  bool isSaved(String phraseId) =>
      _savedIds.contains(phraseId) || _lookedUp.containsKey(phraseId);

  /// A live-translated phrase saved under [phraseId], or null if it's a
  /// curated phrase (or isn't saved at all).
  Phrase? dynamicPhrase(String phraseId) => _lookedUp[phraseId];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getStringList(_prefsKey) ?? const [];
    _savedIds
      ..clear()
      ..addAll(stored);

    final storedLookups = _prefs?.getString(_lookedUpPrefsKey);
    _lookedUp.clear();
    if (storedLookups != null) {
      final decoded = jsonDecode(storedLookups) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _lookedUp[entry.key] = Phrase.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    notifyListeners();
  }

  /// Saves (or updates) a phrase looked up via live translation. Idempotent
  /// by id, so re-looking up the same phrase overwrites rather than
  /// duplicating.
  void saveLookup(Phrase phrase) {
    _lookedUp[phrase.id] = phrase;
    notifyListeners();
    _persist();
  }

  void toggle(String phraseId) {
    if (_savedIds.contains(phraseId)) {
      _savedIds.remove(phraseId);
    } else if (_lookedUp.containsKey(phraseId)) {
      _lookedUp.remove(phraseId);
    } else {
      _savedIds.add(phraseId);
    }
    notifyListeners();
    _persist();
  }

  void _persist() {
    _prefs?.setStringList(_prefsKey, _savedIds.toList());
    _prefs?.setString(
      _lookedUpPrefsKey,
      jsonEncode(_lookedUp.map((id, phrase) => MapEntry(id, phrase.toJson()))),
    );
  }
}
