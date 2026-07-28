import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';

import 'continent_names.dart';
import 'continent_zoom_bounds.dart';
import 'world_map_country.dart';

/// Prototype: same world map as ContinentTapScreen, but zoomed to the
/// selected continent (if we have a hand-computed bounds entry for it —
/// see continent_zoom_bounds.dart) and with a search field as a fallback
/// to tapping a shape directly. Selecting a country either way just
/// highlights it and shows its name — there's no further screen here,
/// this is purely proving out the interaction.
class CountryTapSearchScreen extends StatefulWidget {
  const CountryTapSearchScreen({super.key, required this.continent});

  final String continent;

  @override
  State<CountryTapSearchScreen> createState() =>
      _CountryTapSearchScreenState();
}

class _CountryTapSearchScreenState extends State<CountryTapSearchScreen> {
  static const _mapSize = Size(2000, 857);

  final _transformController = TransformationController();
  final _searchController = TextEditingController();

  List<WorldMapCountry>? _countries;
  String _query = '';
  WorldMapCountry? _selected;
  bool _didInitialZoom = false;

  @override
  void initState() {
    super.initState();
    loadWorldMapCountries().then((countries) {
      setState(() {
        _countries = countries
            .where((c) => c.continent == widget.continent)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      });
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _zoomToContinent(Size viewportSize) {
    final bounds = continentZoomBounds[widget.continent];
    if (bounds == null) return; // no hand-computed bounds yet — stay at default (unzoomed)

    final rect = Rect.fromLTRB(
      bounds.left * _mapSize.width,
      bounds.top * _mapSize.height,
      bounds.right * _mapSize.width,
      bounds.bottom * _mapSize.height,
    );

    final scale = (viewportSize.width / rect.width)
        .clamp(0.0, viewportSize.height / rect.height);

    final matrix = Matrix4.identity()
      ..translateByDouble(viewportSize.width / 2, viewportSize.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1)
      ..translateByDouble(-rect.center.dx, -rect.center.dy, 0, 1);

    _transformController.value = matrix;
  }

  void _selectCountry(WorldMapCountry country) {
    setState(() {
      _selected = country;
      _query = '';
      _searchController.clear();
    });
  }

  void _onMapTapped(String id, String name, TapUpDetails details) {
    final countries = _countries;
    if (countries == null) return;
    for (final c in countries) {
      if (c.id == id) {
        _selectCountry(c);
        return;
      }
    }
    // Tapped a country outside the current continent (e.g. panned/zoomed
    // out too far) — ignore rather than guess what was meant.
  }

  @override
  Widget build(BuildContext context) {
    final countries = _countries;
    final continentName =
        continentDisplayNames[widget.continent] ?? widget.continent;

    if (countries == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final results = _query.isEmpty
        ? const <WorldMapCountry>[]
        : countries
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(continentName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search countries',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text('Selected: ${_selected!.name}')),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (!_didInitialZoom) {
                      _didInitialZoom = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _zoomToContinent(constraints.biggest);
                      });
                    }
                    return InteractiveViewer(
                      transformationController: _transformController,
                      constrained: false,
                      minScale: 0.5,
                      maxScale: 12,
                      boundaryMargin: const EdgeInsets.all(400),
                      child: SizedBox(
                        width: _mapSize.width,
                        height: _mapSize.height,
                        child: SimpleMap(
                          instructions: SMapWorld.instructions,
                          defaultColor: Colors.grey.shade300,
                          countryBorder:
                              CountryBorder(color: Colors.grey.shade600, width: 0.5),
                          colors: _selected == null
                              ? null
                              : {_selected!.id: Colors.green},
                          callback: _onMapTapped,
                        ),
                      ),
                    );
                  },
                ),
                if (results.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 0,
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
                              onTap: () => _selectCountry(country),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
