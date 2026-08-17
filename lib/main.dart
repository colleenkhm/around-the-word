import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/destination_screen.dart';
import 'state/trip_selection.dart';
import 'theme/country_theme.dart';

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
        theme: _theme,
        home: const DestinationScreen(),
      ),
    );
  }
}

/// App-wide default so every screen — not just the country page — starts
/// from the navy/cream/gold "boarding pass" identity instead of Material's
/// generic deepPurple seed. Added 2026-08-17, per Colleen: "make sure all
/// pages follow the same general stylings/theme as the country page."
///
/// **Deliberately shallow, not a full design-system port.** This sets the
/// defaults every plain `Scaffold`/`AppBar`/`TextField`/`Text` picks up
/// automatically (background, app bar chrome, base font, input borders,
/// dividers) — the country page's own widgets (`CountryHeader`,
/// `TravelInfoSection`, ...) already hardcode `CountryTheme` values
/// directly and don't read this theme at all, so this doesn't touch them.
/// `DestinationScreen` and `AboutScreen` got a fuller pass on top of this
/// (see their own files) since they were named explicitly; other screens
/// (categories, flashcards, coming-soon) inherit these defaults for free
/// without being individually restyled — a smaller, quicker win than
/// hand-porting every screen, worth revisiting screen-by-screen later if
/// one still looks out of place.
final _theme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: CountryTheme.paper,
  colorScheme: const ColorScheme.light(
    primary: CountryTheme.navy,
    onPrimary: CountryTheme.onNavy,
    secondary: CountryTheme.terracotta,
    onSecondary: CountryTheme.onNavy,
    surface: CountryTheme.paper,
    onSurface: CountryTheme.ink,
    error: CountryTheme.stampRed,
    onError: CountryTheme.onNavy,
  ),
  fontFamily: 'Public Sans',
  dividerColor: CountryTheme.rule,
  appBarTheme: const AppBarTheme(
    backgroundColor: CountryTheme.navy,
    foregroundColor: CountryTheme.onNavy,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Libre Baskerville',
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: CountryTheme.onNavy,
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontFamily: 'Libre Baskerville',
      fontWeight: FontWeight.w700,
      color: CountryTheme.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Libre Baskerville',
      fontWeight: FontWeight.w700,
      color: CountryTheme.ink,
    ),
    titleMedium: TextStyle(fontFamily: 'Public Sans', color: CountryTheme.ink),
    bodyMedium: TextStyle(fontFamily: 'Public Sans', color: CountryTheme.inkBody),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: CountryTheme.card,
    labelStyle: const TextStyle(fontFamily: 'Courier Prime', color: CountryTheme.inkSoft, fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
      borderSide: const BorderSide(color: CountryTheme.rule),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
      borderSide: const BorderSide(color: CountryTheme.rule),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
      borderSide: const BorderSide(color: CountryTheme.navy, width: 1.5),
    ),
  ),
);
