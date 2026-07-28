import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/continent_names.dart';
import '../data/map_tap_resolution.dart';
import '../models/world_map_country.dart';
import 'country_tap_search_screen.dart';

/// Prototype: tap anywhere on the world map, resolve the tapped country to
/// its continent, then either continue (continent has active content) or
/// show a plain "not available yet" message (it doesn't). No zoom-to-fit
/// here — the whole point of this screen is picking a continent, so the
/// full world stays visible; InteractiveViewer's pinch/pan is enough on its
/// own for a prototype.
///
/// This interaction has since graduated into the real app —
/// see lib/screens/continent_map_screen.dart. Kept as a standalone demo,
/// now sharing the same resolution logic so the two can't drift apart.
class ContinentTapScreen extends StatefulWidget {
  const ContinentTapScreen({super.key});

  @override
  State<ContinentTapScreen> createState() => _ContinentTapScreenState();
}

class _ContinentTapScreenState extends State<ContinentTapScreen> {
  List<WorldMapCountry>? _worldCountries;
  Set<String>? _activeContinents;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final worldCountries = await loadWorldMapCountries();
    final countries = await ContentRepository().loadCountries();
    setState(() {
      _worldCountries = worldCountries;
      _activeContinents =
          countries.where((c) => c.active).map((c) => c.continent).toSet();
    });
  }

  void _onCountryTapped(String id, String name, TapUpDetails details) {
    final worldCountries = _worldCountries;
    final activeContinents = _activeContinents;
    if (worldCountries == null || activeContinents == null) return;

    final result = resolveContinentTap(
      tappedId: id,
      worldCountries: worldCountries,
      isContinentActive: activeContinents.contains,
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CountryTapSearchScreen(continent: continent),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_worldCountries == null || _activeContinents == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tap a continent (map prototype)')),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 8,
        child: SimpleMap(
          instructions: SMapWorld.instructions,
          defaultColor: Colors.grey.shade300,
          countryBorder: CountryBorder(color: Colors.grey.shade600, width: 0.5),
          callback: _onCountryTapped,
        ),
      ),
    );
  }
}
