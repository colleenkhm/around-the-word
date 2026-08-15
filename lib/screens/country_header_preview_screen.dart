import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/country_bundle.dart';
import '../models/live_data.dart';
import '../models/travel_info.dart';
import '../theme/country_theme.dart';
import '../utils/hex_color.dart';
import '../widgets/country_page/best_times_section.dart';
import '../widgets/country_page/cities_section.dart';
import '../widgets/country_page/country_header.dart';
import '../widgets/country_page/language_pair_section.dart';
import '../widgets/country_page/paper_texture.dart';
import '../widgets/country_page/practical_norms_section.dart';
import '../widgets/country_page/travel_info_section.dart';

/// Temporary review screen for the Overview tab, built up one section at a
/// time against real (Costa Rica) mock data — not part of the real
/// navigation flow. Remove once CountryPageScreen exists and hosts these
/// sections for real. Swapped in as main.dart's `home` for now
/// specifically so this is what `flutter run` shows during review.
///
/// **Section order** (2026-08-15, matching `trip-dashboard-v3.html` as
/// closely as the existing architecture allows): ticket header → Travel
/// Info (advisories + visa) → Cities → Languages/Word-of-day → Best times
/// → Practical notes. The mockup actually places Visa/Entry right after
/// the ticket and Travel Advisory near the very end, next to "Getting
/// around" — but [TravelInfoSection] deliberately combines advisories and
/// visa into one shared-source unit (see its class doc, a 2026-08-11
/// decision this pass didn't revisit), so they can't be split across two
/// positions. Kept as one unit, placed early for the same "can I even go"
/// prominence the mockup gives Visa/Entry.
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

  /// Whether the page background uses a light pastel of the country's
  /// flag color (via [CountryTheme.lightTint]) instead of the fixed
  /// parchment [CountryTheme.paper]. **Off for now** (2026-08-11, per
  /// Colleen: "we don't have to stick with the background color thing we
  /// did earlier... I want the page theme to be more overarchingly
  /// cohesive" — a different pastel per country was working against the
  /// one amber/board identity the rest of the page just adopted). The
  /// capability itself is intentionally left in place rather than
  /// deleted — this flag, `lightTint`, `hexToColor`, and
  /// `CountryFacts.accentColorHex` all still work; flipping this to
  /// `true` is the entire change if per-country backgrounds come back
  /// later. `final`, not `const`, specifically so the analyzer doesn't
  /// const-fold the `if` below into a dead-code warning.
  static final bool _useAccentPageBackground = false;

  Color _pageBackground(CountryBundle? bundle) {
    if (!_useAccentPageBackground) return CountryTheme.paper;
    final hex = bundle?.facts.accentColorHex;
    return hex == null ? CountryTheme.paper : CountryTheme.lightTint(hexToColor(hex));
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    return Scaffold(
      backgroundColor: _pageBackground(bundle),
      body: PaperTexture(
        child: bundle == null
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
                    utcOffsetMinutes: bundle.facts.utcOffsetMinutes,
                    // Mock instance, not bundle data — currency conversion
                    // is explicitly never bundled (see CountryHeader's doc
                    // comment). A stand-in for what a live Edge Function
                    // call would return. Season (the retired RightNowStrip's
                    // third column) is dropped from the Overview tab for
                    // this pass, not moved anywhere — see CountryHeader's
                    // class doc.
                    exchangeRate: ExchangeRate(
                      currencyCode: bundle.facts.currencyCode ?? 'CRC',
                      rateFromUsd: 519.8,
                      fetchedAt: DateTime.now(),
                    ),
                    currencyName: bundle.facts.currencyName,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TravelInfoSection(
                            advisories: _usAdvisories(bundle),
                            visa: bundle.visa,
                            regionalNote: bundle.regionalNote,
                            emergencyNumber: bundle.facts.emergencyNumber,
                          ),
                          const SizedBox(height: 18),
                          CitiesSection(
                            cities: bundle.cities,
                            capital: bundle.facts.capital,
                          ),
                          const SizedBox(height: 18),
                          LanguagePairSection(
                            officialLanguages: bundle.facts.officialLanguages,
                            // Static pick, not a real "today's word" —
                            // see LanguagePairSection's class doc.
                            featuredWord: bundle.words.isEmpty ? null : bundle.words.first,
                          ),
                          const SizedBox(height: 18),
                          BestTimesSection(bestTimes: bundle.guide.bestTimes),
                          const SizedBox(height: 18),
                          PracticalNormsSection(norms: bundle.guide.practicalNorms),
                          const SizedBox(height: 24),
                          Text(
                            '(Explore/Guide/Language tabs not built yet — '
                            'Overview is the only tab this screen previews.)',
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
      ),
    );
  }
}
