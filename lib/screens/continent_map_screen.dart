import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_selection.dart';
import 'country_map_screen.dart';

/// Screen 1: "Where are you going?" — a placeholder list-based stand-in for
/// the eventual continent map (language-app-system-design.md flags real
/// map/SVG package evaluation as separate follow-up work).
class ContinentMapScreen extends StatelessWidget {
  const ContinentMapScreen({super.key});

  static const _continents = [
    ('north-america', 'North America'),
    ('south-america', 'South America'),
    ('europe', 'Europe'),
    ('africa', 'Africa'),
    ('asia', 'Asia'),
    ('oceania', 'Oceania'),
    ('antarctica', 'Antarctica'),
  ];

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();

    if (trip.loadingReferenceData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Where are you going?')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _continents.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (id, name) = _continents[index];
          final active = trip.isContinentActive(id);
          return ListTile(
            title: Text(name),
            enabled: active,
            trailing: active ? const Icon(Icons.chevron_right) : null,
            onTap: active
                ? () {
                    trip.selectContinent(id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CountryMapScreen(),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }
}
