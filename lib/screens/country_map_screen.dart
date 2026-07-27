import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../state/trip_selection.dart';
import 'category_selection_screen.dart';

/// Screen 2: a zoomed-in list of the selected continent's countries, plus a
/// text-search fallback. Same placeholder-list approach as the continent
/// screen — see the note there about real map rendering being separate work.
class CountryMapScreen extends StatefulWidget {
  const CountryMapScreen({super.key});

  @override
  State<CountryMapScreen> createState() => _CountryMapScreenState();
}

class _CountryMapScreenState extends State<CountryMapScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();
    final continent = trip.selectedContinent!;
    final countries = trip
        .countriesInContinent(continent)
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a country')),
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
          Expanded(
            child: ListView.separated(
              itemCount: countries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final Country country = countries[index];
                return ListTile(
                  title: Text(country.name),
                  enabled: country.active,
                  trailing:
                      country.active ? const Icon(Icons.chevron_right) : null,
                  onTap: country.active
                      ? () {
                          trip.selectCountry(country);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CategorySelectionScreen(),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
