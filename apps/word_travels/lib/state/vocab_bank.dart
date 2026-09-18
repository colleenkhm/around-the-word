import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';

/// The set of phrases a user has saved to practice. Just a set of phrase
/// IDs — the phrases themselves stay in the static seed data for now.
/// Persisted locally so it survives app restarts; no account, no backend.
class VocabBank extends ChangeNotifier {
  static const _prefsKey = 'vocab_bank_phrase_ids';

  final Set<String> _savedIds = {};
  SharedPreferences? _prefs;

  Set<String> get savedIds => Set.unmodifiable(_savedIds);

  List<Phrase> get savedPhrases =>
      allPhrases.where((p) => _savedIds.contains(p.id)).toList();

  bool isSaved(String phraseId) => _savedIds.contains(phraseId);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getStringList(_prefsKey) ?? const [];
    _savedIds
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  void toggle(String phraseId) {
    if (_savedIds.contains(phraseId)) {
      _savedIds.remove(phraseId);
    } else {
      _savedIds.add(phraseId);
    }
    notifyListeners();
    _persist();
  }

  void _persist() {
    _prefs?.setStringList(_prefsKey, _savedIds.toList());
  }
}
