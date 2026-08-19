import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/country.dart' as country_model;
import '../models/country_bundle.dart';
import '../models/country_guide.dart';
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

/// The country page — reached directly from `DestinationScreen` for
/// **every** tapped country now, not just `active` ones (see below) —
/// standing in for the real multi-tab `CountryPageScreen`
/// (Overview/Explore/Guide/Travel Info/Language) until that's built. Only
/// `assets/data/bundles/cr.json` actually exists today, so Costa Rica is
/// the only country with real content — every other country renders this
/// same shell with every section in its "coming soon" state (see below).
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
///
/// **2026-08-18 (later): `ComingSoonScreen` retired from this flow** — per
/// Colleen: "instead of the coming soon page we should just have a
/// country page showing any available data where the expanded categories
/// say 'coming soon'." `DestinationScreen` now sends every tapped
/// country here regardless of `Country.active`; when no bundle file
/// exists for it, `_load` builds an empty in-memory [CountryBundle]
/// shell (see `_emptyBundle`) instead of falling into a dead-end error
/// state — every [AccordionSection] below already renders a "Coming
/// soon" body when its `hasData` is false, so an all-empty bundle just
/// means every section shows that. `ComingSoonScreen` itself, and the
/// generic `coming_soon_resources` it read, are unreferenced now but
/// left in place — same "kept as history, not deleted, until something
/// else needs the space" pattern the rest of this codebase's superseded
/// code follows.
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
      // No curated bundle yet for this country — not an error state
      // anymore (see class doc, 2026-08-18): render the same page shell
      // with every section in its "coming soon" state, rather than a
      // dead end. Expected for every country besides Costa Rica today.
      debugPrint('No bundle for $code — showing an empty shell: $error');
      setState(() => _bundle = _emptyBundle(widget.country));
    }
  }

  /// A [CountryBundle] with every list/optional field empty — every
  /// [AccordionSection] below reads `hasData: false` off of it and shows
  /// "Coming soon" accordingly. `country`/`fetchedAt` are the only real
  /// values; everything else is the type's natural empty value, not a
  /// guess at real content.
  CountryBundle _emptyBundle(country_model.Country country) {
    return CountryBundle(
      country: Country(
        id: country.countryCode.toLowerCase(),
        isoCode: country.countryCode,
        nameCommon: country.name,
        nameOfficial: country.name,
        contentStatus: ContentStatus.none,
      ),
      facts: const CountryFacts(officialLanguages: []),
      cities: const [],
      guide: const CountryGuide(
        bestTimes: [],
        seasons: [],
        practicalNorms: [],
        dressExpectations: [],
        cuisine: [],
        historicalEvents: [],
        festivals: [],
        prepNotes: [],
      ),
      pointsOfInterest: const [],
      tips: const [],
      phrases: const [],
      words: const [],
      categories: const [],
      advisories: const [],
      contributorNames: const [],
      fetchedAt: DateTime.now(),
    );
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
      body: bundle == null
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
                            // the data architecture doc). Only built when
                            // there's a real currency to mock a rate for —
                            // `null` otherwise (renders an em dash), so an
                            // empty-shell country (see `_emptyBundle`)
                            // doesn't show a fabricated rate for whatever
                            // currency this hardcoded mock happened to
                            // default to.
                            exchangeRate: bundle.facts.currencyCode == null
                                ? null
                                : ExchangeRate(
                                    currencyCode: bundle.facts.currencyCode!,
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
      // Gradient, not the flat tint above — every section row uses one
      // now (see AccordionTheme.visaRowGradient's doc comment).
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
      gradient: AccordionTheme.citiesRowGradient,
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
      gradient: AccordionTheme.timesRowGradient,
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
      gradient: AccordionTheme.advisoryRowGradient,
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
      gradient: AccordionTheme.languageRowGradient,
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
      gradient: AccordionTheme.normsRowGradient,
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
