import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';

/// What the user has saved to practice, grouped by the trip it was saved
/// for. Two stores:
///
/// - `_decks` maps a phrase id to the trips it belongs to. One phrase can
///   sit in several decks — looking the same thing up for a second trip
///   adds membership rather than a copy, so its practice score (kept by id
///   in `PracticeScores`) carries over instead of resetting.
/// - `_lookedUp` holds the content of live-translated phrases, which unlike
///   curated ones can't be recovered from the seed data by id.
///
/// A phrase is saved exactly when it belongs to at least one deck, so
/// emptying its membership is what removes it.
class VocabBank extends ChangeNotifier {
  static const _decksKey = 'vocab_bank_decks';
  static const _lookedUpPrefsKey = 'vocab_bank_lookup_phrases';

  // What the pre-trips version stored: a flat list of saved ids with no
  // notion of which trip they were for.
  static const _legacySavedIdsKey = 'vocab_bank_phrase_ids';

  final Map<String, Set<String>> _decks = {};
  final Map<String, Phrase> _lookedUp = {};
  bool _loaded = false;
  SharedPreferences? _prefs;

  /// False until storage has been read. Migration from a pre-trips install
  /// waits on this, so it can't run against an empty bank and then be
  /// overwritten by the real contents landing a moment later.
  bool get loaded => _loaded;

  bool isSaved(String phraseId) => (_decks[phraseId] ?? const {}).isNotEmpty;

  bool isInTrip(String phraseId, String tripId) =>
      (_decks[phraseId] ?? const {}).contains(tripId);

  /// A live-translated phrase's content, or null for a curated one.
  Phrase? dynamicPhrase(String phraseId) => _lookedUp[phraseId];

  /// Everything saved, regardless of trip.
  List<Phrase> get savedPhrases =>
      _decks.keys.map(_resolve).whereType<Phrase>().toList();

  /// The deck for one trip.
  List<Phrase> deckFor(String tripId) => _decks.entries
      .where((e) => e.value.contains(tripId))
      .map((e) => _resolve(e.key))
      .whereType<Phrase>()
      .toList();

  /// Every phrase saved for any trip in [tripIds] — the umbrella deck that
  /// covers a whole language. A phrase in two of those trips appears once.
  List<Phrase> deckForTrips(Iterable<String> tripIds) {
    final wanted = tripIds.toSet();
    return _decks.entries
        .where((e) => e.value.any(wanted.contains))
        .map((e) => _resolve(e.key))
        .whereType<Phrase>()
        .toList();
  }

  Phrase? _resolve(String id) => phraseById(id) ?? _lookedUp[id];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    _lookedUp.clear();
    final storedLookups = _prefs?.getString(_lookedUpPrefsKey);
    if (storedLookups != null) {
      final decoded = jsonDecode(storedLookups) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _lookedUp[entry.key] = Phrase.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    _decks.clear();
    final storedDecks = _prefs?.getString(_decksKey);
    if (storedDecks != null) {
      final decoded = jsonDecode(storedDecks) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        _decks[entry.key] = (entry.value as List).map((t) => t as String).toSet();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Moves everything the pre-trips version saved into [tripId]. Safe to
  /// call more than once: it only runs while no memberships exist.
  void adoptLegacySaves(String tripId) {
    if (_decks.isNotEmpty) return;
    final legacy = _prefs?.getStringList(_legacySavedIdsKey) ?? const [];
    for (final id in [...legacy, ..._lookedUp.keys]) {
      _decks.putIfAbsent(id, () => {}).add(tripId);
    }
    if (_decks.isEmpty) return;
    notifyListeners();
    _persist();
  }

  /// Saves a live-translated phrase to [tripId]'s deck. Idempotent: looking
  /// the same thing up again refreshes its content and adds the trip.
  void saveLookup(Phrase phrase, String tripId) {
    _lookedUp[phrase.id] = phrase;
    _decks.putIfAbsent(phrase.id, () => {}).add(tripId);
    notifyListeners();
    _persist();
  }

  /// Adds or removes [phraseId] from [tripId]'s deck. A phrase that ends up
  /// in no deck at all is dropped, along with any stored lookup content.
  void toggle(String phraseId, String tripId) {
    final trips = _decks.putIfAbsent(phraseId, () => {});
    if (!trips.remove(tripId)) trips.add(tripId);
    if (trips.isEmpty) {
      _decks.remove(phraseId);
      _lookedUp.remove(phraseId);
    }
    notifyListeners();
    _persist();
  }

  /// Forgets a deck. Phrases that were only in it go too; those shared with
  /// another trip stay, and keep their practice history either way.
  void removeTrip(String tripId) {
    final emptied = <String>[];
    for (final entry in _decks.entries) {
      entry.value.remove(tripId);
      if (entry.value.isEmpty) emptied.add(entry.key);
    }
    for (final id in emptied) {
      _decks.remove(id);
      _lookedUp.remove(id);
    }
    notifyListeners();
    _persist();
  }

  void _persist() {
    _prefs?.setString(
      _decksKey,
      jsonEncode(_decks.map((id, trips) => MapEntry(id, trips.toList()))),
    );
    _prefs?.setString(
      _lookedUpPrefsKey,
      jsonEncode(_lookedUp.map((id, phrase) => MapEntry(id, phrase.toJson()))),
    );
  }
}
