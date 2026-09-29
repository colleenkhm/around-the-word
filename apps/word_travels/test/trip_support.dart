import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/trip.dart';
import 'package:pocket_talk/state/trips.dart';

/// A [Trips] holding one trip, for screens that need somewhere to save to.
/// Not loaded from storage — `load()` isn't called, so nothing persists and
/// each test starts clean.
Trips tripsWithOne({
  String country = 'Mexico',
  Set<String> mutedTags = const {},
  String? name,
}) {
  return Trips()
    ..add(
      Trip.create(
        languageCode: currentLanguage.code,
        country: country,
        mutedTags: mutedTags,
        name: name,
      ),
    );
}

/// The id of the only (or first) trip — what deck-membership calls take.
String onlyTripId(Trips trips) => trips.trips.first.id;
