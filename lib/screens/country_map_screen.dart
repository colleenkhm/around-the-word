import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/continent_names.dart';
import '../data/continent_zoom_bounds.dart';
import '../data/map_tap_resolution.dart';
import '../models/world_map_country.dart';
import '../state/trip_selection.dart';
import 'category_selection_screen.dart';

/// Screen 2: a real map zoomed to the selected continent, plus a text
/// search fallback — see continent_map_screen.dart's doc comment for
/// where this interaction was proven out first.
class CountryMapScreen extends StatefulWidget {
  const CountryMapScreen({super.key});

  @override
  State<CountryMapScreen> createState() => _CountryMapScreenState();
}

class _CountryMapScreenState extends State<CountryMapScreen> {
  final _transformController = TransformationController();

  List<WorldMapCountry>? _worldCountries;
  bool _didInitialZoom = false;

  @override
  void initState() {
    super.initState();
    loadWorldMapCountries().then((countries) {
      if (!mounted) return;
      final continent = context.read<TripSelection>().selectedContinent;
      setState(() {
        _worldCountries =
            countries.where((c) => c.continent == continent).toList()
              ..sort((a, b) => a.name.compareTo(b.name));
      });
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomToContinent(String continent, Size viewportSize) {
    final bounds = continentZoomBounds[continent];
    if (bounds == null) return; // no hand-computed bounds yet — stay unzoomed

    final rect = Rect.fromLTRB(
      bounds.left * mapSize.width,
      bounds.top * mapSize.height,
      bounds.right * mapSize.width,
      bounds.bottom * mapSize.height,
    );

    final scale = (viewportSize.width / rect.width)
        .clamp(0.0, viewportSize.height / rect.height);

    final matrix = Matrix4.identity()
      ..translateByDouble(viewportSize.width / 2, viewportSize.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-rect.center.dx, -rect.center.dy, 0, 1);

    _transformController.value = matrix;
  }

  void _handleTapResult(TripSelection trip, CountryTapResult result) {
    switch (result) {
      case CountryTapUnrecognized():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unrecognized region — try again.')),
        );
      case CountryTapUnavailable(:final name):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No languages available for travel to $name at the moment.'),
          ),
        );
      case CountryTapAvailable(:final country):
        trip.selectCountry(country);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CategorySelectionScreen()),
        );
    }
  }

  void _onMapTapped(TripSelection trip, String id, String name, TapUpDetails details) {
    final worldCountries = _worldCountries;
    if (worldCountries == null) return;
    _handleTapResult(
      trip,
      resolveCountryTap(
        tappedId: id,
        worldCountries: worldCountries,
        countries: trip.countries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();
    final continent = trip.selectedContinent!;
    final continentName = continentDisplayNames[continent] ?? continent;
    final worldCountries = _worldCountries;

    if (worldCountries == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(continentName)),
      body: Column(
        children: [
          // Owns its own search-text state, deliberately kept out of this
          // widget's state — SimpleMap re-parses ~290KB of embedded JSON on
          // every rebuild (no internal caching), so if the search field's
          // setState lived up here, every keystroke would rebuild — and
          // re-parse — the whole map below it too.
          _CountrySearchField(
            countries: worldCountries,
            onSelected: (country) => _handleTapResult(
              trip,
              resolveCountryTap(
                tappedId: country.id,
                worldCountries: worldCountries,
                countries: trip.countries,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!_didInitialZoom) {
                  _didInitialZoom = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _zoomToContinent(continent, constraints.biggest);
                  });
                }
                return InteractiveViewer(
                  transformationController: _transformController,
                  constrained: false,
                  minScale: 0.5,
                  maxScale: 12,
                  boundaryMargin: const EdgeInsets.all(400),
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
    );
  }
}

class _CountrySearchField extends StatefulWidget {
  const _CountrySearchField({required this.countries, required this.onSelected});

  final List<WorldMapCountry> countries;
  final ValueChanged<WorldMapCountry> onSelected;

  @override
  State<_CountrySearchField> createState() => _CountrySearchFieldState();
}

class _CountrySearchFieldState extends State<_CountrySearchField> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? const <WorldMapCountry>[]
        : widget.countries
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Search countries',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        if (results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final country = results[index];
                    return ListTile(
                      title: Text(country.name),
                      onTap: () {
                        widget.onSelected(country);
                        setState(() {
                          _query = '';
                          _controller.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
