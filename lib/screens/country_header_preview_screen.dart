import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/country.dart' as country_model;
import '../models/country_bundle.dart';
import '../models/live_data.dart';
import '../models/travel_info.dart';
import '../theme/accordion_theme.dart';
import 'about_screen.dart';
import 'destination_screen.dart';
import '../widgets/country_page/accordion_section.dart';
import '../widgets/country_page/best_times_section.dart';
import '../widgets/country_page/cities_section.dart';
import '../widgets/country_page/country_header.dart';
import '../widgets/country_page/language_pair_section.dart';
import '../widgets/country_page/practical_norms_section.dart';
import '../widgets/country_page/site_header.dart';
import '../widgets/country_page/travel_advisory_section.dart';
import '../widgets/country_page/visa_section.dart';

/// The country page — reached directly from `DestinationScreen` when an
/// `active` country is tapped, standing in for the real multi-tab
/// `CountryPageScreen` (Overview/Explore/Guide/Travel Info/Language) until
/// that's built. Only `assets/data/bundles/cr.json` actually exists today,
/// so Costa Rica is the only country this can render — but the only other
/// `active: true` country would need is a matching bundle file, no code
/// change.
///
/// **2026-08-18: rebuilt as a collapsible-sections accordion**, matching
/// `trip-dashboard-v5.html`'s two frames (default-collapsed vs. every
/// section expanded). Replaces the always-expanded flat stack the
/// 2026-08-15 pass built — see [AccordionTheme]'s class doc for the full
/// list of what this reverses and why it's scoped to just this screen.
///
/// **Section order** (2026-08-18, matching the v5 mockup exactly): ticket
/// header → Visa & Entry → Cities → When to Visit → Travel Advisory →
/// Language → Practical Norms. Visa and Travel Advisory are two
/// independent sections now, not one combined unit — see [VisaSection]'s
/// class doc.
///
/// **Every section always renders as a row, regardless of data** — per
/// Colleen: "all of these things should display if we have data for
/// them, otherwise the section should say 'coming soon' when expanded."
/// See [AccordionSection]'s class doc on how this differs from the rest
/// of the app's "omit an empty tab" rule.
class CountryHeaderPreviewScreen extends StatefulWidget {
  final country_model.Country country;

  const CountryHeaderPreviewScreen({super.key, required this.country});

  @override
  State<CountryHeaderPreviewScreen> createState() =>
      _CountryHeaderPreviewScreenState();
}

/// One entry per accordion row, in display order — used as the source of
/// truth for both the section list and the "expand/collapse all" state.
enum _Section { visa, cities, times, advisory, language, norms }

class _CountryHeaderPreviewScreenState
    extends State<CountryHeaderPreviewScreen> {
  CountryBundle? _bundle;
  bool _loadFailed = false;

  /// Every section starts collapsed — matches the mockup's default frame.
  final Map<_Section, bool> _expanded = {for (final s in _Section.values) s: false};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code = widget.country.countryCode.toLowerCase();
    try {
      final raw = await rootBundle.loadString('assets/data/bundles/$code.json');
      setState(() {
        _bundle = CountryBundle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      });
    } catch (error) {
      // Shouldn't happen in practice — DestinationScreen only routes here
      // for `active` countries, and today that's Costa Rica alone — but
      // this screen now takes an arbitrary Country, so a missing bundle
      // file (rather than an infinite spinner) needs somewhere to go.
      debugPrint('No bundle for $code: $error');
      setState(() => _loadFailed = true);
    }
  }

  /// US State Department only, for now (per Colleen, 2026-08-11) — the
  /// only advisory source actually wired up in `tools/commodity_importer`;
  /// UK FCDO and Global Affairs Canada are real sources per the data
  /// architecture doc but nothing fetches them yet.
  List<TravelAdvisory> _usAdvisories(CountryBundle bundle) => bundle.advisories
      .where((a) => a.issuingAuthority == 'US State Department')
      .toList();

  bool get _allExpanded => _expanded.values.every((v) => v);

  void _toggle(_Section section) {
    setState(() => _expanded[section] = !_expanded[section]!);
  }

  void _toggleAll() {
    final next = !_allExpanded;
    setState(() {
      for (final s in _Section.values) {
        _expanded[s] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    return Scaffold(
      backgroundColor: AccordionTheme.page,
      body: _loadFailed
          ? _LoadFailedView(country: widget.country)
          : bundle == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  SiteHeader(
                    // Clears the nav stack rather than a plain push — "back
                    // to home" should hold regardless of how deep the user
                    // is in the flow, not just undo the last screen.
                    onHomeTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const DestinationScreen()),
                      (route) => false,
                    ),
                    onAboutTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    ),
                    backgroundColor: AccordionTheme.ink,
                    iconColor: Colors.white.withValues(alpha: 0.85),
                    aboutTextStyle: const TextStyle(
                      fontFamily: AccordionTheme.dmMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CountryHeader(
                            bundle: bundle,
                            // No country has curated native-name data yet
                            // except this one hardcoded Costa Rica value.
                            nativeName: widget.country.countryCode == 'CR' ? 'Costa Rica' : null,
                            nativeNameRomanized: null,
                            utcOffsetMinutes: bundle.facts.utcOffsetMinutes,
                            // Mock instance, not bundle data — currency
                            // conversion is explicitly never bundled (see
                            // the data architecture doc).
                            exchangeRate: ExchangeRate(
                              currencyCode: bundle.facts.currencyCode ?? 'CRC',
                              rateFromUsd: 519.8,
                              fetchedAt: DateTime.now(),
                            ),
                            currencyName: bundle.facts.currencyName,
                            allExpanded: _allExpanded,
                            onToggleAll: _toggleAll,
                          ),
                          _visaSection(bundle),
                          _citiesSection(bundle),
                          _timesSection(bundle),
                          _advisorySection(bundle),
                          _languageSection(bundle),
                          _normsSection(bundle),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Sections -----------------------------------------------------------
  // Each returns an AccordionSection wired with this section's tint, meta
  // summary (collapsed subheading), hasData flag, and content. Meta text
  // is derived from real bundle fields only — never invented (see e.g.
  // VisaSection's class doc on the "No visa required" headline it
  // deliberately doesn't fabricate).

  Widget _visaSection(CountryBundle bundle) {
    final visa = bundle.visa;
    return AccordionSection(
      title: 'Visa & Entry',
      tint: AccordionTheme.sky,
      // Gradient, not the flat tint above — see AccordionTheme.visaRowGradient's
      // doc comment: distinguishes this row from the sky-colored ticket
      // stub directly above it.
      gradient: AccordionTheme.visaRowGradient,
      hasData: visa != null,
      meta: visa == null ? null : _firstClause(visa.summary),
      expanded: _expanded[_Section.visa]!,
      onToggle: () => _toggle(_Section.visa),
      contentBuilder: (_) => VisaSection(visa: visa!, regionalNote: bundle.regionalNote),
    );
  }

  Widget _citiesSection(CountryBundle bundle) {
    final cities = bundle.cities;
    return AccordionSection(
      title: 'Cities',
      tint: AccordionTheme.lavender,
      hasData: cities.isNotEmpty,
      meta: cities.isEmpty ? null : '${cities.length} destination${cities.length == 1 ? '' : 's'}',
      expanded: _expanded[_Section.cities]!,
      onToggle: () => _toggle(_Section.cities),
      contentBuilder: (_) => CitiesSection(cities: cities, capital: bundle.facts.capital),
    );
  }

  Widget _timesSection(CountryBundle bundle) {
    final bestTimes = bundle.guide.bestTimes;
    return AccordionSection(
      title: 'When to Visit',
      tint: AccordionTheme.butter,
      hasData: bestTimes.isNotEmpty,
      meta: bestTimes.isEmpty ? null : bestTimes.map((b) => b.months).join(' · '),
      expanded: _expanded[_Section.times]!,
      onToggle: () => _toggle(_Section.times),
      contentBuilder: (_) => BestTimesSection(bestTimes: bestTimes),
    );
  }

  Widget _advisorySection(CountryBundle bundle) {
    final advisories = _usAdvisories(bundle);
    final first = advisories.isEmpty ? null : advisories.first;
    final metaLabel = first == null
        ? null
        : [first.level, first.issuingAuthority].nonNulls.join(' · ');
    return AccordionSection(
      title: 'Travel Advisory',
      tint: AccordionTheme.sage,
      hasData: advisories.isNotEmpty,
      meta: metaLabel,
      expanded: _expanded[_Section.advisory]!,
      onToggle: () => _toggle(_Section.advisory),
      contentBuilder: (_) => TravelAdvisorySection(
        advisories: advisories,
        emergencyNumber: bundle.facts.emergencyNumber,
      ),
    );
  }

  Widget _languageSection(CountryBundle bundle) {
    final languages = bundle.facts.officialLanguages;
    final featuredWord = bundle.words.isEmpty ? null : bundle.words.first;
    final hasData = languages.isNotEmpty || featuredWord != null;
    return AccordionSection(
      title: 'Language',
      tint: AccordionTheme.rose,
      hasData: hasData,
      meta: languages.isEmpty ? null : languages.join(' · '),
      expanded: _expanded[_Section.language]!,
      onToggle: () => _toggle(_Section.language),
      contentBuilder: (_) => LanguagePairSection(
        officialLanguages: languages,
        featuredWord: featuredWord,
      ),
    );
  }

  Widget _normsSection(CountryBundle bundle) {
    final norms = bundle.guide.practicalNorms;
    return AccordionSection(
      title: 'Practical Norms',
      tint: AccordionTheme.peach,
      hasData: norms.isNotEmpty,
      meta: norms.isEmpty ? null : norms.map((n) => n.title).join(' · '),
      expanded: _expanded[_Section.norms]!,
      onToggle: () => _toggle(_Section.norms),
      contentBuilder: (_) => PracticalNormsSection(norms: norms),
    );
  }

  /// First sentence-ish clause of a free-text summary, for a collapsed
  /// row's meta line — truncated to keep the row a single line. Doesn't
  /// invent structured facts (e.g. a "visa required: yes/no" boolean)
  /// that aren't in [VisaInfo]; just teases the real summary text.
  String _firstClause(String summary) {
    final period = summary.indexOf('.');
    final clause = period == -1 ? summary : summary.substring(0, period);
    return clause.length > 60 ? '${clause.substring(0, 60)}…' : clause;
  }
}

/// Shown in place of the page when no bundle file exists for the tapped
/// country — see `_load`'s catch clause. Not styled to match the
/// accordion theme; this is a "shouldn't happen" fallback, not a designed
/// state.
class _LoadFailedView extends StatelessWidget {
  final country_model.Country country;

  const _LoadFailedView({required this.country});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't load content for ${country.name}.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const DestinationScreen()),
                  (route) => false,
                ),
                child: const Text('Back to search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
