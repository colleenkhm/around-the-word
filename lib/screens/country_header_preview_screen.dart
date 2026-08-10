import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/country_bundle.dart';
import '../theme/country_theme.dart';
import '../widgets/country_page/country_header.dart';

/// Temporary review screen for the country-page header/chrome — see it
/// rendered against real (Costa Rica) mock data before the rest of the
/// Overview tab exists to nest it in. Not part of the real navigation
/// flow; remove once CountryPageScreen exists and hosts the header for
/// real. Swapped in as main.dart's `home` for now specifically so this is
/// what `flutter run` shows during header review.
class CountryHeaderPreviewScreen extends StatefulWidget {
  const CountryHeaderPreviewScreen({super.key});

  @override
  State<CountryHeaderPreviewScreen> createState() =>
      _CountryHeaderPreviewScreenState();
}

class _CountryHeaderPreviewScreenState
    extends State<CountryHeaderPreviewScreen> {
  CountryBundle? _bundle;
  CountryTab _activeTab = CountryTab.overview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/bundles/cr.json');
    setState(() {
      _bundle = CountryBundle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    return Scaffold(
      backgroundColor: CountryTheme.paper,
      body: bundle == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  CountryHeader(
                    bundle: bundle,
                    activeTab: _activeTab,
                    onTabSelected: (tab) => setState(() => _activeTab = tab),
                    // Costa Rica has no curated native-name/romanization
                    // data yet — see CountryHeader's doc comment on why
                    // these are constructor params, not bundle fields.
                    nativeName: 'Costa Rica',
                    nativeNameRomanized: null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Active tab: ${_activeTab.name}\n\n'
                        '(Rest of the Overview tab not built yet — '
                        'this screen only hosts the header for review.)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CountryTheme.inkSoft),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
