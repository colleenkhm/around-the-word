import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/trip.dart';
import 'package:pocket_talk/state/trips.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Trip _trip(String country, {Set<String> mutedTags = const {}}) => Trip.create(
  languageCode: currentLanguage.code,
  country: country,
  mutedTags: mutedTags,
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
    trips.add(_trip('Chile', mutedTags: {'Mountain'}));

    expect(trips.activePlace.country, 'Chile');
    expect(trips.activePlace.mutedTags, {'Mountain'});
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
    first.add(_trip('Mexico', mutedTags: {'Urban', 'Coastal'}));
    first.add(_trip('Spain'));
    first.setActive(first.trips.first.id);

    final second = Trips();
    await second.load();

    expect(second.trips.map((t) => t.country), ['Mexico', 'Spain']);
    expect(second.trips.first.mutedTags, {'Urban', 'Coastal'});
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
    test('an old set of picked settings becomes everything else muted', () async {
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
      // Picking Coastal used to mean "show me Coastal and nothing else
      // setting-specific", which is now everything but Coastal muted — its
      // activities included, since they came with it.
      final muted = trips.active!.mutedTags;
      expect(muted, isNot(contains('Coastal')));
      expect(muted, isNot(contains('Surfing')));
      expect(muted, containsAll(['Urban', 'Mountain', 'Rural', 'Hiking']));
    });

    test('an old install that skipped the question mutes nothing', () async {
      // Skipping used to leave the user with *only* the untagged phrases.
      // Carrying that over literally would mute the whole phrasebook, so the
      // empty pick is read as the non-answer it was.
      SharedPreferences.setMockInitialValues({'selected_country': 'Chile'});
      final trips = Trips();
      await trips.load();

      trips.migrateLegacySettings(currentLanguage.code);

      expect(trips.active?.mutedTags, isEmpty);
    });

    test('a trip stored before muting is converted on load', () async {
      SharedPreferences.setMockInitialValues({
        'trips': jsonEncode([
          {
            'id': 'trip_1',
            'name': 'Santiago',
            'languageCode': 'es',
            'country': 'Chile',
            'environments': ['Urban'],
          },
        ]),
      });
      final trips = Trips();
      await trips.load();

      final muted = trips.trips.single.mutedTags;
      expect(muted, isNot(contains('Urban')));
      expect(muted, isNot(contains('Public transit')));
      expect(muted, contains('Coastal'));
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
