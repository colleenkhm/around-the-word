import 'place.dart';

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
/// Independently, [environments] narrow a phrase to the kinds of setting where
/// it's useful (a hiking phrase for mountain users). Empty means any setting.
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

  /// Settings this phrase is specific to (see `environmentOptions`); empty
  /// means it's useful in any setting.
  final List<String> environments;

  const Phrase({
    required this.id,
    required this.categoryId,
    required this.english,
    required this.target,
    required this.pronunciation,
    required this.blankWord,
    this.variants = const [],
    this.countries = const [],
    this.environments = const [],
  });

  /// Whether a user in [place] should see this phrase: its country scope
  /// matches (or it's language-wide) and its setting scope matches (or it
  /// suits any setting). A place with no country chosen yet sees everything.
  bool appliesTo(Place place) {
    if (place.country == null) return true;
    final inCountry = countries.isEmpty || countries.contains(place.country);
    final inSetting =
        environments.isEmpty || environments.any(place.environments.contains);
    return inCountry && inSetting;
  }

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
  String get targetWithBlank {
    final pattern = RegExp(RegExp.escape(blankWord), caseSensitive: false);
    final match = pattern.firstMatch(target);
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
