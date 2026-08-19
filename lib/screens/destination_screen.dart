import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../state/trip_selection.dart';
import '../theme/accordion_theme.dart';
import '../widgets/country_page/dashed_divider.dart';
import '../widgets/country_page/site_header.dart';
import 'about_screen.dart';
import 'country_header_preview_screen.dart';

/// Screen 1: "Where are you going?" — a single search-first destination
/// picker. Countries aren't grouped by continent in the UI; typing filters
/// the full country list directly. Replaces the old continent-map ->
/// country-map two-screen flow (see HANDOFF.md for why).
///
/// **2026-08-18: every country opens the country page now, `active` or
/// not** — per Colleen: "instead of the coming soon page we should just
/// have a country page showing any available data where the expanded
/// categories say 'coming soon'." `ComingSoonScreen` (the old dead end
/// for inactive countries) is retired from this flow; see
/// `CountryHeaderPreviewScreen`'s class doc for how it renders a country
/// with no curated bundle at all — every accordion section just shows
/// "Coming soon" rather than the page failing to load.
///
/// **2026-08-17: an active country now opens the country page directly**
/// (`CountryHeaderPreviewScreen`, standing in for the real multi-tab
/// `CountryPageScreen` until that's built) instead of going straight to
/// `CategorySelectionScreen`'s "What do you want to learn?" checkboxes.
/// That flow still exists — it's the Language tab's sub-flow now, reached
/// from within the country page, per the pivot-3 docs' five-tab shape — it
/// just isn't the first thing a destination tap leads to anymore.
///
/// **Same chrome as the country page** — `SiteHeader` at the top (About
/// only; no `onHomeTap`, since this *is* home already), matching ticket
/// typography for the title/search/results. `SafeArea(top: false)`
/// deliberately, matching `CountryHeaderPreviewScreen` — `SiteHeader`
/// insets its own content by the status-bar height, so a normal
/// `SafeArea` here would double that gap.
///
/// **2026-08-18: repointed from `CountryTheme` to `AccordionTheme`**, per
/// Colleen: bring the home page's fonts/colors in line with the
/// collapsible-sections country-page restyle (`AccordionTheme`'s class
/// doc) rather than the older navy/gold theme. This reopens the "scoped
/// to just the country page" call from that restyle — confirmed directly
/// this time, not assumed. `PaperTexture` (a warm-parchment-era texture)
/// is dropped along with it, matching the country page's flat page
/// background. Most other screens still inherit the app-wide `CountryTheme`
/// in `main.dart` — this is a second hand-restyled exception, not a
/// site-wide repoint.
///
/// **`SiteHeader` itself now owns its whole look** (colors, fonts, the
/// "Whereabout" wordmark) rather than taking it as constructor params —
/// see that class's doc comment. This screen's call site is just
/// `SiteHeader(onAboutTap: ...)`, no `onHomeTap` since this *is* home
/// already (`SiteHeader` renders a static, non-tappable globe in that
/// case).
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
      MaterialPageRoute(builder: (context) => CountryHeaderPreviewScreen(country: country)),
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
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AccordionTheme.page,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SiteHeader(
              onAboutTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Where are you going?',
                      style: AccordionTheme.pageHeading(28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontFamily: AccordionTheme.dmSans, color: AccordionTheme.ink),
                      decoration: const InputDecoration(
                        labelText: 'Search countries',
                        labelStyle: TextStyle(fontFamily: AccordionTheme.dmMono, color: AccordionTheme.ink3),
                        prefixIcon: Icon(Icons.search, color: AccordionTheme.ink3),
                        // white, not the app-wide theme's default fill
                        // (CountryTheme.card, a cream/tan left over from
                        // the navy/gold theme) — was bleeding through
                        // since this field didn't set its own `filled`/
                        // `fillColor` and inherited main.dart's
                        // InputDecorationTheme, which is exactly the kind
                        // of off-theme mismatch Colleen flagged.
                        filled: true,
                        fillColor: AccordionTheme.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AccordionTheme.rule),
                        ),
                        // ink, not skyDark — a lone blue accent on this
                        // page (nothing else here is blue; skyDark is
                        // reserved for Visa & Entry's own section on the
                        // country page) read as off-theme. Ink ties the
                        // focus ring back to the header/heading/chevron
                        // color already used everywhere else on this page.
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AccordionTheme.ink, width: 1.5),
                        ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    Expanded(
                      child: results.isNotEmpty
                          ? ListView.separated(
                              // Tight top padding — ListTile's own default
                              // padding/min-height was doing most of the
                              // work of the gap Colleen flagged as too
                              // large, not the space between the field and
                              // this list.
                              padding: EdgeInsets.zero,
                              itemCount: results.length,
                              separatorBuilder: (context, index) =>
                                  const DashedDivider(color: AccordionTheme.rule),
                              itemBuilder: (context, index) {
                                final country = results[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(country.name, style: AccordionTheme.rowTitle),
                                  trailing: const Icon(Icons.chevron_right, color: AccordionTheme.ruleDark),
                                  onTap: () => _selectCountry(trip, country),
                                );
                              },
                            )
                          // Decorative filler when there's no search in
                          // progress — just to have a little more on the
                          // page than a bare search field.
                          : Center(
                              child: Icon(
                                Icons.public,
                                size: 160,
                                color: AccordionTheme.ink.withValues(alpha: 0.08),
                              ),
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
