import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_talk/data/phrases.dart';
import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/models/place.dart';

/// Asserts the blank in [blanked] stands where a whole word stood, rather
/// than inside one. Checked on the rendered output, so it holds whatever
/// [Phrase.targetWithBlank] does internally.
void expectWholeWordBlank(String blankWord, String blanked, String reason) {
  final blank = '_' * blankWord.length;
  final start = blanked.indexOf(blank);
  expect(start, isNot(-1), reason: '$reason: nothing was blanked');

  final letter = RegExp(r'[\p{L}\p{N}]', unicode: true);
  if (start > 0) {
    expect(
      letter.hasMatch(blanked[start - 1]),
      isFalse,
      reason: '$reason: the blank starts inside a word — $blanked',
    );
  }
  final end = start + blank.length;
  if (end < blanked.length) {
    expect(
      letter.hasMatch(blanked[end]),
      isFalse,
      reason: '$reason: the blank ends inside a word — $blanked',
    );
  }
}

void main() {
  test('every blank word appears as a whole word in its phrase', () {
    // `contains` alone was the weaker invariant: it passes for a blank word
    // buried inside a longer one, which is exactly the case that blanks the
    // wrong letters.
    for (final p in allPhrases) {
      expect(
        p.target.toLowerCase(),
        contains(p.blankWord.toLowerCase()),
        reason: p.id,
      );
      expectWholeWordBlank(p.blankWord, p.targetWithBlank, p.id);

      for (final v in p.variants) {
        expect(
          v.target.toLowerCase(),
          contains(v.blankWord.toLowerCase()),
          reason: '${p.id} ${v.countryLabel}',
        );
        final variant = p.forCountry(v.countries.first);
        expectWholeWordBlank(
          variant.blankWord,
          variant.targetWithBlank,
          '${p.id} ${v.countryLabel}',
        );
      }
    }
  });

  group('grading a practice answer', () {
    final propina = allPhrases.firstWhere((p) => p.id == 'food_21');
    final cafe = allPhrases.firstWhere((p) => p.blankWord == 'café');

    test('the word, accents and all, is exact', () {
      expect(cafe.grade('café'), AnswerAccuracy.exact);
      // Case and surrounding whitespace were always forgiven.
      expect(cafe.grade('  CAFÉ '), AnswerAccuracy.exact);
      expect(propina.grade('propina'), AnswerAccuracy.exact);
    });

    test('the right word without its accent scores, but is called out', () {
      // A phone keyboard makes the accent real work, and search has always
      // been accent-forgiving — practice shouldn't be the one place that
      // silently isn't.
      expect(cafe.grade('cafe'), AnswerAccuracy.accentsMissing);
      expect(cafe.grade('CAFE'), AnswerAccuracy.accentsMissing);
      expect(AnswerAccuracy.accentsMissing.isCorrect, isTrue);
    });

    test('a different word is wrong', () {
      expect(cafe.grade('agua'), AnswerAccuracy.wrong);
      expect(cafe.grade(''), AnswerAccuracy.wrong);
      expect(cafe.grade('caf'), AnswerAccuracy.wrong);
      expect(AnswerAccuracy.wrong.isCorrect, isFalse);
    });

    test('a word with no accent in it can only be exact or wrong', () {
      expect(propina.grade('propina'), AnswerAccuracy.exact);
      expect(propina.grade('propino'), AnswerAccuracy.wrong);
    });
  });

  group('blanking the practice word', () {
    Phrase withBlank(String target, String blankWord) => Phrase(
      id: 'test',
      categoryId: 'food',
      english: 'test',
      target: target,
      pronunciation: '',
      blankWord: blankWord,
    );

    test('skips a longer word the blank word is only part of', () {
      // "Esto" would match first on a plain substring search, asking the user
      // for a word that isn't the one being drilled.
      expect(
        withBlank('Esto es bueno', 'es').targetWithBlank,
        'Esto __ bueno',
      );
    });

    test('a word ending in an accented letter still matches as a whole', () {
      // The case `\b` gets wrong: it's ASCII-only, so it doesn't see a word
      // boundary after the "á" and `\bestá\b` matches nothing at all.
      expect(
        withBlank('¿Está lejos de aquí?', 'está').targetWithBlank,
        '¿____ lejos de aquí?',
      );
      expect(
        withBlank('Soy alérgico a los frutos secos', 'alérgico').targetWithBlank,
        'Soy ________ a los frutos secos',
      );
    });

    test('a one-letter word next to an accent is matched on its own', () {
      expect(
        withBlank('Soy alérgico a los frutos secos', 'a').targetWithBlank,
        'Soy alérgico _ los frutos secos',
      );
    });

    test('punctuation around a word still counts as a boundary', () {
      expect(
        withBlank('¿Esto pica?', 'pica').targetWithBlank,
        '¿Esto ____?',
      );
      expect(
        withBlank('La cuenta, por favor', 'cuenta').targetWithBlank,
        'La ______, por favor',
      );
    });

    test('a blank word buried in a longer one still blanks something', () {
      // There's no whole word to blank here, so this falls back to the old
      // substring behavior. It's a content mistake either way — the
      // whole-word invariant above fails it — but printing the sentence with
      // the answer still in it would be the worse failure.
      expect(withBlank('la parada', 'para').targetWithBlank, 'la ____da');
      expect(withBlank('Está lejos', 'est').targetWithBlank, '___á lejos');
    });
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
