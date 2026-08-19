import 'package:flutter/material.dart';

import '../../theme/accordion_theme.dart';
import '../../utils/contrast_color.dart';

/// The app's persistent site-wide nav bar — a "Whereabout" wordmark next to
/// the globe icon on the left, an "About" link on the right. **One fixed
/// look by default** — every screen that shows this shows the same thing,
/// unless it has a real, stated reason not to (see [backgroundColor]).
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
/// file had before** — text/icon color derives automatically via
/// [readableTextColor], so there's exactly one thing a caller can get out
/// of sync, and it's data (a `Color`), not a second hand-copied block of
/// styling code. `null` (every non-country-page caller) keeps the fixed
/// ink look.
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
    final foreground = readableTextColor(background);
    final iconColor = foreground.withValues(alpha: 0.85);
    final aboutStyle = TextStyle(
      fontFamily: AccordionTheme.dmMono,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
      color: foreground,
    );
    final labelStyle = TextStyle(
      fontFamily: AccordionTheme.fraunces,
      fontWeight: FontWeight.w700,
      fontSize: 17,
      letterSpacing: -0.1,
      color: foreground,
    );

    return Container(
      color: background,
      // Vertical 10->16 and horizontal 16->20 (2026-08-18, per Colleen:
      // "add some more padding around any of the text in the header").
      // Top bumped again the same day, 16->24 above topInset (bottom left
      // at 16) — per Colleen: "add more top padding for the header."
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Same plain `Icon` box whether tappable or not — wrapping
              // it in `InkWell` for the tap behavior, rather than
              // swapping to `IconButton`, is what keeps this pixel-
              // identical across every screen (see class doc).
              if (onHomeTap != null)
                Tooltip(
                  message: 'Home',
                  child: InkWell(
                    onTap: onHomeTap,
                    customBorder: const CircleBorder(),
                    child: Icon(Icons.public, size: 22, color: iconColor),
                  ),
                )
              else
                Icon(Icons.public, size: 22, color: iconColor),
              const SizedBox(width: 8),
              Text('Whereabout', style: labelStyle),
            ],
          ),
          if (onAboutTap != null)
            TextButton(
              onPressed: onAboutTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('ABOUT', style: aboutStyle),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
