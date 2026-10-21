import 'language.dart';
import 'place.dart';
import 'pronunciation.dart';

/// The [Phrase.categoryId] of a live-translated phrase. Deliberately not a
/// real category — adding it to `categories` would put a bogus tile in the
/// phrasebook grid.
const String lookupCategoryId = 'lookup';

/// A single phrase: shown as a flip card while browsing, and as a
/// fill-in-the-blank exercise once it's in the vocab bank.
///
/// [blankWord] is hand-picked per phrase (not auto-detected) — Spanish
/// articles/gender agreement make "just blank a random word" unreliable,
/// so the content word to drill is chosen deliberately.
///
/// A phrase has one of two scopes. With no [countries] it belongs to the
/// language as a whole and every user sees it; with [countries] it is
/// specific to those countries (Chilean "¿Cachai?") and only their users
/// see it.
///
/// Independently, [tags] mark the setting or activity a phrase belongs to
/// (a hiking phrase is tagged `'Hiking'`). Empty means it comes up on any
/// trip; a tagged phrase drops out only once the user mutes every tag it
/// carries.
///
/// Separately, a phrase whose wording differs by country (car: "carro" in
/// Mexico, "auto" in Chile) is flagged by giving it [variants] — one full
/// entry per country.
/// The top-level [target]/[pronunciation]/[blankWord] must repeat the first
/// variant's, since that's the one used for practice and any lookup that
/// needs a single wording (checked in test/phrases_test.dart).
class Phrase {
  final String id;
  final String categoryId;
  final String english;
  final String target;
  final String pronunciation;
  final String blankWord;
  final List<CountryVariant> variants;

  /// Countries this phrase is specific to; empty means the whole language.
  final List<String> countries;

  /// The settings or activities this phrase belongs to (see
  /// `allEnvironmentTags`); empty means it's useful on any trip.
  ///
  /// A phrase names the most specific tag that fits and only that one —
  /// `'Surfing'`, not `'Surfing'` plus its parent `'Coastal'`. Muting a
  /// setting mutes its activities alongside it, so the parent tag would be
  /// redundant, and carrying it would stop the user re-enabling one activity
  /// under a muted setting.
  final List<String> tags;

  /// The [Language.code] this phrase is in. Defaults to Spanish so none of
  /// the curated phrases below need to name it — it only matters for
  /// phrases created via [Phrase.fromLookup], to scope saved/practice data
  /// per language once a second one exists.
  final String languageCode;

  const Phrase({
    required this.id,
    required this.categoryId,
    required this.english,
    required this.target,
    required this.pronunciation,
    required this.blankWord,
    this.variants = const [],
    this.countries = const [],
    this.tags = const [],
    this.languageCode = 'es',
  });

  /// A phrase built from a live translation lookup rather than the curated
  /// set — nothing here was hand-written, so the practice [blankWord] is
  /// guessed by [autoBlankWord] and the pronunciation guide is generated on
  /// demand (see [pronunciationGuide]) rather than stored.
  factory Phrase.fromLookup({
    required String english,
    required String target,
    required Language language,
  }) {
    final normalized = normalizeForSearch(
      english,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    return Phrase(
      id: 'lookup_${language.code}_$normalized',
      categoryId: lookupCategoryId,
      english: english,
      target: target,
      pronunciation: '',
      blankWord: autoBlankWord(target),
      languageCode: language.code,
    );
  }

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    english: json['english'] as String,
    target: json['target'] as String,
    // Generated for lookups, so whatever an older version stored here is
    // ignored rather than migrated.
    pronunciation: '',
    blankWord: json['blankWord'] as String,
    languageCode: json['languageCode'] as String? ?? 'es',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'english': english,
    'target': target,
    'blankWord': blankWord,
    'languageCode': languageCode,
  };

  /// Whether this came from a live translation rather than the curated set.
  bool get isLookup => categoryId == lookupCategoryId;

  /// The pronunciation guide to show. Curated phrases have one written by
  /// hand; a looked-up phrase derives its own from [target] every time it's
  /// read, which costs microseconds and means it can never be left stale by
  /// a change to the rules that generate it.
  String get pronunciationGuide =>
      isLookup ? spanishPronunciation(target) : pronunciation;

  /// Whether this phrase exists at all for a trip to [place] — its country
  /// scope matches, or it's language-wide. A place with no country chosen
  /// yet gets everything.
  ///
  /// Muting is deliberately *not* part of this: a muted phrase is still part
  /// of the phrasebook and still turns up in search. See [isMutedIn].
  bool availableIn(Place place) {
    if (place.country == null) return true;
    return countries.isEmpty || countries.contains(place.country);
  }

  /// Whether the trip has switched this phrase off — every tag it carries is
  /// muted. Untagged phrases can never be muted; they're the language-wide
  /// core.
  ///
  /// Note it takes *every* tag: a phrase tagged for two settings survives
  /// until both are muted, so muting Coastal doesn't cost a Coastal+Mountain
  /// phrase to someone still going to the mountains.
  bool isMutedIn(Place place) =>
      tags.isNotEmpty && tags.every(place.mutedTags.contains);

  bool get variesByCountry => variants.isNotEmpty;

  /// Country label of the version practice quizzes on, if this phrase varies.
  String? get practiceCountry =>
      variesByCountry ? variants.first.countryLabel : null;

  /// This phrase as the user's [country] would say it. A phrase with a variant for
  /// [country] collapses to that variant as a plain phrase; with
  /// no country chosen (null), or no variant for it, the phrase is returned
  /// unchanged so every variant is still shown.
  Phrase forCountry(String? country) {
    if (country == null || !variesByCountry) return this;
    for (final v in variants) {
      if (v.countries.contains(country)) {
        return Phrase(
          id: id,
          categoryId: categoryId,
          english: english,
          target: v.target,
          pronunciation: v.pronunciation,
          blankWord: v.blankWord,
          // Only [variants] collapses away — the scoping carries over, so a
          // phrase stays filterable after it's been worded for a country.
          countries: countries,
          tags: tags,
          languageCode: languageCode,
        );
      }
    }
    return this;
  }

  /// Whether [query] matches this phrase as seen by [country] — English, the
  /// target wording, or any still-shown variant. This is meant for a quick,
  /// under-pressure lookup, so it's forgiving: every word of [query] must
  /// appear somewhere (in any order, so punctuation between words in the
  /// phrase doesn't break a match), accents and hyphens are ignored, and a
  /// handful of common English synonyms (see [searchSynonyms]) are tried too.
  bool matches(String query, String? country) {
    final p = forCountry(country);
    final tokens = searchTokens(query);
    if (tokens.isEmpty) return false;

    final haystacks = [
      p.english,
      p.target,
      ...p.variants.map((v) => v.target),
    ].map(normalizeForSearch).toList();

    return tokens.every((token) {
      final withSynonyms = searchSynonyms[token] ?? [token];
      return withSynonyms.any((t) => haystacks.any((h) => h.contains(t)));
    });
  }

  /// [target] with [blankWord] replaced by a blank, for the practice screen.
  ///
  /// Matches [blankWord] as a whole word. A plain substring match would blank
  /// the wrong letters as soon as the word turns up inside a longer one —
  /// blanking "es" in "Esto es bueno" would hit "Esto" first and ask for a
  /// word that isn't the one being drilled.
  ///
  /// Note the boundaries are spelled out as Unicode property escapes rather
  /// than `\b`, which (like `\w`) is ASCII-only in Dart and would treat the
  /// accented letter in "está" as a word boundary.
  String get targetWithBlank {
    final escaped = RegExp.escape(blankWord);
    const edge = r'[\p{L}\p{N}]';
    final whole = RegExp(
      '(?<!$edge)$escaped(?!$edge)',
      caseSensitive: false,
      unicode: true,
    );
    // Falls back to a substring match rather than giving up: a blank word
    // that only ever appears inside a longer one is a content mistake
    // (phrases_test.dart fails it), and blanking the wrong letters is still
    // a better failure than printing the sentence with the answer in it.
    final match =
        whole.firstMatch(target) ??
        RegExp(escaped, caseSensitive: false).firstMatch(target);
    if (match == null) return target;
    final blank = '_' * blankWord.length;
    return target.replaceRange(match.start, match.end, blank);
  }

  bool checkAnswer(String attempt) {
    return _normalize(attempt) == _normalize(blankWord);
  }

  static String _normalize(String s) => s.trim().toLowerCase();
}

/// One country's wording of a phrase, e.g. Chile: "¿Dónde puedo arrendar un auto?".
/// One variant can cover several [countries] that share the wording. Each must
/// be listed in `spanishCountries` (checked in test/phrases_test.dart).
class CountryVariant {
  final List<String> countries;
  final String target;
  final String pronunciation;
  final String blankWord;

  const CountryVariant({
    required this.countries,
    required this.target,
    required this.pronunciation,
    required this.blankWord,
  });

  String get countryLabel => countries.join(', ');
}

/// Common short Spanish function words — articles, prepositions, pronouns —
/// that make poor blank-word choices even though they're often the
/// shortest, most frequent words in a sentence.
const Set<String> _blankWordStopwords = {
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
  'de', 'del', 'a', 'al', 'en', 'con', 'sin', 'por', 'para',
  'y', 'o', 'que', 'es', 'son', 'esta', 'este', 'estan',
  'lo', 'le', 'les', 'se', 'su', 'sus', 'mi', 'mis', 'tu', 'tus',
  'yo', 'me', 'te',
};

/// Guesses which word of a live-translated [target] sentence is worth
/// drilling in practice, since (unlike the curated set) nothing hand-picked
/// one: the longest word that isn't a common function word, since that's
/// usually the content word carrying the sentence's meaning. Falls back to
/// the last word if every word got filtered out.
String autoBlankWord(String target) {
  // Strips surrounding punctuation (¿ ? ¡ ! , . ...) by matching anything
  // that isn't a letter or digit. Has to be the Unicode property escape,
  // not \w — \w is ASCII-only, so it would eat the accented letter off the
  // end of "está" or "café".
  final words = target
      .split(RegExp(r'\s+'))
      .map(
        (w) => w.replaceAll(
          RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
          '',
        ),
      )
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return target;

  final candidates = words
      .where((w) => !_blankWordStopwords.contains(normalizeForSearch(w)))
      .toList();
  final pool = candidates.isNotEmpty ? candidates : words;

  return pool.reduce((a, b) => b.length > a.length ? b : a);
}

const Map<String, String> _searchAccents = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

/// Lowercases, drops accents (so "bano" finds "baño" on a keyboard with no
/// accent keys) and hyphens (so "checkout" finds "check-out"), for both the
/// query and the phrase text it's compared against.
String normalizeForSearch(String s) {
  var out = s.toLowerCase().replaceAll('-', '');
  for (final entry in _searchAccents.entries) {
    out = out.replaceAll(entry.key, entry.value);
  }
  return out;
}

/// Splits a search query into normalized words. A phrase matches when every
/// token is found somewhere (see [Phrase.matches]) — so word order, and
/// punctuation in the phrase between words, doesn't matter: "check please"
/// still finds "The check, please".
List<String> searchTokens(String query) => normalizeForSearch(
  query,
).trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

/// Common English words travelers might type instead of the word a phrase
/// actually uses — e.g. searching "bathroom" should still find "restroom".
/// Built from these groups: every word in a group is treated as
/// interchangeable with every other word in it.
final Map<String, List<String>> searchSynonyms = _buildSynonyms([
  ['restroom', 'bathroom', 'toilet', 'washroom'],
  ['taxi', 'cab'],
  ['hospital', 'er'],
  ['pharmacy', 'drugstore'],
  ['check', 'bill'],
  ['subway', 'metro'],
  ['cost', 'price', 'how much'],
  ['stolen', 'robbed'],
  ['sick', 'ill'],
  ['reservation', 'booking'],
  ['wallet', 'purse'],
  ['petrol', 'gas'],
  ['cashpoint', 'atm'],
  ['wifi', 'internet'],
]);

Map<String, List<String>> _buildSynonyms(List<List<String>> groups) {
  final map = <String, List<String>>{};
  for (final group in groups) {
    for (final word in group) {
      map[word] = group;
    }
  }
  return map;
}
