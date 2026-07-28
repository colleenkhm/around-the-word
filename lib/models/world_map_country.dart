import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One of the 219 countries/territories actually drawn as a tappable shape
/// on countries_world_map's `SMapWorld`. [id] is the lowercase ISO 3166-1
/// alpha-2 code — the same value `SimpleMap`'s tap callback returns, and the
/// key `SMapWorldColors.toMap()` uses.
///
/// [continent] uses our own 7-continent bucketing (see the generation notes
/// in assets/data/map/world_map_countries.json's sibling script output —
/// summarized: Caribbean + Central America count as north-america, matching
/// how Costa Rica is already treated in assets/data/countries.json), not the
/// UN geoscheme, which lumps Central America/Caribbean/South America
/// together.
class WorldMapCountry {
  final String id;
  final String name;
  final String continent;

  const WorldMapCountry({
    required this.id,
    required this.name,
    required this.continent,
  });

  factory WorldMapCountry.fromJson(Map<String, dynamic> json) {
    return WorldMapCountry(
      id: json['id'] as String,
      name: json['name'] as String,
      continent: json['continent'] as String,
    );
  }
}

Future<List<WorldMapCountry>> loadWorldMapCountries() async {
  final raw =
      await rootBundle.loadString('assets/data/map/world_map_countries.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => WorldMapCountry.fromJson(e as Map<String, dynamic>))
      .toList();
}
