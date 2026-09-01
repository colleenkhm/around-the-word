import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../state/trip_selection.dart';
import '../theme/accordion_theme.dart';
import '../widgets/country_page/dashed_divider.dart';
import '../widgets/site_footer.dart';
import '../widgets/site_header.dart';
import 'country_header_preview_screen.dart';

/// Screen 1: "Tell me about..." — a search-first destination picker.
/// Every country opens the country page, `active` or not — see
/// `CountryHeaderPreviewScreen`. See HANDOFF.md for history.
/// Copy changed from "Where are you going?" 2026-08-31, alongside the
/// Whereabout -> Forin rename.
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
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
        backgroundColor: AccordionTheme.page,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = _query.isEmpty
        ? const <Country>[]
        : trip.countries
              .where((c) => c.name.toLowerCase().startsWith(_query.toLowerCase()))
              .toList();

    return Scaffold(
      backgroundColor: AccordionTheme.page,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SiteHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Tell me about...',
                      style: AccordionTheme.pageHeading(31),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
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
                          color: AccordionTheme.ink3,
                        ),
                        filled: true,
                        fillColor: AccordionTheme.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AccordionTheme.rule),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AccordionTheme.ink,
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
                                    color: AccordionTheme.rule,
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
                                    color: AccordionTheme.ruleDark,
                                  ),
                                  onTap: () => _selectCountry(trip, country),
                                );
                              },
                            )
                          // Decorative filler with no search in progress.
                          : Center(
                              child: Icon(
                                Icons.public,
                                size: 160,
                                color: AccordionTheme.ink.withValues(
                                  alpha: 0.08,
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
