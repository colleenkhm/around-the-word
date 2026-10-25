import 'package:flutter_test/flutter_test.dart';

import 'package:word_travels/data/phrases.dart';
import 'package:word_travels/models/pronunciation.dart';

/// How closely the generator has to track the hand-written guides. It sits
/// at 93.6% exact / 98.1% per-word against the curated set; the floors here
/// are a little under that, so ordinary content edits don't trip the test
/// but a real regression in the rules does.
const _minExact = 0.90;
const _minWordAccuracy = 0.96;

void main() {
  group('vowels and stress', () {
    test('stress falls on the second-to-last syllable by default', () {
      expect(spanishPronunciation('mesa'), 'MEH-sah');
      expect(spanishPronunciation('tengo'), 'TEHN-goh');
    });

    test('a word ending in a consonant stresses the last syllable', () {
      expect(spanishPronunciation('favor'), 'fah-VOR');
      expect(spanishPronunciation('salud'), 'sah-LOOD');
    });

    test('a written accent overrides both', () {
      expect(spanishPronunciation('menú'), 'meh-NOO');
      expect(spanishPronunciation('dónde'), 'DOHN-deh');
    });

    test('one-syllable words are left unmarked', () {
      expect(spanishPronunciation('dos'), 'dohs');
      expect(spanishPronunciation('tren'), 'trehn');
    });

    test('a final y counts as a consonant for stress but sounds like i', () {
      expect(spanishPronunciation('soy'), 'soy');
      expect(spanishPronunciation('estoy'), 'ehs-TOY');
    });
  });

  group('consonants', () {
    test('c and g soften before e and i', () {
      expect(spanishPronunciation('receta'), 'reh-SEH-tah');
      expect(spanishPronunciation('gracias'), 'GRAH-see-ahs');
    });

    test('j sounds like h, and h is silent', () {
      expect(spanishPronunciation('lejos'), 'LEH-hohs');
      expect(spanishPronunciation('hambre'), 'AHM-breh');
    });

    test('digraphs: ll sounds like y, rr and ch keep their own sound', () {
      expect(spanishPronunciation('botella'), 'boh-TEH-yah');
      expect(spanishPronunciation('carro'), 'KAH-rroh');
      expect(spanishPronunciation('leche'), 'LEH-cheh');
    });

    test('qu and gu drop their silent u', () {
      expect(spanishPronunciation('quiero'), 'kee-EH-roh');
    });

    test('x between vowels splits across the syllable break', () {
      expect(spanishPronunciation('taxi'), 'TAHK-see');
    });
  });

  group('diphthongs', () {
    test('u glides onto the next vowel', () {
      expect(spanishPronunciation('puedo'), 'PWEH-doh');
      expect(spanishPronunciation('agua'), 'AH-gwah');
    });

    test('i takes a chunk of its own', () {
      expect(spanishPronunciation('tiene'), 'tee-EH-neh');
      expect(spanishPronunciation('delicioso'), 'deh-lee-see-OH-soh');
    });

    test('au and oi close into one sound', () {
      expect(spanishPronunciation('autobús'), 'ow-toh-BOOS');
    });
  });

  test('a whole phrase, punctuation dropped', () {
    expect(
      spanishPronunciation('¿Cuánto cuesta esto?'),
      'KWAHN-toh KWEHS-tah EHS-toh',
    );
    expect(spanishPronunciation('La cuenta, por favor'), isNotEmpty);
  });

  test('empty in, empty out', () {
    expect(spanishPronunciation(''), '');
    expect(spanishPronunciation('  ¿?  '), '');
  });

  // The curated guides are the yardstick: they're hand-written in the style
  // the generator is imitating, so they're the closest thing to ground
  // truth available. They aren't perfectly self-consistent (the same sound
  // is spelled differently in a few places), which is why these are floors
  // rather than a demand for a perfect score.
  test('tracks the hand-written guides across the curated set', () {
    var exact = 0;
    var words = 0;
    var wordHits = 0;

    for (final p in allPhrases) {
      final got = spanishPronunciation(p.target);
      if (got == p.pronunciation) exact++;

      final want = p.pronunciation.split(' ');
      final gotWords = got.split(' ');
      for (var i = 0; i < want.length; i++) {
        words++;
        if (i < gotWords.length && gotWords[i] == want[i]) wordHits++;
      }
    }

    expect(
      exact / allPhrases.length,
      greaterThanOrEqualTo(_minExact),
      reason: 'exact phrase matches dropped',
    );
    expect(
      wordHits / words,
      greaterThanOrEqualTo(_minWordAccuracy),
      reason: 'per-word accuracy dropped',
    );
  });
}
