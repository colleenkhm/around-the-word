import 'package:flutter/material.dart';

import '../../theme/accordion_theme.dart';

/// The app's persistent site-wide nav bar — a "Whereabout" wordmark next to
/// the globe icon. **One fixed look by default** — every screen that shows
/// this shows the same thing, unless it has a real, stated reason not to
/// (see [backgroundColor]).
///
/// **2026-08-18: the wordmark itself is the nav now, not a separate right-
/// side link** — per Colleen: globe + "Where" opens [onHomeTap]; "about"
/// (the second half of the same word) opens [onAboutTap]. The standalone
/// "ABOUT" link that used to sit on the right is gone — it was a duplicate
/// destination once "about" was tappable in the wordmark itself.
///
/// **Two fixed colors, not [foreground]-derived ones** — "Where" is plain
/// white, "about" is [AccordionTheme.page] (the light lavender-grey that's
/// the country-search page's own background, reused here as a color, not
/// a background). Colleen's first idea was literal black for "about," but
/// caught it herself: [backgroundColor] is always dark here (the fixed
/// `AccordionTheme.ink` default, or a [SectionPalette.header] deepened
/// color — never anything light), so black would disappear into it rather
/// than read as a second tone. `AccordionTheme.page` gives the same
/// two-tone effect while staying visible against either.
///
/// **2026-08-18: collapsed back down to just `onHomeTap`/`onAboutTap`.**
/// Colors, fonts, and the "Whereabout" label used to be constructor
/// params — added when the country page's accordion restyle needed an
/// ink-themed instance distinct from this file's original navy default,
/// then copy-pasted identically into `DestinationScreen`'s call site once
/// it wanted the same look. That duplication is exactly what caused the
/// icon-to-wordmark gap bug the same day (the two call sites' `onHomeTap`
/// branches quietly diverged — `IconButton` vs. a bare `Icon` — because
/// nothing forced them to stay in sync being two separate blocks of
/// styling code). Per Colleen: "we shouldn't be having separate code for
/// this on different pages regardless." Since every real consumer wants
/// the identical visual treatment now — confirmed, not assumed, this is a
/// site-wide nav bar — that treatment belongs in this file once, not
/// passed in twice.
///
/// **[backgroundColor] reopened that, later the same day, for a real
/// reason** — `CountryHeaderPreviewScreen`'s masthead became a per-country
/// deepened flag color (`SectionPalette.header`) instead of flat
/// `AccordionTheme.ink`, and the site nav directly above it needs to
/// match for the two to read as one continuous surface (see
/// design-preferences.md's "structural chrome" note on that seam).
/// Deliberately **one color in, not the five separate style params this
/// file had before** — there's exactly one thing a caller can get out of
/// sync, and it's data (a `Color`), not a second hand-copied block of
/// styling code. `null` (every non-country-page caller) keeps the fixed
/// ink look. Text/icon colors themselves are the two fixed tones from the
/// note above, not derived from [backgroundColor] — see that note on why
/// that's safe given what [backgroundColor] is ever actually set to.
///
/// Deliberately a separate widget from [CountryHeader], not a row inside
/// it — split out 2026-08-17 so *site* chrome (globe/About, same on every
/// country) isn't tangled up with *page* chrome (this specific country's
/// flag, name, ticket stub) in one build method.
class SiteHeader extends StatelessWidget {
  final VoidCallback? onHomeTap;
  final VoidCallback? onAboutTap;
  final Color? backgroundColor;

  const SiteHeader({
    super.key,
    this.onHomeTap,
    this.onAboutTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // This is the topmost widget on every screen that uses it (each
    // wraps its body in `SafeArea(top: false)`), so it's the one that
    // owns status-bar/notch clearance. Same capped-at-32-not-the-full-
    // inset trade-off as before: a first pass at the full device inset
    // (~59px on Dynamic Island) read as too much empty space; 16 was
    // then a touch tight; 32 is the settled value. Worth a real-device
    // look to confirm the globe/About icons don't sit under the system
    // clock/battery, since nothing here can render that.
    final topInset = MediaQuery.paddingOf(context).top.clamp(0.0, 32.0);
    final background = backgroundColor ?? AccordionTheme.ink;
    final iconColor = Colors.white.withValues(alpha: 0.85);
    final whereStyle = const TextStyle(
      fontFamily: AccordionTheme.fraunces,
      fontWeight: FontWeight.w700,
      fontSize: 17,
      letterSpacing: -0.1,
      color: Colors.white,
    );
    // "about"'s own tone — AccordionTheme.page, not black. See class doc.
    final aboutStyle = whereStyle.copyWith(color: AccordionTheme.page);

    return Container(
      color: background,
      // Vertical 10->16 and horizontal 16->20 (2026-08-18, per Colleen:
      // "add some more padding around any of the text in the header").
      // Top bumped again the same day, 16->24 above topInset. Bottom
      // brought back down, 16->10 (2026-08-19) — per Colleen, this plus
      // CountryHeader's own masthead top padding were compounding into
      // "a lot of space between site nav and destination."
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 10),
      // Default (max) mainAxisSize, not min — per Colleen, 2026-08-18:
      // `min` shrank this Row to just its own content width, which
      // shrank this Container along with it (nothing else here declares
      // an explicit width) — the header background stopped covering the
      // full width of the screen, not just "whereabout" reading as
      // pushed left. Default mainAxisAlignment (start) still keeps the
      // content itself flush left; only the *background* needed to
      // reach full width.
      child: Row(
        children: [
          // Same plain `Icon`/`Text` whether tappable or not — wrapping
          // in `InkWell` for the tap behavior, rather than swapping
          // widget types, is what keeps this pixel-identical across
          // every screen (see class doc).
          _tappable(
            onTap: onHomeTap,
            tooltip: 'Home',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 22, color: iconColor),
                const SizedBox(width: 8),
                Text('Where', style: whereStyle),
              ],
            ),
          ),
          _tappable(
            onTap: onAboutTap,
            tooltip: 'About',
            child: Text('about', style: aboutStyle),
          ),
        ],
      ),
    );
  }

  /// Wraps [child] in a tappable region when [onTap] is non-null, or
  /// returns it bare otherwise — the same "one shared shape, tappable or
  /// not" rule the globe icon used before this split the wordmark into
  /// two independently-tappable halves.
  Widget _tappable({
    required VoidCallback? onTap,
    required String tooltip,
    required Widget child,
  }) {
    if (onTap == null) return child;
    return Tooltip(
      message: tooltip,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
