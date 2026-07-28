import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/continent_names.dart';
import '../data/map_tap_resolution.dart';
import '../models/world_map_country.dart';
import '../state/trip_selection.dart';
import 'country_map_screen.dart';

/// Screen 1: "Where are you going?" — a real, tappable world map (see
/// language-app-system-design.md section 4 and HANDOFF.md for how this
/// replaced the original placeholder list, and lib/map_prototype/ for where
/// the interaction was proven out first).
class ContinentMapScreen extends StatefulWidget {
  const ContinentMapScreen({super.key});

  @override
  State<ContinentMapScreen> createState() => _ContinentMapScreenState();
}

class _ContinentMapScreenState extends State<ContinentMapScreen> {
  List<WorldMapCountry>? _worldCountries;

  @override
  void initState() {
    super.initState();
    loadWorldMapCountries().then((countries) {
      if (mounted) setState(() => _worldCountries = countries);
    });
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
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 8,
        child: SimpleMap(
          instructions: SMapWorld.instructions,
          defaultColor: Colors.grey.shade300,
          countryBorder: CountryBorder(color: Colors.grey.shade600, width: 0.5),
          callback: (id, name, details) => _onMapTapped(trip, id, name, details),
        ),
      ),
    );
  }
}
