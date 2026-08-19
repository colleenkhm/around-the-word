import 'package:flutter/material.dart';

import '../../theme/accordion_theme.dart';

/// One collapsible row of the accordion-style country page. Collapsed:
/// tinted row, title + optional meta. Expanded: [contentBuilder] renders
/// below, or "Coming soon" if [hasData] is false. Every section always
/// renders as a row, regardless of data.
class AccordionSection extends StatelessWidget {
  /// Whether the collapsed-row subheading renders at all. Off for now.
  static const bool showSubheading = false;

  final String title;
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
    required this.title,
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
          title: title,
          meta: hasData ? meta : 'Coming soon',
          tint: tint,
          textColor: textColor,
          expanded: expanded,
          onTap: onToggle,
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
  final String title;
  final String? meta;
  final Color tint;
  final Color textColor;
  final bool expanded;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    required this.meta,
    required this.tint,
    required this.textColor,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          // Hairline is collapsed-only.
          decoration: expanded
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: textColor.withValues(alpha: 0.12),
                    ),
                  ),
                ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      // Thin underline, expanded-only, matching textColor.
                      style: AccordionTheme.secName.copyWith(
                        color: textColor,
                        decoration: expanded ? TextDecoration.underline : null,
                        decorationColor: textColor,
                        decorationThickness: 1.5,
                      ),
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
              _Chevron(expanded: expanded, textColor: textColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final bool expanded;
  final Color textColor;

  const _Chevron({required this.expanded, required this.textColor});

  @override
  Widget build(BuildContext context) {
    // Same outline whether expanded or not; only direction changes.
    return AnimatedContainer(
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
    );
  }
}

/// Expanded-but-no-data state.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Text(
        "Coming soon — we haven't curated this yet.",
        style: AccordionTheme.sBody.copyWith(
          color: AccordionTheme.ink3,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
