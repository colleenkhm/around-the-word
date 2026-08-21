/// Explore-tab content: landmarks, restaurants, neighborhoods (one table,
/// `poi_type` discriminator — see the data architecture doc's
/// `points_of_interest`), plus short hand-written tips.
library;

enum PoiType { landmark, restaurant, neighborhood }

PoiType _poiTypeFromJson(String value) =>
    PoiType.values.firstWhere((e) => e.name == value);

class PointOfInterest {
  final String id;
  final PoiType poiType;
  final List<String> tags; // breakfast/lunch/dinner/coffee/bar — restaurants only
  final String name;
  final String description;
  final String? dressCode;
  final String? visitNotes;
  final double? latitude;
  final double? longitude;
  final String? cityId; // null = regional, not tied to a single profiled city

  const PointOfInterest({
    required this.id,
    required this.poiType,
    required this.tags,
    required this.name,
    required this.description,
    this.dressCode,
    this.visitNotes,
    this.latitude,
    this.longitude,
    this.cityId,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'] as String,
      poiType: _poiTypeFromJson(json['poiType'] as String),
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      name: json['name'] as String,
      description: json['description'] as String,
      dressCode: json['dressCode'] as String?,
      visitNotes: json['visitNotes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cityId: json['cityId'] as String?,
    );
  }
}

class Tip {
  final String id;
  final String title;
  final String body;
  final String? cityId;
  final String? categoryId;

  const Tip({
    required this.id,
    required this.title,
    required this.body,
    this.cityId,
    this.categoryId,
  });

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      cityId: json['cityId'] as String?,
      categoryId: json['categoryId'] as String?,
    );
  }
}
