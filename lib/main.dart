import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/destination_screen.dart';
import 'state/trip_selection.dart';
import 'theme/accordion_theme.dart';

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
        debugShowCheckedModeBanner: false,
        home: const DestinationScreen(),
      ),
    );
  }
}

/// App-wide default so every screen — not just the country page — starts
/// from this app's real identity instead of Material's generic deepPurple
/// seed. Added 2026-08-17, per Colleen: "make sure all pages follow the
/// same general stylings/theme as the country page."
///
/// **2026-08-18: repointed from `CountryTheme` (navy/cream/gold "boarding
/// pass") to `AccordionTheme`** (ink/lavender/sage/rose/butter/sky,
/// Fraunces/DM Sans/DM Mono) — per Colleen: "let's align any remaining
/// pages with the new stylings," once the country page and home page had
/// both already moved to `AccordionTheme`. This is what makes that
/// alignment reach every other screen (categories, personalizing,
/// learn/use, vocab list, flashcards, about) essentially for free — none
/// of them reference either theme file directly (confirmed via grep
/// before this change), so they all pick up whatever this file sets.
///
/// **Deliberately shallow, not a full design-system port.** This sets the
/// defaults every plain `Scaffold`/`AppBar`/`TextField`/`Text` picks up
/// automatically (background, app bar chrome, base font, input borders,
/// dividers) — the country/home pages' own widgets (`CountryHeader`,
/// `VisaSection`, ...) already hardcode `AccordionTheme` values directly
/// and don't read this theme at all, so this doesn't touch them; they'd
/// look the same with this theme deleted. Worth revisiting screen-by-
/// screen (a real `AppBar`/`SiteHeader` swap, tighter per-screen padding,
/// ...) if one still looks out of place once it has real content.
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
