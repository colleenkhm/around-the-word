import 'dart:ui' show Rect, Size;

/// Native pixel size of the world map SimpleMap draws (from the package's
/// embedded instructions' "w"/"h" fields) — shared by both map screens so
/// zoom/pan math has a single source of truth for the map's coordinate space.
const mapSize = Size(2000, 857);

/// Hand-computed (not runtime-computed) bounding box per continent, as
/// fractions (0..1) of the map's drawable area — matches the coordinate
/// space countries_world_map's SimpleMap already draws in, so no rendered
/// pixel size is needed to store these, only to apply them.
///
/// Computed once by parsing countries_world_map's own path data for every
/// country tagged with that continent (see world_map_country.dart's continent
/// bucketing) and taking the min/max of all points. Deliberately not done at
/// runtime or generalized to all 7 continents — only the continents with
/// active content need one; add more here as they come online.
const continentZoomBounds = <String, Rect>{
  'north-america': Rect.fromLTRB(0.0498, 0.0012, 0.4722, 0.5315),
};
