import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../state/trip_selection.dart';
import 'category_selection_screen.dart';
import 'coming_soon_screen.dart';

/// Screen 1: "Where are you going?" — a single search-first destination
/// picker. Countries aren't grouped by continent in the UI; typing filters
/// the full country list directly. Replaces the old continent-map ->
/// country-map two-screen flow (see HANDOFF.md for why). Every country is
/// tappable; only `active` ones lead to the real flow, the rest dead-end at
/// ComingSoonScreen (language-app-system-design.md section 2, step 2).
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCountry(TripSelection trip, Country country) {
    if (!country.active) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ComingSoonScreen(country: country)),
      );
      return;
    }
    trip.selectCountry(country);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CategorySelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();

    if (trip.loadingReferenceData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final results = _query.isEmpty
        ? const <Country>[]
        : trip.countries
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'Where are you going?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search countries',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.isNotEmpty
                    ? ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final country = results[index];
                          return ListTile(
                            title: Text(country.name),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _selectCountry(trip, country),
                          );
                        },
                      )
                    // Decorative filler when there's no search in progress —
                    // just to have a little more on the page than a bare
                    // search field.
                    : Center(
                        child: Icon(
                          Icons.public,
                          size: 160,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
