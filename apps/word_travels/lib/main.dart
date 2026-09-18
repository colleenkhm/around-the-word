import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/vocab_bank_screen.dart';
import 'screens/welcome_screen.dart';
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
    return ChangeNotifierProvider(
      create: (_) => VocabBank()..load(),
      child: MaterialApp(
        title: 'Pocket Talk',
        debugShowCheckedModeBanner: false,
        theme: buildPocketTalkTheme(),
        home: const AppEntry(),
      ),
    );
  }
}

/// Decides whether to show the welcome splash (first launch only) or go
/// straight to the app.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _seenWelcome;

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

  @override
  Widget build(BuildContext context) {
    if (_seenWelcome == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!_seenWelcome!) {
      return WelcomeScreen(onGetStarted: _completeWelcome);
    }
    return const RootScaffold();
  }
}

/// Bottom-nav shell: browse categories, or review the vocab bank.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _tab = 0;

  static const _screens = [HomeScreen(), VocabBankScreen()];

  static const _items = [
    PTTabItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    PTTabItem(icon: Icons.bookmark_border, selectedIcon: Icons.bookmark, label: 'Saved'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: PTTabBar(
        items: _items,
        selectedIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}
