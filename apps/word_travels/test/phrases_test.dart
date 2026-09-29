import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/models/place.dart';

void main() {
  test('every blank word appears in its phrase', () {
    for (final p in allPhrases) {
      expect(
        p.target.toLowerCase(),
        contains(p.blankWord.toLowerCase()),
        reason: p.id,
      );
      for (final v in p.variants) {
        expect(
          v.target.toLowerCase(),
          contains(v.blankWord.toLowerCase()),
          reason: '${p.id} ${v.countryLabel}',
        );
      }
    }
  });

  test('phrases with variants repeat their first variant as the default', () {
    for (final p in allPhrases.where((p) => p.variesByCountry)) {
      final first = p.variants.first;
      expect(p.target, first.target, reason: p.id);
      expect(p.pronunciation, first.pronunciation, reason: p.id);
      expect(p.blankWord, first.blankWord, reason: p.id);
      expect(p.variants.length, greaterThan(1), reason: p.id);
    }
  });

  test('variant countries come from the selectable country list', () {
    for (final p in allPhrases) {
      for (final v in p.variants) {
        expect(spanishCountries, containsAll(v.countries), reason: p.id);
      }
    }
  });

  test('forCountry picks the country\'s wording, else keeps every variant', () {
    final car = allPhrases.firstWhere((p) => p.id == 'transportation_15');
    expect(car.forCountry('Chile').blankWord, 'auto');
    expect(car.forCountry('Chile').variesByCountry, isFalse);
    expect(car.forCountry(null).variants.length, 3);
    expect(car.forCountry('Argentina').variants.length, 3);
    expect(allPhrases.first.forCountry('Chile'), same(allPhrases.first));
  });

  test('country-specific phrases only name selectable countries', () {
    for (final p in allPhrases) {
      expect(spanishCountries, containsAll(p.countries), reason: p.id);
    }
  });

  test('users see language-wide phrases plus their own country\'s', () {
    final chile = phrasesForPlace(const Place('Chile')).map((p) => p.id).toSet();
    expect(chile, contains('basics_1'));
    expect(chile, contains('conversation_24'));
    expect(chile, isNot(contains('conversation_21')));
    expect(phrasesForPlace(const Place('Mexico')).map((p) => p.id), contains('conversation_21'));
  });

  test('phrases only name selectable settings or activities', () {
    for (final p in allPhrases) {
      expect(allEnvironmentTags, containsAll(p.tags), reason: p.id);
    }
  });

  test('a phrase names one tag, not an activity and its setting', () {
    for (final p in allPhrases) {
      for (final tag in p.tags) {
        final parent = activityParents[tag];
        expect(
          parent == null || !p.tags.contains(parent),
          isTrue,
          reason: '${p.id} names both $tag and its setting $parent',
        );
      }
    }
  });

  test('every activity has phrases behind it', () {
    for (final tag in activityParents.keys) {
      expect(
        allPhrases.where((p) => p.tags.contains(tag)),
        isNotEmpty,
        reason: '$tag is offered as a toggle but filters nothing',
      );
    }
  });

  test('a new trip mutes nothing and sees the whole phrasebook', () {
    final all = phrasesForPlace(const Place('Chile')).map((p) => p.id).toSet();
    expect(all, contains('basics_1'));
    expect(all, contains('transportation_19')); // Public transit
    expect(all, contains('activities_11')); // Surfing
  });

  test('muting a tag drops its phrases from what the trip is shown', () {
    ids(Place place) => phrasesForPlace(place).map((p) => p.id).toSet();
    expect(ids(const Place('Chile', {'Surfing'})), isNot(contains('activities_11')));
    expect(ids(const Place('Chile', {'Surfing'})), contains('activities_13'));
    // Untagged phrases are the language-wide core; muting can't reach them.
    expect(ids(const Place('Chile', {'Surfing'})), contains('basics_1'));
  });

  test('a muted phrase is still in the book, so search can find it', () {
    final place = const Place('Chile', {'Surfing'});
    expect(
      phrasesForCountry(place).map((p) => p.id),
      contains('activities_11'),
    );
  });

  test('a phrase survives until every tag it carries is muted', () {
    // health_15 (sunscreen) is tagged for both Coastal and Mountain.
    final p = allPhrases.firstWhere((p) => p.id == 'health_15');
    expect(p.isMutedIn(const Place('Chile', {'Coastal'})), isFalse);
    expect(p.isMutedIn(const Place('Chile', {'Coastal', 'Mountain'})), isTrue);
  });

  test('country scope still applies regardless of muting', () {
    final p = allPhrases.firstWhere((p) => p.id == 'conversation_24');
    expect(p.availableIn(const Place('Chile')), isTrue);
    expect(p.availableIn(const Place('Mexico')), isFalse);
  });

  test('muting a setting mutes the activities under it', () {
    final muted = withActivitiesMuted({'Coastal'});
    expect(muted, containsAll(['Coastal', 'Surfing', 'Boats & ferries']));
    expect(muted, isNot(contains('Hiking')));
  });

  test('phrase ids are unique', () {
    expect(allPhrases.map((p) => p.id).toSet().length, allPhrases.length);
  });

  group('forgiving search', () {
    Phrase byId(String id) => allPhrases.firstWhere((p) => p.id == id);

    test('an English synonym finds the phrase that uses the other word', () {
      final restroom = byId('basics_10'); // "Where is the restroom?"
      expect(restroom.matches('bathroom', null), isTrue);
      expect(restroom.matches('toilet', null), isTrue);

      final bill = byId('food_19'); // "Can we split the bill?"
      expect(bill.matches('check', null), isTrue);
      final check = byId('food_1'); // "The check, please"
      expect(check.matches('bill', null), isTrue);
    });

    test('punctuation in the phrase doesn\'t block a multi-word search', () {
      // "The check, please" — searching without the comma should still hit.
      expect(byId('food_1').matches('check please', null), isTrue);
    });

    test('accents are optional when searching Spanish', () {
      // "¿Dónde está el baño?"
      expect(byId('basics_10').matches('bano', null), isTrue);
      expect(byId('basics_10').matches('baño', null), isTrue);
    });

    test('hyphens are ignored', () {
      final checkout = allPhrases.firstWhere(
        (p) => p.english == 'What time is check-out?',
      );
      expect(checkout.matches('checkout', null), isTrue);
    });

    test('every query word has to match somewhere', () {
      final restroom = byId('basics_10');
      expect(restroom.matches('restroom please', null), isFalse);
    });

    test('an empty or blank query matches nothing', () {
      expect(byId('basics_10').matches('', null), isFalse);
      expect(byId('basics_10').matches('   ', null), isFalse);
    });
  });
}
