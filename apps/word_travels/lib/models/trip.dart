/// One journey: where you're going, what you won't be doing there, and — by
/// way of the vocab bank's deck membership — the vocabulary you've gathered
/// for it.
///
/// The destination and settings live here rather than in global settings
/// because they're properties of a journey, not of the language: two trips
/// to different countries should see different wording (`carro` in Mexico,
/// `auto` in Chile) without one overwriting the other.
class Trip {
  final String id;
  final String name;
  final String languageCode;
  final String country;

  /// Settings and activities switched off for this trip, so their phrases
  /// stay out of the practice deck.
  ///
  /// Stored as what's *muted* rather than what's chosen, so that a setting
  /// or activity added in a later version is on by default for trips that
  /// already exist — a stored list of choices would silently never mention
  /// it. Empty, the default, means the whole phrasebook is in play.
  final Set<String> mutedTags;

  const Trip({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.country,
    this.mutedTags = const {},
  });

  /// A new trip, named after its destination unless given a name.
  factory Trip.create({
    required String languageCode,
    required String country,
    String? name,
    Set<String> mutedTags = const {},
  }) => Trip(
    id: 'trip_${DateTime.now().microsecondsSinceEpoch}',
    name: (name == null || name.trim().isEmpty) ? country : name.trim(),
    languageCode: languageCode,
    country: country,
    mutedTags: mutedTags,
  );

  Trip copyWith({String? name, String? country, Set<String>? mutedTags}) =>
      Trip(
        id: id,
        name: name ?? this.name,
        languageCode: languageCode,
        country: country ?? this.country,
        mutedTags: mutedTags ?? this.mutedTags,
      );

  /// Expects [json] to already name `mutedTags` — a trip stored by a version
  /// that listed chosen settings instead is converted on load, in
  /// `Trips.load`, which is where the tag vocabulary is in scope.
  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    name: json['name'] as String,
    languageCode: json['languageCode'] as String? ?? 'es',
    country: json['country'] as String,
    mutedTags: ((json['mutedTags'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'languageCode': languageCode,
    'country': country,
    'mutedTags': mutedTags.toList(),
  };
}
