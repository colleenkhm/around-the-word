import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/phrases.dart';
import 'models/trip.dart';
import 'screens/country_screen.dart';
import 'screens/deck_screen.dart';
import 'screens/environment_screen.dart';
import 'screens/my_trip_screen.dart';
import 'screens/translate_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/translation_service.dart';
import 'state/trips.dart';
import 'state/practice_scores.dart';
import 'state/recent_phrases.dart';
import 'state/vocab_bank.dart';
import 'theme/pocket_talk_theme.dart';
import 'widgets/pt_tab_bar.dart';

const _seenWelcomeKey = 'seen_welcome';

void main() {
  runApp(const PocketTalkApp());
}

class PocketTalkApp extends StatelessWidget {
  const PocketTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VocabBank()..load()),
        ChangeNotifierProvider(create: (_) => Trips()..load()),
        ChangeNotifierProvider(create: (_) => RecentPhrases()..load()),
        ChangeNotifierProvider(create: (_) => PracticeScores()..load()),
        Provider<TranslationProvider>.value(value: activeTranslationProvider),
      ],
      child: MaterialApp(
        title: 'Pocket Talk',
        debugShowCheckedModeBanner: false,
        theme: buildPocketTalkTheme(),
        home: const AppEntry(),
      ),
    );
  }
}

/// First launch: welcome splash, then set up a first trip — where you're
/// going and what it'll be like there. After that, straight to the app.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _seenWelcome;
  bool _migrationChecked = false;

  /// The destination chosen but not yet committed — the trip isn't created
  /// until its settings are picked too.
  String? _draftCountry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _seenWelcome = prefs.getBool(_seenWelcomeKey) ?? false);
  }

  void _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenWelcomeKey, true);
    setState(() => _seenWelcome = true);
  }

  /// Carries a pre-trips install over: the country and settings that used to
  /// be global become the first trip, and everything already saved becomes
  /// its deck, so nobody is asked to set up again or loses their vocabulary.
  void _migrateIfNeeded() {
    final trip = context.read<Trips>().migrateLegacySettings(
      currentLanguage.code,
    );
    if (trip != null) context.read<VocabBank>().adoptLegacySaves(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<Trips>();
    final bank = context.watch<VocabBank>();
    if (_seenWelcome == null || !trips.loaded || !bank.loaded) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Both stores are up; check for an older install exactly once. Deferred
    // a frame because it notifies listeners, which can't happen mid-build.
    if (!_migrationChecked) {
      _migrationChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _migrateIfNeeded();
        // Rebuild unconditionally: with nothing to carry over, migrating
        // notifies no one, and this gate would never lift.
        setState(() {});
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_seenWelcome!) {
      return WelcomeScreen(onGetStarted: _completeWelcome);
    }
    if (!trips.hasTrip) {
      if (_draftCountry == null) {
        return CountryScreen(
          onSelected: (country) => setState(() => _draftCountry = country),
        );
      }
      return EnvironmentScreen(
        onDone: (environments) {
          context.read<Trips>().add(
            Trip.create(
              languageCode: currentLanguage.code,
              country: _draftCountry!,
              environments: environments,
            ),
          );
          setState(() => _draftCountry = null);
        },
      );
    }
    return const RootScaffold();
  }
}

/// Bottom-nav shell: look anything up, browse the curated phrasebook, or
/// practice what's been saved. An [IndexedStack] rather than swapping widgets,
/// so each tab keeps its state (a typed query, a scrolled grid) while the
/// user is on another one.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  static const _translateTab = 0;

  int _tab = _translateTab;

  // Set when another tab hands a query to Translate (the phrasebook's empty
  // search offering to look it up). TranslateScreen picks it up as a prop
  // change, since it stays alive in the IndexedStack.
  String? _translateQuery;

  static const _items = [
    PTTabItem(
      // Icons.translate has no outlined variant; the tab bar already marks
      // the selected tab with ink color and weight.
      icon: Icons.translate,
      selectedIcon: Icons.translate,
      label: 'Translate',
    ),
    PTTabItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'My trip',
    ),
    PTTabItem(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      label: 'Practice',
    ),
  ];

  void _translate(String query) {
    setState(() {
      _translateQuery = query;
      _tab = _translateTab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TranslateScreen(incomingQuery: _translateQuery),
          MyTripScreen(onTranslate: _translate),
          const DeckScreen(),
        ],
      ),
      bottomNavigationBar: PTTabBar(
        items: _items,
        selectedIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}
