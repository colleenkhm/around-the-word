import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A running score per phrase, built from practice: +1 for each correct
/// answer, -1 for each miss. Scores accumulate across sessions rather than
/// resetting, so a phrase missed repeatedly keeps sinking — and keeps being
/// prioritized in the next practice deck — until it's actually been
/// learned. Persisted locally like the rest of this app's state.
class PracticeScores extends ChangeNotifier {
  static const _prefsKey = 'practice_scores';

  final Map<String, int> _scores = {};
  bool _loaded = false;
  SharedPreferences? _prefs;

  /// False until storage has been read. [load] replaces whatever is in
  /// memory, so a score recorded before it lands would be thrown away — the
  /// app waits on this before building anything that can record one, the
  /// same way it waits on `VocabBank.loaded`.
  bool get loaded => _loaded;

  /// A phrase's score; 0 if it's never been practiced.
  int scoreFor(String phraseId) => _scores[phraseId] ?? 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_prefsKey);
    if (stored != null) {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      _scores
        ..clear()
        ..addAll(decoded.map((id, score) => MapEntry(id, score as int)));
    }
    _loaded = true;
    notifyListeners();
  }

  void recordCorrect(String phraseId) => _adjust(phraseId, 1);

  void recordIncorrect(String phraseId) => _adjust(phraseId, -1);

  void _adjust(String phraseId, int delta) {
    _scores[phraseId] = scoreFor(phraseId) + delta;
    notifyListeners();
    _prefs?.setString(_prefsKey, jsonEncode(_scores));
  }
}
