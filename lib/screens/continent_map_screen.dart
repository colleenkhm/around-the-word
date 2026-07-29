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
import 'about_screen.dart';
import 'country_map_screen.dart';
import 'resources_screen.dart';

/// Screen 1: "Where are you going?" — a real, tappable world map (see
/// language-app-system-design.md section 4 and HANDOFF.md for how this
/// replaced the original placeholder list, and lib/map_prototype/ for where
/// the interaction was proven out first).
///
/// Opens zoomed out just far enough to show the whole map, centered in the
/// viewport. Pan and pinch-zoom past that from there. Same
/// constrained-false-plus-computed-matrix approach as CountryMapScreen's
/// zoom-to-continent, just centered on the whole map instead of one
/// continent's bounds.
///
/// This is the app's landing screen, so it's the one place (not the other
/// four screens in the flow) that carries the About/Resources header nav
/// instead of a plain AppBar.
class ContinentMapScreen extends StatefulWidget {
  const ContinentMapScreen({super.key});

  @override
  State<ContinentMapScreen> createState() => _ContinentMapScreenState();
}

class _ContinentMapScreenState extends State<ContinentMapScreen> {
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
    final matrix = Matrix4.identity()
      ..translateByDouble(viewportSize.width / 2, viewportSize.height / 2, 0, 1)
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
      tapPosition: Offset(
        details.localPosition.dx / mapSize.width,
        details.localPosition.dy / mapSize.height,
      ),
      fallbackBounds: centralAmericaFallbackBounds,
      fallbackContinent: 'north-america',
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    ),
                    child: const Text('About'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ResourcesScreen()),
                    ),
                    child: const Text('Resources'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Where are you going?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportSize = constraints.biggest;
                  // Scale at which the whole map just fits the viewport —
                  // the zoom-out floor, and also the initial scale (see
                  // _positionMap).
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
            ),
          ],
        ),
      ),
    );
  }
}
