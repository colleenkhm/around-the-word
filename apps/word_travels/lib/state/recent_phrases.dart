import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phrases the user has actually looked at recently (flipped a card on),
/// most recent first. This is the "quick access" signal for Home — the app
/// is meant for a fast lookup right before or in the moment, so getting back
/// to what you needed last time should take one glance, not a re-search.
/// Persisted locally like the vocab bank.
class RecentPhrases extends ChangeNotifier {
  static const _prefsKey = 'recent_phrase_ids';
  static const maxEntries = 8;

  final List<String> _ids = [];
  bool _loaded = false;
  SharedPreferences? _prefs;

  List<String> get ids => List.unmodifiable(_ids);

  /// False until storage has been read. [load] replaces whatever is in
  /// memory, so a view recorded before it lands would be thrown away — the
  /// app waits on this before building anything that can record one, the
  /// same way it waits on `VocabBank.loaded`.
  bool get loaded => _loaded;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getStringList(_prefsKey) ?? const [];
    _ids
      ..clear()
      ..addAll(stored);
    _loaded = true;
    notifyListeners();
  }

  /// Moves [phraseId] to the front, trimming to [maxEntries].
  void recordView(String phraseId) {
    _ids.remove(phraseId);
    _ids.insert(0, phraseId);
    if (_ids.length > maxEntries) {
      _ids.removeRange(maxEntries, _ids.length);
    }
    notifyListeners();
    _prefs?.setStringList(_prefsKey, _ids);
  }
}
