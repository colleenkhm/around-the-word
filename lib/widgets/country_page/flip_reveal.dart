import 'package:flutter/material.dart';

/// Tap-to-flip content — the page's core interaction, and the primary
/// reason this app exists (per direction received: "this is going to be
/// the draw to this app"). Shows [front] (the country's primary
/// language) until tapped, then [back] (English), entirely on its own —
/// there is no page-level "show English" state. Every section title,
/// ticket-header label, and piece of prose on the country page is one of
/// these, each flipping independently, so the page reads as a deck of
/// flashcards rather than one page with a language switch.
///
/// **The governing rule, stated plainly:** a tap either changes the
/// language, or it does something else — never both, and there is no
/// third option. That means two things in practice:
///
/// 1. **Every other tappable thing on the page (the accordion chevron,
///    an [ExternalLink], a row that navigates somewhere) must carry its
///    own distinct visual marker — almost always an icon** (the chevron
///    circle, a link's `↗`) — so it reads as a control, not prose, before
///    it's ever tapped. Nothing here enforces that automatically; it's a
///    design convention to keep honoring at every new call site.
/// 2. **Never put [front] or [back] on something that already has its
///    own tap behavior.** [ExternalLink] and anything like it must never
///    go inside a `FlipReveal` — a link's whole job is that tapping it
///    does something, and layering this widget's own tap gesture on top
///    means a single tap ambiguously both flips the label *and* fires
///    the link. (An earlier version of this file did exactly that, on
///    four different links, before the bug was caught.) A link's label
///    is either a static string, or two full separate widgets swapped by
///    something other than a shared tap zone — never a `FlipReveal`.
///
/// Safe to nest inside an [AccordionSection] row specifically because
/// that row's own tap-to-expand is scoped to its chevron only, not the
/// row — the one collision this rule exists to prevent already got fixed
/// once at the row level; rule 2 above is the same fix applied to every
/// smaller case since. See HANDOFF.md's flashcard_layout entries for the
/// full history.
class FlipReveal extends StatefulWidget {
  final Widget front;
  final Widget back;

  const FlipReveal({super.key, required this.front, required this.back});

  @override
  State<FlipReveal> createState() => _FlipRevealState();
}

class _FlipRevealState extends State<FlipReveal> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showBack = !_showBack),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topLeft,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(_showBack),
            child: _showBack ? widget.back : widget.front,
          ),
        ),
      ),
    );
  }
}
