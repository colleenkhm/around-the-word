import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/country_bundle.dart';
import '../models/live_data.dart';
import '../models/travel_info.dart';
import '../theme/country_theme.dart';
import '../widgets/country_page/cities_section.dart';
import '../widgets/country_page/country_header.dart';
import '../widgets/country_page/right_now_strip.dart';
import '../widgets/country_page/section_heading.dart';
import '../widgets/country_page/travel_info_section.dart';

/// Temporary review screen for the Overview tab, built up one section at a
/// time against real (Costa Rica) mock data — not part of the real
/// navigation flow. Remove once CountryPageScreen exists and hosts these
/// sections for real. Swapped in as main.dart's `home` for now
/// specifically so this is what `flutter run` shows during review.
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

  /// "Right now" in the country's own timezone, not wherever this device
  /// happens to be — a season lookup keyed off the wrong local date could
  /// show the wrong season near a month boundary.
  DateTime _localDate(CountryBundle bundle) {
    final offset = bundle.facts.utcOffsetMinutes;
    return offset == null
        ? DateTime.now()
        : DateTime.now().toUtc().add(Duration(minutes: offset));
  }

  /// US State Department only, for now (per Colleen, 2026-08-11) — the
  /// only advisory source actually wired up in `tools/commodity_importer`;
  /// UK FCDO and Global Affairs Canada are real sources per the data
  /// architecture doc but nothing fetches them yet, so `bundle.advisories`
  /// having a UK entry (mock data only) shouldn't imply the app is
  /// multi-government-ready. `TravelInfoSection` itself still renders a
  /// list generically — this filter is the temporary policy, not a widget
  /// change — so removing it later is a one-line reversal once a second
  /// source is real.
  ///
  /// Matches on `issuingAuthority`'s free text (see [TravelAdvisory]'s doc
  /// comment: no government-code field exists to match on instead) — fine
  /// for one hardcoded mock country, worth revisiting if that ever proves
  /// fragile against real imported data.
  List<TravelAdvisory> _usAdvisories(CountryBundle bundle) => bundle.advisories
      .where((a) => a.issuingAuthority == 'US State Department')
      .toList();

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
                    // Grows one tab at a time as each screen actually gets
                    // built — not derived from bundle content. See
                    // CountryHeader's doc comment.
                    tabs: const [CountryTab.overview],
                    activeTab: _activeTab,
                    onTabSelected: (tab) => setState(() => _activeTab = tab),
                    // Costa Rica has no curated native-name/romanization
                    // data yet — see CountryHeader's doc comment on why
                    // these are constructor params, not bundle fields.
                    nativeName: 'Costa Rica',
                    nativeNameRomanized: null,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeading('Right now'),
                          RightNowStrip(
                            utcOffsetMinutes: bundle.facts.utcOffsetMinutes,
                            // Real curated content, resolved against the
                            // country's own local date — not mock data,
                            // unlike the exchange rate below.
                            season: bundle.guide.seasonFor(_localDate(bundle)),
                            // Mock instance, not bundle data — currency
                            // conversion is explicitly never bundled (see
                            // RightNowStrip's doc comment). A stand-in for
                            // what a live Edge Function call would return.
                            exchangeRate: ExchangeRate(
                              currencyCode: bundle.facts.currencyCode ?? 'CRC',
                              rateFromUsd: 519.8,
                              fetchedAt: DateTime.now(),
                            ),
                            currencyName: bundle.facts.currencyName,
                          ),
                          const SizedBox(height: 18),
                          TravelInfoSection(
                            advisories: _usAdvisories(bundle),
                            visa: bundle.visa,
                            regionalNote: bundle.regionalNote,
                          ),
                          const SizedBox(height: 18),
                          CitiesSection(
                            cities: bundle.cities,
                            capital: bundle.facts.capital,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '(Rest of the Overview tab not built yet — '
                            'more sections land here one at a time.)',
                            style: TextStyle(
                              color: CountryTheme.inkSoft,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
