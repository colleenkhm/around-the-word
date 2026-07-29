import 'dart:math' as math;

import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/continent_names.dart';
import '../data/continent_zoom_bounds.dart';
import '../data/map_tap_resolution.dart';
import '../models/world_map_country.dart';
import '../state/trip_selection.dart';
import 'country_map_screen.dart';

/// Screen 1: "Where are you going?" — a real, tappable world map (see
/// language-app-system-design.md section 4 and HANDOFF.md for how this
/// replaced the original placeholder list, and lib/map_prototype/ for where
/// the interaction was proven out first).
///
/// Opens zoomed out just far enough to show the whole map, biased toward
/// the bottom of the viewport rather than dead-centered — phones are much
/// taller/narrower than the map's own wide/short aspect ratio, so fitting
/// the whole map leaves a lot of empty vertical space, and centering it
/// splits that evenly above and below. Anchoring low instead pushes most of
/// it above the map (under the app bar) and leaves less at the bottom. Pan
/// and pinch-zoom past that from there. Same constrained-false-plus-
/// computed-matrix approach as CountryMapScreen's zoom-to-continent, just
/// centered on the whole map instead of one continent's bounds.
class ContinentMapScreen extends StatefulWidget {
  const ContinentMapScreen({super.key});

  @override
  State<ContinentMapScreen> createState() => _ContinentMapScreenState();
}

class _ContinentMapScreenState extends State<ContinentMapScreen> {
  // How close to the bottom edge the map's initial position is allowed to
  // sit — the actual gap is whatever's left after leaving at least this
  // much of the map's own scaled height as breathing room below it.
  static const _bottomMargin = 24.0;

  final _transformController = TransformationController();

  List<WorldMapCountry>? _worldCountries;
  bool _didInitialPosition = false;

  @override
  void initState() {
    super.initState();
    loadWorldMapCountries().then((countries) {
      if (mounted) setState(() => _worldCountries = countries);
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _positionMap(Size viewportSize, double scale) {
    final scaledHeight = mapSize.height * scale;
    // Bias the vertical anchor toward the bottom edge (minus a small
    // margin) instead of dead-centering it, but never push it up past
    // dead-center — on a viewport close to the map's own aspect ratio
    // there's little/no slack to bias in the first place.
    final centerY = math.max(
      viewportSize.height / 2,
      viewportSize.height - _bottomMargin - scaledHeight / 2,
    );
    final matrix = Matrix4.identity()
      ..translateByDouble(viewportSize.width / 2, centerY, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-mapSize.width / 2, -mapSize.height / 2, 0, 1);
    _transformController.value = matrix;
  }

  void _onMapTapped(TripSelection trip, String id, String name, TapUpDetails details) {
    final worldCountries = _worldCountries;
    if (worldCountries == null) return;

    final result = resolveContinentTap(
      tappedId: id,
      worldCountries: worldCountries,
      isContinentActive: trip.isContinentActive,
    );

    switch (result) {
      case ContinentTapUnrecognized():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unrecognized region — try again.')),
        );
      case ContinentTapUnavailable(:final continent):
        final continentName = continentDisplayNames[continent] ?? continent;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No languages available for travel to $continentName at the moment.',
            ),
          ),
        );
      case ContinentTapAvailable(:final continent):
        trip.selectContinent(continent);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CountryMapScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();

    if (trip.loadingReferenceData || _worldCountries == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Where are you going?')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          // Scale at which the whole map just fits the viewport — the
          // zoom-out floor, and also the initial scale (see _positionMap).
          final fitScale = math.min(
            viewportSize.width / mapSize.width,
            viewportSize.height / mapSize.height,
          );
          if (!_didInitialPosition) {
            _didInitialPosition = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _positionMap(viewportSize, fitScale);
            });
          }
          return InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            minScale: fitScale,
            maxScale: fitScale * 8,
            boundaryMargin: EdgeInsets.zero,
            child: SizedBox(
              width: mapSize.width,
              height: mapSize.height,
              child: SimpleMap(
                instructions: SMapWorld.instructions,
                defaultColor: Colors.grey.shade300,
                countryBorder:
                    CountryBorder(color: Colors.grey.shade600, width: 0.5),
                callback: (id, name, details) =>
                    _onMapTapped(trip, id, name, details),
              ),
            ),
          );
        },
      ),
    );
  }
}
