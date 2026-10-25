import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'screens/destination_screen.dart';
import 'state/trip_selection.dart';
import 'theme/accordion_theme.dart';

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
        theme: _theme,
        debugShowCheckedModeBanner: false,
        home: const DestinationScreen(),
      ),
    );
  }
}

/// App-wide default theme, based on [AccordionTheme]. Only sets what
/// plain `Scaffold`/`AppBar`/`TextField`/`Text` pick up automatically —
/// country/home page widgets hardcode `AccordionTheme` directly.
final _theme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AccordionTheme.page,
  colorScheme: const ColorScheme.light(
    primary: AccordionTheme.ink,
    onPrimary: AccordionTheme.white,
    secondary: AccordionTheme.roseDark,
    onSecondary: AccordionTheme.white,
    surface: AccordionTheme.page,
    onSurface: AccordionTheme.ink,
    error: AccordionTheme.danger,
    onError: AccordionTheme.white,
  ),
  fontFamily: AccordionTheme.dmSans,
  dividerColor: AccordionTheme.rule,
  appBarTheme: const AppBarTheme(
    backgroundColor: AccordionTheme.ink,
    foregroundColor: AccordionTheme.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: AccordionTheme.fraunces,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: AccordionTheme.white,
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontFamily: AccordionTheme.fraunces,
      fontWeight: FontWeight.w700,
      color: AccordionTheme.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: AccordionTheme.fraunces,
      fontWeight: FontWeight.w700,
      color: AccordionTheme.ink,
    ),
    titleMedium: TextStyle(fontFamily: AccordionTheme.dmSans, color: AccordionTheme.ink),
    bodyMedium: TextStyle(fontFamily: AccordionTheme.dmSans, color: AccordionTheme.ink2),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AccordionTheme.white,
    labelStyle: const TextStyle(fontFamily: AccordionTheme.dmMono, color: AccordionTheme.ink3, fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AccordionTheme.cardRadius),
      borderSide: const BorderSide(color: AccordionTheme.rule),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AccordionTheme.cardRadius),
      borderSide: const BorderSide(color: AccordionTheme.rule),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AccordionTheme.cardRadius),
      borderSide: const BorderSide(color: AccordionTheme.ink, width: 1.5),
    ),
  ),
);
