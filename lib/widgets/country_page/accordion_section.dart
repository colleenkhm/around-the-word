import 'package:flutter/material.dart';

import '../../theme/accordion_theme.dart';
import 'flip_reveal.dart';

/// One collapsible row of the accordion-style country page. Collapsed:
/// tinted row, title + optional meta. Expanded: [contentBuilder] renders
/// below, or "Coming soon" if [hasData] is false. Every section always
/// renders as a row, regardless of data.
///
/// **Tap targets are split on purpose**: only the chevron expands or
/// collapses the row. The title itself is a [FlipReveal] flashcard (tap
/// it to see its English name) — the two gestures used to share the same
/// tap zone (the whole row), which meant tapping the title to flip its
/// language also expanded the section. Scoping expand/collapse to the
/// chevron specifically frees the rest of the row for the page's real
/// primary function: everything on it is a flashcard. See HANDOFF.md's
/// flashcard_layout entries.
class AccordionSection extends StatelessWidget {
  /// Whether the collapsed-row subheading renders at all. Off for now.
  static const bool showSubheading = false;

  final String titleEn;
  final String titleEs;
  final String? meta;
  final Color tint;

  /// Black or white, whichever reads on [tint].
  final Color textColor;

  final bool expanded;
  final VoidCallback onToggle;
  final bool hasData;
  final WidgetBuilder contentBuilder;

  const AccordionSection({
    super.key,
    required this.titleEn,
    required this.titleEs,
    required this.tint,
    required this.textColor,
    required this.expanded,
    required this.onToggle,
    required this.hasData,
    required this.contentBuilder,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(
          titleEn: titleEn,
          titleEs: titleEs,
          meta: hasData ? meta : null,
          tint: tint,
          textColor: textColor,
          expanded: expanded,
          onToggle: onToggle,
        ),
        if (expanded)
          // Color change is the seam; no divider between row and body.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AccordionTheme.white,
              border: Border(bottom: BorderSide(color: AccordionTheme.rule)),
            ),
            child: hasData ? contentBuilder(context) : const _ComingSoon(),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String titleEn;
  final String titleEs;
  final String? meta;
  final Color tint;
  final Color textColor;
  final bool expanded;
  final VoidCallback onToggle;

  const _Row({
    required this.titleEn,
    required this.titleEs,
    required this.meta,
    required this.tint,
    required this.textColor,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = AccordionTheme.secName.copyWith(
      color: textColor,
      // Thin underline, expanded-only, matching textColor.
      decoration: expanded ? TextDecoration.underline : null,
      decorationColor: textColor,
      decorationThickness: 1.5,
    );

    return ColoredBox(
      color: tint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        // Hairline is collapsed-only.
        decoration: expanded
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: textColor.withValues(alpha: 0.12)),
                ),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlipReveal(
                    front: Text(titleEs, style: titleStyle),
                    back: Text(titleEn, style: titleStyle),
                  ),
                  if (AccordionSection.showSubheading &&
                      !expanded &&
                      meta != null &&
                      meta!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta!,
                      style: AccordionTheme.secMeta.copyWith(
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Chevron(
              // Keyed by the (stable, English) title so tests — and
              // nothing else — can target one row's expand/collapse tap
              // target specifically, now that it's no longer the whole row.
              key: ValueKey('chevron-$titleEn'),
              expanded: expanded,
              textColor: textColor,
              onTap: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final bool expanded;
  final Color textColor;
  final VoidCallback onTap;

  const _Chevron({super.key, required this.expanded, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Same outline whether expanded or not; only direction changes. The
    // one tap target that actually expands/collapses the row — see this
    // file's class doc.
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: textColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 18,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// Expanded-but-no-data state — itself a flashcard, same as everything
/// else on the page.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    final style = AccordionTheme.sBody.copyWith(
      color: AccordionTheme.ink3,
      fontStyle: FontStyle.italic,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: FlipReveal(
        front: Text('Próximamente — todavía no hemos preparado este contenido.', style: style),
        back: Text("Coming soon — we haven't curated this yet.", style: style),
      ),
    );
  }
}
