import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'screens/destination_screen.dart';
import 'state/trip_selection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // Loads the bundled IANA tzdata — no network fetch. Needed before any
  // country_facts.timezone lookup (see CountryHeader's local-time logic).
  tz_data.initializeTimeZones();

  runApp(const WhereaboutApp());
}

class WhereaboutApp extends StatelessWidget {
  const WhereaboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TripSelection()..loadReferenceData(),
      child: MaterialApp(
        title: 'whereabout',
        theme: sharedThemeData,
        debugShowCheckedModeBanner: false,
        home: const DestinationScreen(),
      ),
    );
  }
}
