import 'package:flutter/material.dart';

/// Tap-to-flip content — the page's core interaction. Shows [front] (the
/// country's primary language) until tapped, then [back] (English),
/// entirely on its own — there is no page-level "show English" state.
/// Every section title, ticket-header label, and piece of prose on the
/// country page is one of these, each flipping independently, so the
/// page reads as a deck of flashcards rather than one page with a
/// language switch. Safe to nest inside an [AccordionSection] row: that
/// row's own tap-to-expand is scoped to its chevron only, specifically so
/// this can own the rest of the row without a competing gesture. See
/// HANDOFF.md's flashcard_layout entries for how this interaction
/// settled here.
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
