import 'package:flutter/material.dart';

import 'continent_tap_screen.dart';

/// Standalone entry point for the map prototype — deliberately not wired
/// into the real app's Provider/TripSelection/navigation. Run directly:
///   flutter run -t lib/map_prototype/main_prototype.dart
void main() {
  runApp(const MapPrototypeApp());
}

class MapPrototypeApp extends StatelessWidget {
  const MapPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ContinentTapScreen(),
    );
  }
}
