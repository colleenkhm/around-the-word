import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// The app's persistent site-wide nav bar — a globe icon (always back to
/// the "Where are you going?" destination screen) on the left, an "About"
/// link on the right.
///
/// Deliberately a separate widget from [CountryHeader], not a row inside
/// it — split out 2026-08-17 so *site* chrome (globe/About, same on every
/// country) isn't tangled up with *page* chrome (this specific country's
/// flag, name, ticket stub) in one build method, even though (see below)
/// they currently render as the same color.
///
/// **Navy, not gold.** Briefly tried gold — distinct from CountryHeader's
/// navy on purpose, the reasoning at the time being that *site* and *page*
/// chrome should look visually separate — but per Colleen that read as
/// "still weird," and the real ask underneath both rounds of feedback
/// turned out to be the opposite: one continuous navy surface from here
/// through `CountryHeader`'s ticket stub, not a deliberately-different
/// accent color up top. The thin gold/navyMid `_TopStripe` inside
/// `CountryHeader` is the only remaining seam between the two — enough to
/// mark where site chrome ends and page chrome begins without breaking
/// the surface into visibly separate blocks.
class SiteHeader extends StatelessWidget {
  final VoidCallback? onHomeTap;
  final VoidCallback? onAboutTap;

  const SiteHeader({super.key, this.onHomeTap, this.onAboutTap});

  @override
  Widget build(BuildContext context) {
    // This is the topmost widget on the country page (the screen wraps
    // everything in `SafeArea(top: false)`), so it's the one that owns
    // status-bar/notch clearance now — CountryHeader no longer bleeds
    // behind the notch itself. Same capped-at-32-not-the-full-inset
    // trade-off as before: a first pass at the full device inset (~59px
    // on Dynamic Island) read as too much empty space; 16 was then a
    // touch tight; 32 is the settled value. Worth a real-device look to
    // confirm the globe/About icons don't sit under the system clock/
    // battery, since nothing here can render that.
    final topInset = MediaQuery.paddingOf(context).top.clamp(0.0, 32.0);

    return Container(
      color: CountryTheme.navy,
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onHomeTap != null)
            IconButton(
              onPressed: onHomeTap,
              icon: const Icon(Icons.public),
              iconSize: 20,
              color: CountryTheme.onNavySoft,
              tooltip: 'Home',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const SizedBox.shrink(),
          if (onAboutTap != null)
            TextButton(
              onPressed: onAboutTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'ABOUT',
                style: CountryTheme.pillLabel.copyWith(
                  color: CountryTheme.onNavySoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
