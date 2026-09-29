import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/phrases.dart';
import '../models/place.dart';
import '../models/trip.dart';

/// The user's trips, and which one they're currently on. Replaces the old
/// global country/settings: those are trip properties now, so everything
/// downstream still asks for a [Place] — it just comes from the active trip.
class Trips extends ChangeNotifier {
  static const _tripsKey = 'trips';
  static const _activeKey = 'active_trip_id';

  // The keys the pre-trips version wrote its global settings to. Read once,
  // to build the first trip out of what the user already chose.
  static const _legacyCountryKey = 'selected_country';
  static const _legacyEnvironmentsKey = 'selected_environments';

  final List<Trip> _trips = [];
  String? _activeId;
  bool _loaded = false;
  SharedPreferences? _prefs;

  List<Trip> get trips => List.unmodifiable(_trips);

  /// False until storage has been read, so the app doesn't flash onboarding
  /// at someone who already has trips.
  bool get loaded => _loaded;

  bool get hasTrip => _trips.isNotEmpty;

  Trip? get active {
    if (_trips.isEmpty) return null;
    for (final t in _trips) {
      if (t.id == _activeId) return t;
    }
    return _trips.first;
  }

  /// Where the active trip is going — the filter every phrase list applies.
  /// With no trip yet, an empty place shows everything.
  Place get activePlace {
    final trip = active;
    return trip == null ? const Place(null) : Place(trip.country, trip.mutedTags);
  }

  /// Trips that teach [languageCode], used to decide whether an umbrella
  /// deck for that language is worth offering.
  List<Trip> tripsForLanguage(String languageCode) =>
      _trips.where((t) => t.languageCode == languageCode).toList();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_tripsKey);
    _trips.clear();
    if (stored != null) {
      final decoded = jsonDecode(stored) as List;
      _trips.addAll(
        decoded.map(
          (t) => Trip.fromJson(_migrated(t as Map<String, dynamic>)),
        ),
      );
    }
    _activeId = _prefs?.getString(_activeKey);
    _loaded = true;
    notifyListeners();
  }

  /// A stored trip from before settings became mutable, brought forward.
  ///
  /// Those versions stored the settings the user had *picked*, meaning "show
  /// only these"; muting inverts that, so a picked set becomes everything it
  /// left out. An empty pick is the exception: it meant the user skipped the
  /// question, not that they wanted nothing, so it converts to nothing muted
  /// — which is also what fixes skipping having handed out the smallest
  /// phrasebook rather than the largest.
  Map<String, dynamic> _migrated(Map<String, dynamic> json) {
    if (json.containsKey('mutedTags') || !json.containsKey('environments')) {
      return json;
    }
    final picked = ((json['environments'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet();
    return {...json, 'mutedTags': _mutedForPicked(picked).toList()};
  }

  Set<String> _mutedForPicked(Set<String> picked) => picked.isEmpty
      ? <String>{}
      : allEnvironmentTags
            .where(
              (t) =>
                  !picked.contains(t) && !picked.contains(activityParents[t]),
            )
            .toSet();

  /// Builds the first trip from the settings the pre-trips version stored,
  /// so an existing user keeps their country and settings instead of being
  /// asked again. Returns null if there was nothing to carry over.
  Trip? migrateLegacySettings(String languageCode) {
    if (_trips.isNotEmpty) return null;
    final country = _prefs?.getString(_legacyCountryKey);
    if (country == null) return null;
    final picked =
        _prefs?.getStringList(_legacyEnvironmentsKey)?.toSet() ?? <String>{};
    return add(
      Trip.create(
        languageCode: languageCode,
        country: country,
        mutedTags: _mutedForPicked(picked),
      ),
    );
  }

  Trip add(Trip trip) {
    _trips.add(trip);
    _activeId = trip.id;
    notifyListeners();
    _persist();
    return trip;
  }

  void setActive(String tripId) {
    if (_activeId == tripId) return;
    _activeId = tripId;
    notifyListeners();
    _persist();
  }

  void update(Trip trip) {
    final i = _trips.indexWhere((t) => t.id == trip.id);
    if (i == -1) return;
    _trips[i] = trip;
    notifyListeners();
    _persist();
  }

  void remove(String tripId) {
    _trips.removeWhere((t) => t.id == tripId);
    if (_activeId == tripId) _activeId = _trips.isEmpty ? null : _trips.first.id;
    notifyListeners();
    _persist();
  }

  void _persist() {
    _prefs?.setString(
      _tripsKey,
      jsonEncode(_trips.map((t) => t.toJson()).toList()),
    );
    final id = _activeId;
    if (id != null) _prefs?.setString(_activeKey, id);
  }
}
