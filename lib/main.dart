import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/destination_screen.dart';
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
        home: const DestinationScreen(),
      ),
    );
  }
}
