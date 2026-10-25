/// A language the app can teach. Only one is wired up today
/// ([currentLanguage] in `lib/data/phrases.dart`), but lookups, storage and
/// the translation service all key off a [Language] rather than assuming
/// Spanish, so a second one can be added later without reworking those.
class Language {
  final String code;
  final String name;
  final List<String> countries;

  const Language({
    required this.code,
    required this.name,
    this.countries = const [],
  });
}
