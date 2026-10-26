import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:shared_theme/shared_theme.dart';

import '../data/currency_service.dart';
import '../data/supabase_country_repository.dart';
import '../models/country.dart' as country_model;
import '../models/country_bundle.dart';
import '../models/country_guide.dart';
import '../models/live_data.dart';
import '../models/resource.dart';
import '../models/travel_info.dart';
import '../state/trip_selection.dart';
import '../theme/section_palette.dart';
import '../utils/flag_palette.dart' show extractFlagBaseColors;
import 'destination_screen.dart';
import '../widgets/country_page/additional_resources_section.dart';
import '../widgets/country_page/best_times_section.dart';
import '../widgets/country_page/cities_section.dart';
import '../widgets/country_page/country_header.dart';
import '../widgets/country_page/fact_card_content.dart';
import '../widgets/country_page/language_pair_section.dart';
import '../widgets/country_page/border_countries_section.dart';
import '../widgets/country_page/paper_texture.dart';
import '../widgets/country_page/postage_card.dart';
import '../widgets/country_page/practical_norms_section.dart';
import '../widgets/country_page/travel_advisory_section.dart';
import '../widgets/country_page/visa_section.dart';
import '../widgets/site_footer.dart';
import '../widgets/site_header.dart';

/// The country page — a grid of flip/open cards under the masthead. See
/// HANDOFF.md for the full decision history.
class CountryHeaderPreviewScreen extends StatefulWidget {
  final country_model.Country country;

  const CountryHeaderPreviewScreen({super.key, required this.country});

  @override
  State<CountryHeaderPreviewScreen> createState() =>
      _CountryHeaderPreviewScreenState();
}

class _CountryHeaderPreviewScreenState
    extends State<CountryHeaderPreviewScreen> {
  CountryBundle? _bundle;

  // Live USD rate, fetched once the bundle's currency is known. Null
  // renders an em dash — never a mock/stale value.
  ExchangeRate? _exchangeRate;

  // Falls back to hand-picked defaults until flag colors load.
  SectionPalette _palette = SectionPalette.fallback;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPalette();
  }

  Future<void> _loadPalette() async {
    final colors = await extractFlagBaseColors(widget.country.countryCode);
    if (colors == null || colors.isEmpty || !mounted) return;
    setState(() => _palette = SectionPalette.fromFlagColors(colors));
  }

  Future<void> _load() async {
    final code = widget.country.countryCode.toLowerCase();

    CountryBundle? supabaseBundle;
    try {
      supabaseBundle = await SupabaseCountryRepository().fetchCountryBundle(
        widget.country.countryCode,
      );
    } catch (error) {
      debugPrint('Supabase fetch failed for $code: $error');
    }

    // Supabase's own curated content wins outright when it has any. Else,
    // prefer a local mock bundle if one actually exists (today, only
    // Costa Rica). Else, still show whatever Supabase has — even
    // commodity-only facts (timezone, currency, capital, cities,
    // neighbors) are real and available, and every country's page is
    // reachable from search regardless of curation status, so per
    // direction received: "I would like them to see any information that
    // is available to them" rather than an empty shell just because
    // nothing curated exists yet.
    if (supabaseBundle != null && _hasCuratedContent(supabaseBundle)) {
      setState(() => _bundle = supabaseBundle);
      _loadExchangeRate();
      return;
    }

    try {
      final raw = await rootBundle.loadString('assets/data/bundles/$code.json');
      setState(() {
        _bundle = CountryBundle.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      });
      _loadExchangeRate();
      return;
    } catch (_) {
      // No local mock bundle for this country — fall through.
    }

    if (supabaseBundle != null) {
      setState(() => _bundle = supabaseBundle);
      _loadExchangeRate();
      return;
    }

    debugPrint('No data anywhere for $code — showing an empty shell.');
    setState(() => _bundle = _emptyBundle(widget.country));
    _loadExchangeRate();
  }

  bool _hasCuratedContent(CountryBundle bundle) =>
      !bundle.guide.isEmpty ||
      bundle.advisories.isNotEmpty ||
      bundle.visa != null ||
      bundle.words.isNotEmpty;

  Future<void> _loadExchangeRate() async {
    final currencyCode = _bundle?.facts.currencyCode;
    if (currencyCode == null) return;
    final rate = await CurrencyService().fetchRate(currencyCode);
    if (!mounted) return;
    setState(() => _exchangeRate = rate);
  }

  // Empty shell so every section shows "Coming soon."
  CountryBundle _emptyBundle(country_model.Country country) {
    return CountryBundle(
      country: Country(
        id: country.countryCode.toLowerCase(),
        isoCode: country.countryCode,
        nameCommon: country.name,
        nameOfficial: country.name,
        contentStatus: ContentStatus.none,
      ),
      facts: const CountryFacts(languages: []),
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

  // US State Dept only for now.
  List<TravelAdvisory> _usAdvisories(CountryBundle bundle) => bundle.advisories
      .where((a) => a.issuingAuthority == 'US State Department')
      .toList();

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    final trip = context.watch<TripSelection>();
    final resources = trip.resources;
    return Scaffold(
      backgroundColor: AccordionTheme.page,
      body: bundle == null
          ? const Center(child: CircularProgressIndicator())
          : PaperTexture(
              color: AccordionTheme.ink,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SiteHeader(
                      // Clears the nav stack.
                      onHomeTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const DestinationScreen(),
                        ),
                        (route) => false,
                      ),
                      // Matches the masthead below.
                      backgroundColor: _palette.header.tint,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CountryHeader(
                              bundle: bundle,
                              nativeName: widget.country.countryCode == 'CR'
                                  ? 'Costa Rica'
                                  : null,
                              nativeNameRomanized: null,
                              header: _palette.header,
                            ),
                            _cardGrid(bundle, trip.countries, resources),
                            const SiteFooter(),
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

  // --- Cards --------------------------------------------------------------

  Widget _cardGrid(
    CountryBundle bundle,
    List<country_model.Country> allCountries,
    List<Resource> resources,
  ) {
    final advisories = _usAdvisories(bundle);
    final advisory = advisories.isEmpty ? null : advisories.first;
    final hasTime =
        bundle.facts.timezone != null || bundle.facts.utcOffsetMinutes != null;
    final languages = bundle.facts.languages;
    final featuredWord = bundle.words.isEmpty ? null : bundle.words.first;
    final borderCodes = bundle.facts.borderingCountryCodes;

    // face shows up front, back flips, sheet opens.
    final specs = <_CardSpec>[
      _CardSpec(
        'Local Time',
        Icons.schedule,
        hasTime,
        face: (colors) => LocalTimeFacts(
          timezone: bundle.facts.timezone,
          utcOffsetMinutes: bundle.facts.utcOffsetMinutes,
          latitude: bundle.facts.latitude,
          ink: colors.textColor,
        ),
      ),
      _CardSpec(
        'Currency',
        Icons.payments_outlined,
        bundle.facts.currencyCode != null,
        face: (colors) => CurrencyFacts(
          // Live; null until it resolves, never a mock value.
          rate: _exchangeRate,
          currencyName: bundle.facts.currencyName,
          ink: colors.textColor,
        ),
      ),
      _CardSpec(
        'Travel Advisory',
        Icons.shield_outlined,
        advisory != null,
        face: (colors) =>
            AdvisoryLevelFacts(advisory: advisory!, ink: colors.textColor),
        back: (colors) => AdvisorySummaryBack(
          advisory: advisory!,
          accent: colors.accentOnWhite,
          onReadMore: () => showPostageSheet(
            context,
            title: 'Travel Advisory',
            icon: Icons.shield_outlined,
            colors: colors,
            builder: (_) => TravelAdvisorySection(
              advisories: advisories,
              emergencyNumber: bundle.facts.emergencyNumber,
              accent: colors.accentOnWhite,
            ),
          ),
        ),
      ),
      _CardSpec(
        'Visa & Entry',
        Icons.badge_outlined,
        bundle.visa != null,
        sheet: (colors) => VisaSection(
          visa: bundle.visa!,
          regionalNote: bundle.regionalNote,
          accent: colors.accentOnWhite,
        ),
      ),
      _CardSpec(
        'Language',
        Icons.translate,
        languages.isNotEmpty || featuredWord != null,
        sheet: (colors) => LanguagePairSection(
          languages: languages,
          featuredWord: featuredWord,
          tint: colors.tint,
          textColor: colors.textColor,
          accentOnWhite: colors.accentOnWhite,
        ),
      ),
      _CardSpec(
        'When to Visit',
        Icons.wb_sunny_outlined,
        bundle.guide.bestTimes.isNotEmpty,
        sheet: (colors) => BestTimesSection(
          bestTimes: bundle.guide.bestTimes,
          palette: _palette.cycle,
        ),
      ),
      _CardSpec(
        'Cities',
        Icons.location_city,
        bundle.cities.isNotEmpty,
        sheet: (colors) => CitiesSection(
          cities: bundle.cities,
          capital: bundle.facts.capital,
          accent: colors.accentOnWhite,
        ),
      ),
      _CardSpec(
        'Border Countries',
        Icons.map_outlined,
        borderCodes.isNotEmpty,
        sheet: (colors) => BorderCountriesSection(
          borderingCountryCodes: borderCodes,
          allCountries: allCountries,
          accent: colors.accentOnWhite,
          onTapBorderCountry: (country) {
            context.read<TripSelection>().selectCountry(country);
            final navigator = Navigator.of(context);
            navigator.pop(); // the sheet
            navigator.push(
              MaterialPageRoute(
                builder: (context) =>
                    CountryHeaderPreviewScreen(country: country),
              ),
            );
          },
        ),
      ),
      _CardSpec(
        'Practical Norms',
        Icons.tips_and_updates_outlined,
        bundle.guide.practicalNorms.isNotEmpty,
        sheet: (colors) => PracticalNormsSection(
          norms: bundle.guide.practicalNorms,
          tint: colors.tint,
          textColor: colors.textColor,
        ),
      ),
      _CardSpec(
        'Resources',
        Icons.link,
        resources.isNotEmpty,
        sheet: (colors) => AdditionalResourcesSection(
          resources: resources,
          accent: colors.accentOnWhite,
        ),
      ),
    ];

    final cycle = _palette.cycle;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
            // Stagger rows so colors don't stack into solid columns.
            final period = _cyclePeriod(cycle);
            final stagger = period > 1 && columns % period == 0;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              // Fixed height: content doesn't grow with card width.
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                mainAxisExtent: 160,
              ),
              children: [
                for (var i = 0; i < specs.length; i++)
                  _card(
                    specs[i],
                    cycle[(i + (stagger ? i ~/ columns : 0)) % cycle.length],
                    i,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(_CardSpec spec, SectionColors colors, int index) {
    final sheet = spec.sheet;
    final back = spec.back;
    final face = spec.face;
    return PostageCard(
      title: spec.title,
      icon: spec.icon,
      colors: colors,
      hasData: spec.hasData,
      tiltDegrees: postageCardTilts[index % postageCardTilts.length],
      face: face == null ? null : (_) => face(colors),
      back: back == null ? null : (_) => back(colors),
      onOpen: sheet == null
          ? null
          : () => showPostageSheet(
              context,
              title: spec.title,
              icon: spec.icon,
              colors: colors,
              builder: (_) => sheet(colors),
            ),
    );
  }

  // Number of distinct colors before the cycle repeats.
  static int _cyclePeriod(List<SectionColors> cycle) {
    for (var p = 1; p < cycle.length; p++) {
      var repeats = true;
      for (var i = p; i < cycle.length; i++) {
        if (cycle[i].tint != cycle[i % p].tint) {
          repeats = false;
          break;
        }
      }
      if (repeats) return p;
    }
    return cycle.length;
  }
}

class _CardSpec {
  final String title;
  final IconData icon;
  final bool hasData;
  final Widget Function(SectionColors colors)? face;
  final Widget Function(SectionColors colors)? back;
  final Widget Function(SectionColors colors)? sheet;

  const _CardSpec(
    this.title,
    this.icon,
    this.hasData, {
    this.face,
    this.back,
    this.sheet,
  });
}
