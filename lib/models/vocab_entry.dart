/// A single tagged vocab entry, as produced by tools/vocab_tagger and stored
/// in assets/data/content/{countryCode}.json.
///
/// V1's UI only reads [phrase]/[translation]; the grammar tags are carried
/// through now so they don't need to be backfilled once exercises that rely
/// on them (fill-in-blank, matching) come back into scope.
class VocabEntry {
  final String phrase;
  final String translation;
  final String? partOfSpeech;
  final String? gender;
  final String? number;

  const VocabEntry({
    required this.phrase,
    required this.translation,
    this.partOfSpeech,
    this.gender,
    this.number,
  });

  factory VocabEntry.fromJson(Map<String, dynamic> json) {
    return VocabEntry(
      phrase: json['phrase'] as String,
      translation: json['translation'] as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      gender: json['gender'] as String?,
      number: json['number'] as String?,
    );
  }
}
