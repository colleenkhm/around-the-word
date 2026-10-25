/// Generates a plain-English pronunciation guide for Spanish text, in the
/// same house style as the curated phrases (`OO-nah MEH-sah PAH-rah dohs`):
/// syllables hyphenated, the stressed one in caps.
///
/// This is rules, not a dictionary — Spanish spelling maps onto sound
/// regularly enough that a few hundred lines covers it, which is why it can
/// run locally the instant a translation comes back rather than needing an
/// API or a word list. It is language-specific by nature: another language
/// needs its own implementation, and English would need a real pronouncing
/// dictionary rather than rules.
library;

const _accentedToPlain = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
};

const _vowels = 'aeiouáéíóúü';
const _accented = 'áéíóú';

/// Weak vowels form a diphthong with a neighbour; two strong vowels don't
/// (they're a hiatus, i.e. two syllables), and an accented weak vowel
/// behaves as strong.
const _weak = 'iuü';

/// Consonant pairs that never split across a syllable boundary.
const _inseparable = {
  'pr', 'br', 'fr', 'tr', 'dr', 'cr', 'gr',
  'pl', 'bl', 'fl', 'cl', 'gl',
};

/// Short function words the curated guides leave in plain spelling, since
/// they already read correctly to an English eye.
const _asSpelled = {'el', 'del', 'al'};

String _stripAccent(String c) => _accentedToPlain[c] ?? c;

bool _isVowel(String c) => _vowels.contains(c);

bool _isWeak(String c) => _weak.contains(c);

bool _isAccented(String c) => _accented.contains(c);

/// A pronunciation guide for [text], or an empty string if there's nothing
/// pronounceable in it.
String spanishPronunciation(String text) {
  final words = text
      .split(RegExp(r'\s+'))
      .map(_stripPunctuation)
      .where((w) => w.isNotEmpty)
      .map(_word)
      .where((w) => w.isNotEmpty)
      .toList();
  return words.join(' ');
}

String _stripPunctuation(String w) => w.replaceAll(
  RegExp(r'^[^\p{L}]+|[^\p{L}]+$', unicode: true),
  '',
);

String _word(String raw) {
  final word = raw.toLowerCase();
  if (_asSpelled.contains(word)) return word;
  if (word == 'y') return 'ee';

  // A final `y` after a vowel is really the vowel `i` (soy, estoy, hay).
  final normalized = word.length > 1 &&
          word.endsWith('y') &&
          _isVowel(word[word.length - 2])
      ? '${word.substring(0, word.length - 1)}i'
      : word;

  final units = _toUnits(normalized);
  final syllables = _syllabify(units);
  if (syllables.isEmpty) return '';

  // Stress is judged on the original spelling: a word ending in `y` counts
  // as consonant-final and stresses its last syllable (es-TOY), even though
  // that `y` sounds like a vowel.
  final stress = _stressIndex(syllables, word);
  final parts = <String>[];
  for (var i = 0; i < syllables.length; i++) {
    parts.add(_render(syllables[i], stressed: i == stress));
  }
  final joined = parts.join('-');

  // A one-syllable word is normally left unmarked, but when its vowel
  // splits into two written chunks (bien → bee-EHN) one of them still has
  // to carry the stress.
  if (syllables.length == 1 && joined.contains('-')) {
    return _render(syllables.single, stressed: true);
  }
  return joined;
}

/// Splits a word into sound units, keeping digraphs together so later steps
/// treat `ch`/`ll`/`rr` as one consonant and don't mistake the silent `u` of
/// `qu`/`gu` for a vowel.
List<String> _toUnits(String word) {
  final units = <String>[];
  for (var i = 0; i < word.length; i++) {
    final c = word[i];
    final next = i + 1 < word.length ? word[i + 1] : '';
    final after = i + 2 < word.length ? word[i + 2] : '';

    if ((c == 'c' && next == 'h') || (c == 'l' && next == 'l') || (c == 'r' && next == 'r')) {
      units.add(c + next);
      i++;
      continue;
    }
    // Between vowels, `x` is two sounds that straddle the syllable break:
    // taxi → TAHK-see.
    if (c == 'x' && units.isNotEmpty && _isVowel(units.last) && _isVowel(next)) {
      units.addAll(['k', 's']);
      continue;
    }
    // qu/gu before e or i: the u is silent, so it isn't a vowel here.
    if ((c == 'q' || c == 'g') && next == 'u' && 'eéií'.contains(after)) {
      units.add(c + next);
      i++;
      continue;
    }
    units.add(c);
  }
  return units;
}

/// Groups units into syllables: find the vowel nuclei, then hand the
/// consonants between them to the following syllable unless they have to
/// split.
List<List<String>> _syllabify(List<String> units) {
  final nuclei = <List<int>>[]; // index spans of each vowel nucleus
  var i = 0;
  while (i < units.length) {
    if (!_isVowel(units[i])) {
      i++;
      continue;
    }
    final group = <int>[i];
    var j = i + 1;
    while (j < units.length && _isVowel(units[j])) {
      group.add(j);
      j++;
    }
    nuclei.addAll(_splitVowelGroup(units, group));
    i = j;
  }
  if (nuclei.isEmpty) return const [];

  // Each syllable runs from after the previous nucleus's consonants to the
  // end of its own nucleus, plus whatever coda it keeps.
  final bounds = <int>[0];
  for (var n = 0; n < nuclei.length - 1; n++) {
    final gapStart = nuclei[n].last + 1;
    final gapEnd = nuclei[n + 1].first; // exclusive
    bounds.add(gapStart + _codaLength(units, gapStart, gapEnd));
  }
  bounds.add(units.length);

  final syllables = <List<String>>[];
  for (var s = 0; s < bounds.length - 1; s++) {
    syllables.add(units.sublist(bounds[s], bounds[s + 1]));
  }
  return syllables;
}

/// How many of the consonants between two nuclei stay with the first
/// syllable.
int _codaLength(List<String> units, int start, int end) {
  final count = end - start;
  if (count <= 1) return 0; // a lone consonant opens the next syllable
  if (count == 2) {
    final pair = units[start] + units[start + 1];
    // ch/ll/rr are single units, so a two-unit run is only inseparable if
    // it's one of the stop+liquid clusters.
    return _inseparable.contains(pair) ? 0 : 1;
  }
  if (count == 3) {
    final lastTwo = units[start + 1] + units[start + 2];
    return _inseparable.contains(lastTwo) ? 1 : 2;
  }
  return count - 2;
}

/// Splits a run of adjacent vowels into one or more nuclei: diphthongs stay
/// together, hiatus (two strong vowels, or an accented weak one) breaks.
List<List<int>> _splitVowelGroup(List<String> units, List<int> group) {
  final out = <List<int>>[];
  var current = <int>[group.first];
  for (var k = 1; k < group.length; k++) {
    final prev = units[group[k - 1]];
    final here = units[group[k]];
    final bothStrong = !_isWeak(prev) && !_isWeak(here);
    final accentedWeak =
        (_isWeak(here) && _isAccented(here)) || (_isWeak(prev) && _isAccented(prev));
    if (bothStrong || accentedWeak) {
      out.add(current);
      current = [group[k]];
    } else {
      current.add(group[k]);
    }
  }
  out.add(current);
  return out;
}

/// Which syllable carries the stress: a written accent wins, otherwise a
/// word ending in a vowel, `n` or `s` stresses the second-to-last and
/// anything else the last.
int _stressIndex(List<List<String>> syllables, String word) {
  // A one-syllable word carries the stress by default, but the curated
  // guides don't shout it — `dohs`, `keh`, `trehn` all stay lowercase — so
  // there's no syllable to mark.
  if (syllables.length == 1) return -1;
  for (var i = 0; i < syllables.length; i++) {
    if (syllables[i].any((u) => u.split('').any(_isAccented))) return i;
  }
  final last = word[word.length - 1];
  final penultimate = _isVowel(last) || last == 'n' || last == 's';
  return penultimate ? syllables.length - 2 : syllables.length - 1;
}

/// Spells one syllable the way the curated guides do. A syllable built on
/// `i` + another vowel is written as two chunks (`tie` → `tee-EH`), which
/// is why this can return a hyphenated string.
String _render(List<String> units, {required bool stressed}) {
  final firstVowel = units.indexWhere(_isVowel);
  if (firstVowel == -1) return units.join(); // no vowel: spell it out

  var lastVowel = firstVowel;
  while (lastVowel + 1 < units.length && _isVowel(units[lastVowel + 1])) {
    lastVowel++;
  }

  final onset = units.sublist(0, firstVowel);
  final nucleus = units.sublist(firstVowel, lastVowel + 1);
  final coda = units.sublist(lastVowel + 1);

  final nucleusStart = nucleus.first;
  final onsetText = [
    for (var i = 0; i < onset.length; i++)
      _consonant(onset[i], i == onset.length - 1 ? nucleusStart : onset[i + 1]),
  ].join();
  final codaText = [for (final c in coda) _consonant(c, '')].join();

  final vowelText = _nucleus(nucleus, coda: coda.isEmpty ? '' : coda.first);

  if (vowelText.contains('|')) {
    // Split nucleus: the consonants before it ride with the first chunk,
    // the coda with the second, and only the second takes the stress.
    final halves = vowelText.split('|');
    final head = '$onsetText${halves[0]}';
    final tail = '${halves[1]}$codaText';
    return '$head-${stressed ? tail.toUpperCase() : tail}';
  }

  final text = '$onsetText$vowelText$codaText';
  return stressed ? text.toUpperCase() : text;
}

const _plainVowel = {'a': 'ah', 'e': 'eh', 'i': 'ee', 'o': 'oh', 'u': 'oo'};

/// Spells a vowel nucleus. A `|` in the result marks where a rising
/// diphthong on `i` splits into two written chunks.
String _nucleus(List<String> units, {required String coda}) {
  final letters = units.map((u) => _stripAccent(u)).toList();

  if (letters.length >= 2) {
    final a = letters[0];
    final b = letters[1];
    // u + vowel glides: ua → wah, ue → weh.
    if (a == 'u' && b != 'u') {
      return 'w${_bare(b, coda: coda)}';
    }
    // i + vowel: written as its own chunk, e.g. tiene → tee-EH-neh.
    if (a == 'i' && b != 'i') {
      return 'ee|${_bare(b, coda: coda)}';
    }
    // vowel + u/i glides: au → ow, oi → oy.
    if (b == 'u') return a == 'a' ? 'ow' : '${_bare(a, coda: '')}oo';
    if (b == 'i') {
      if (a == 'o') return 'oy';
      return a == 'a' ? 'eye' : 'ay';
    }
  }

  return _bare(letters.first, coda: coda);
}

/// The bare vowel sound. `a` and `o` closed by `r` drop the `h` — `por`,
/// `KAR-neh` rather than `pohr`, `KAHR-neh`.
String _bare(String vowel, {required String coda}) {
  final rClosed = coda == 'r' || coda == 'rr';
  if (rClosed && (vowel == 'a' || vowel == 'o')) return vowel;
  return _plainVowel[vowel] ?? vowel;
}

String _consonant(String unit, String next) {
  final soft = next.isNotEmpty && 'eéií'.contains(next);
  switch (unit) {
    case 'ch':
      return 'ch';
    case 'll':
      return 'y';
    case 'rr':
      return 'rr';
    case 'qu':
      return 'k';
    case 'gu':
      return 'g';
    case 'c':
      return soft ? 's' : 'k';
    case 'g':
      return soft ? 'h' : 'g';
    case 'z':
      return 's';
    case 'j':
      return 'h';
    case 'h':
      return '';
    case 'ñ':
      return 'ny';
    case 'x':
      return 'ks';
    case 'q':
      return 'k';
    case 'ü':
      return 'w';
    default:
      return unit;
  }
}
