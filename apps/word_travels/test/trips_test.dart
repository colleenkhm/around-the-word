import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/trip.dart';
import 'package:pocket_talk/state/trips.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Trip _trip(String country, {Set<String> environments = const {}}) => Trip.create(
  languageCode: currentLanguage.code,
  country: country,
  environments: environments,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new trip becomes the active one', () async {
    final trips = Trips();
    await trips.load();

    final mexico = trips.add(_trip('Mexico'));
    expect(trips.active?.id, mexico.id);

    final spain = trips.add(_trip('Spain'));
    expect(trips.active?.id, spain.id);

    trips.setActive(mexico.id);
    expect(trips.active?.country, 'Mexico');
  });

  test('the active trip decides what phrases are filtered by', () async {
    final trips = Trips();
    await trips.load();
    trips.add(_trip('Chile', environments: {'Mountain'}));

    expect(trips.activePlace.country, 'Chile');
    expect(trips.activePlace.environments, {'Mountain'});
  });

  test('a trip is named after its destination unless given a name', () {
    expect(_trip('Mexico').name, 'Mexico');
    expect(
      Trip.create(
        languageCode: 'es',
        country: 'Spain',
        name: 'Barcelona with Dad',
      ).name,
      'Barcelona with Dad',
    );
  });

  test('trips persist across a reload', () async {
    final first = Trips();
    await first.load();
    first.add(_trip('Mexico', environments: {'Urban', 'Coastal'}));
    first.add(_trip('Spain'));
    first.setActive(first.trips.first.id);

    final second = Trips();
    await second.load();

    expect(second.trips.map((t) => t.country), ['Mexico', 'Spain']);
    expect(second.trips.first.environments, {'Urban', 'Coastal'});
    expect(second.active?.country, 'Mexico');
  });

  test('removing the active trip falls back to another', () async {
    final trips = Trips();
    await trips.load();
    final mexico = trips.add(_trip('Mexico'));
    final spain = trips.add(_trip('Spain'));

    expect(trips.active?.id, spain.id);
    trips.remove(spain.id);

    expect(trips.trips, hasLength(1));
    expect(trips.active?.id, mexico.id);
  });

  test('trips are grouped by the language they teach', () async {
    final trips = Trips();
    await trips.load();
    trips.add(_trip('Mexico'));
    trips.add(_trip('Spain'));

    expect(trips.tripsForLanguage('es'), hasLength(2));
    expect(trips.tripsForLanguage('fr'), isEmpty);
  });

  group('carrying over a pre-trips install', () {
    test('the old country and settings become the first trip', () async {
      SharedPreferences.setMockInitialValues({
        'selected_country': 'Chile',
        'selected_environments': ['Coastal'],
      });
      final trips = Trips();
      await trips.load();

      final migrated = trips.migrateLegacySettings(currentLanguage.code);

      expect(migrated, isNotNull);
      expect(trips.trips, hasLength(1));
      expect(trips.active?.country, 'Chile');
      expect(trips.active?.environments, {'Coastal'});
    });

    test('everything already saved lands in that trip', () async {
      SharedPreferences.setMockInitialValues({
        'selected_country': 'Chile',
        'vocab_bank_phrase_ids': ['basics_1', 'basics_2'],
      });
      final trips = Trips();
      final bank = VocabBank();
      await trips.load();
      await bank.load();

      final migrated = trips.migrateLegacySettings(currentLanguage.code)!;
      bank.adoptLegacySaves(migrated.id);

      expect(bank.deckFor(migrated.id).map((p) => p.id), [
        'basics_1',
        'basics_2',
      ]);
    });

    test('a fresh install has nothing to carry over', () async {
      final trips = Trips();
      await trips.load();

      expect(trips.migrateLegacySettings(currentLanguage.code), isNull);
      expect(trips.hasTrip, isFalse);
    });

    test('an install that already has trips is left alone', () async {
      SharedPreferences.setMockInitialValues({'selected_country': 'Chile'});
      final trips = Trips();
      await trips.load();
      trips.add(_trip('Mexico'));

      expect(trips.migrateLegacySettings(currentLanguage.code), isNull);
      expect(trips.trips, hasLength(1));
      expect(trips.active?.country, 'Mexico');
    });
  });
}
