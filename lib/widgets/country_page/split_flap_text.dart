import 'package:flutter/material.dart';

import '../../theme/country_theme.dart';

/// Renders [text] as a row of individual split-flap "flap" cells — the
/// country name's display style, mimicking a mechanical airport
/// departures board. Added 2026-08-11 to lean into the travel-nostalgia
/// direction Colleen asked for, alongside the MRZ strip's amber board
/// panel and the perforated section dividers (see [TicketPerforation]) —
/// all three share the same board/ticket visual language.
///
/// **Wraps, doesn't shrink or scroll** — a long country name (e.g. "Bosnia
/// and Herzegovina") spills onto a second row of cells via [Wrap], the
/// same way a real split-flap sign runs a long destination across more
/// than one row rather than cramming it into one. Simpler than fitting a
/// dynamic-width single-line layout, and arguably more evocative of the
/// real thing than a shrink-to-fit label would be.
///
/// Spaces render as a blank (uncolored) gap the same width as a letter
/// cell, not as a collapsed gap — a real board's blank flaps still take
/// up a physical slot.
class SplitFlapText extends StatelessWidget {
  final String text;
  final double fontSize;

  const SplitFlapText({super.key, required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final char in text.toUpperCase().split(''))
          _FlapCell(char: char, fontSize: fontSize),
      ],
    );
  }
}

class _FlapCell extends StatelessWidget {
  final String char;
  final double fontSize;

  const _FlapCell({required this.char, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final isBlank = char.trim().isEmpty;
    final width = fontSize * 0.72;
    final height = fontSize * 1.15;

    if (isBlank) return SizedBox(width: width, height: height);

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CountryTheme.boardBg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            char,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontWeight: FontWeight.w600,
              fontSize: fontSize * 0.64,
              height: 1,
              color: CountryTheme.boardAmber,
            ),
          ),
          // The flap's physical center crease — where a real split-flap
          // character splits into its top and bottom half. Positioned
          // (not Align) so it actually stretches edge to edge — a bare
          // Container has no intrinsic width to size itself by.
          const Positioned(
            left: 0,
            right: 0,
            child: SizedBox(height: 1, child: ColoredBox(color: CountryTheme.boardSeam)),
          ),
        ],
      ),
    );
  }
}
