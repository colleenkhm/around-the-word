import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../state/trip_selection.dart';
import '../theme/accordion_theme.dart';
import '../widgets/country_page/dashed_divider.dart';
import '../widgets/site_footer.dart';
import '../widgets/site_header.dart';
import 'country_header_preview_screen.dart';

/// Screen 1: "Where to?" — a search-first destination picker.
/// Every country opens the country page, `active` or not — see
/// `CountryHeaderPreviewScreen`. See HANDOFF.md for history.
/// Copy changed to "Tell me about..." 2026-08-31, alongside the
/// Whereabout -> Forin rename; changed back 2026-10-25 alongside the
/// rename back to whereabout. Shortened to "Where to?" 2026-10-27.
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  static const _headingTop = 88.0;
  static const _headingGap = 36.0;

  // Keeps the logo where it sat with the old 56/24 spacing.
  static const _logoLift = (_headingTop - 56 + _headingGap - 24) / 2;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCountry(TripSelection trip, Country country) {
    trip.selectCountry(country);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CountryHeaderPreviewScreen(country: country),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripSelection>();

    if (trip.loadingReferenceData) {
      return const Scaffold(
        backgroundColor: AccordionTheme.logoSkyPale,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = _query.isEmpty
        ? const <Country>[]
        : trip.countries
              .where((c) => c.name.toLowerCase().startsWith(_query.toLowerCase()))
              .toList();

    return Scaffold(
      backgroundColor: AccordionTheme.logoSkyPale,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SiteHeader(backgroundColor: AccordionTheme.logoGreen),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: _headingTop),
                    Text(
                      'Where to?',
                      style: AccordionTheme.pageHeading(
                        31,
                      ).copyWith(color: AccordionTheme.logoGreen),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: _headingGap),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: AccordionTheme.dmSans,
                        color: AccordionTheme.ink,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Search countries',
                        labelStyle: TextStyle(
                          fontFamily: AccordionTheme.dmMono,
                          color: AccordionTheme.ink3,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AccordionTheme.logoGreen,
                        ),
                        filled: true,
                        fillColor: AccordionTheme.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AccordionTheme.logoSkyRule,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AccordionTheme.logoGreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    Expanded(
                      child: results.isNotEmpty
                          ? ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: results.length,
                              separatorBuilder: (context, index) =>
                                  const DashedDivider(
                                    color: AccordionTheme.logoSkyRule,
                                  ),
                              itemBuilder: (context, index) {
                                final country = results[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    country.name,
                                    style: AccordionTheme.rowTitle,
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: AccordionTheme.logoGreen,
                                  ),
                                  onTap: () => _selectCountry(trip, country),
                                );
                              },
                            )
                          // Logo with no search in progress.
                          : Center(
                              child: Transform.translate(
                                offset: const Offset(0, -_logoLift),
                                child: Image.asset(
                                  'assets/branding/whereabout.png',
                                  width: 220,
                                  height: 220,
                                  cacheWidth: 660,
                                  semanticLabel: 'whereabout logo',
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}
