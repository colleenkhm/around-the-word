import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/country_header_preview_screen.dart';
// ignore: unused_import
import 'screens/destination_screen.dart'; // TEMPORARY: unused while CountryHeaderPreviewScreen is home
import 'state/trip_selection.dart';

void main() {
  runApp(const AroundTheWordApp());
}

class AroundTheWordApp extends StatelessWidget {
  const AroundTheWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TripSelection()..loadReferenceData(),
      child: MaterialApp(
        title: 'Around the Word',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // TEMPORARY: country-page header review (see
        // CountryHeaderPreviewScreen's doc comment). Swap back to
        // DestinationScreen() once the header is signed off.
        home: const CountryHeaderPreviewScreen(),
      ),
    );
  }
}
