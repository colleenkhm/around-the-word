import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:word_travels/data/phrases.dart';
import 'package:word_travels/models/phrase.dart';
import 'package:word_travels/state/vocab_bank.dart';

const _mexico = 'trip_mexico';
const _spain = 'trip_spain';

Phrase _lookup(String english, String target) => Phrase.fromLookup(
  english: english,
  target: target,
  language: currentLanguage,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saving puts a phrase in one trip\'s deck', () {
    final bank = VocabBank()..toggle('basics_1', _mexico);

    expect(bank.deckFor(_mexico).map((p) => p.id), ['basics_1']);
    expect(bank.deckFor(_spain), isEmpty);
    expect(bank.isInTrip('basics_1', _mexico), isTrue);
    expect(bank.isInTrip('basics_1', _spain), isFalse);
  });

  test('toggling again removes it', () {
    final bank = VocabBank()
      ..toggle('basics_1', _mexico)
      ..toggle('basics_1', _mexico);

    expect(bank.deckFor(_mexico), isEmpty);
    expect(bank.isSaved('basics_1'), isFalse);
  });

  group('a phrase shared between trips', () {
    test('is one phrase in two decks, not a copy each', () {
      final bank = VocabBank()
        ..toggle('basics_1', _mexico)
        ..toggle('basics_1', _spain);

      expect(bank.deckFor(_mexico).map((p) => p.id), ['basics_1']);
      expect(bank.deckFor(_spain).map((p) => p.id), ['basics_1']);
      // The umbrella covering both shows it once, not twice — which is why
      // its practice score stays a single number.
      expect(bank.deckForTrips([_mexico, _spain]).map((p) => p.id), [
        'basics_1',
      ]);
    });

    test('removing it from one trip leaves it in the other', () {
      final bank = VocabBank()
        ..toggle('basics_1', _mexico)
        ..toggle('basics_1', _spain)
        ..toggle('basics_1', _mexico);

      expect(bank.deckFor(_mexico), isEmpty);
      expect(bank.deckFor(_spain).map((p) => p.id), ['basics_1']);
      expect(bank.isSaved('basics_1'), isTrue);
    });

    test('looking it up again for a second trip adds membership', () {
      final phrase = _lookup('my flight was delayed', 'mi vuelo se ha retrasado');
      final bank = VocabBank()
        ..saveLookup(phrase, _mexico)
        ..saveLookup(phrase, _spain);

      expect(bank.deckFor(_mexico), hasLength(1));
      expect(bank.deckFor(_spain), hasLength(1));
      expect(bank.savedPhrases, hasLength(1));
    });
  });

  group('deleting a trip', () {
    test('takes the vocabulary saved only to it', () {
      final bank = VocabBank()
        ..toggle('basics_1', _mexico)
        ..saveLookup(_lookup('hello there', 'hola'), _mexico);

      bank.removeTrip(_mexico);

      expect(bank.deckFor(_mexico), isEmpty);
      expect(bank.savedPhrases, isEmpty);
    });

    test('leaves phrases that another trip also holds', () {
      final shared = _lookup('my flight was delayed', 'mi vuelo se ha retrasado');
      final bank = VocabBank()
        ..toggle('basics_1', _mexico)
        ..toggle('basics_1', _spain)
        ..saveLookup(shared, _mexico)
        ..saveLookup(shared, _spain)
        ..toggle('basics_2', _mexico); // Mexico only

      bank.removeTrip(_mexico);

      expect(bank.deckFor(_spain).map((p) => p.id), contains('basics_1'));
      expect(bank.deckFor(_spain).map((p) => p.id), contains(shared.id));
      expect(bank.deckFor(_spain).map((p) => p.id), isNot(contains('basics_2')));
      // The shared lookup keeps its content, since it's still reachable.
      expect(bank.dynamicPhrase(shared.id)?.target, 'mi vuelo se ha retrasado');
    });
  });

  test('decks persist across a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final first = VocabBank();
    await first.load();
    first.toggle('basics_1', _mexico);
    first.saveLookup(_lookup('hello there', 'hola'), _spain);

    final second = VocabBank();
    await second.load();

    expect(second.deckFor(_mexico).map((p) => p.id), ['basics_1']);
    expect(second.deckFor(_spain).map((p) => p.target), ['hola']);
  });
}
