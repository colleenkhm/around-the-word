/// One journey: where you're going, what it'll be like there, and — by way
/// of the vocab bank's deck membership — the vocabulary you've gathered for
/// it.
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
  final Set<String> environments;

  const Trip({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.country,
    this.environments = const {},
  });

  /// A new trip, named after its destination unless given a name.
  factory Trip.create({
    required String languageCode,
    required String country,
    String? name,
    Set<String> environments = const {},
  }) => Trip(
    id: 'trip_${DateTime.now().microsecondsSinceEpoch}',
    name: (name == null || name.trim().isEmpty) ? country : name.trim(),
    languageCode: languageCode,
    country: country,
    environments: environments,
  );

  Trip copyWith({String? name, String? country, Set<String>? environments}) =>
      Trip(
        id: id,
        name: name ?? this.name,
        languageCode: languageCode,
        country: country ?? this.country,
        environments: environments ?? this.environments,
      );

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    name: json['name'] as String,
    languageCode: json['languageCode'] as String? ?? 'es',
    country: json['country'] as String,
    environments: ((json['environments'] as List?) ?? const [])
        .map((e) => e as String)
        .toSet(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'languageCode': languageCode,
    'country': country,
    'environments': environments.toList(),
  };
}
