class Country {
  final String countryCode;
  final String name;
  final String continent;
  final String languageCode;
  final bool active;

  const Country({
    required this.countryCode,
    required this.name,
    required this.continent,
    required this.languageCode,
    required this.active,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryCode: json['countryCode'] as String,
      name: json['name'] as String,
      continent: json['continent'] as String,
      languageCode: json['languageCode'] as String,
      active: json['active'] as bool,
    );
  }
}
