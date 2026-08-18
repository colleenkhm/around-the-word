import 'package:flutter/material.dart';

import '../../theme/accordion_theme.dart';

/// One collapsible row of the accordion-style country page — matches
/// `trip-dashboard-v5.html`'s `.sec-row` (+ `.card-group` once open).
///
/// **Collapsed**: tinted row showing [title] and, when [hasData] is true,
/// a one-line [meta] subheading ("No visa required · 90 days"). When
/// [hasData] is false the row shows "Coming soon" in place of [meta]
/// instead of leaving the row looking identical to a populated one.
///
/// **Expanded**: the [meta] subheading disappears — per Colleen's mockup,
/// the subheading is collapsed-only — and [contentBuilder] renders below
/// the row. If [hasData] is false, [contentBuilder] is never called;
/// [_ComingSoon] renders instead. **Every section always renders as a
/// row**, regardless of [hasData] — a deliberate difference from the rest
/// of the app's "omit an empty tab rather than show it empty" rule (see
/// client design doc's Screen Flows), which is about whole *tabs*, not
/// sub-sections inside one already-shown page. Confirmed directly by
/// Colleen for this screen: sections should always display if there's
/// data, "coming soon" otherwise — never omitted.
class AccordionSection extends StatelessWidget {
  final String title;
  final String? meta;
  final Color tint;

  /// Overrides [tint] with a gradient fill for the collapsed/header row —
  /// added 2026-08-18 for Visa & Entry specifically (per Colleen: it read
  /// as the same solid sky blue as the ticket stub directly above it).
  /// Matches the mockup's `.sec-visa` background, a pale-blue-to-white
  /// diagonal, rather than the flat pastel every other section uses —
  /// `null` (the default) keeps every other section on its plain [tint].
  final Gradient? gradient;

  final bool expanded;
  final VoidCallback onToggle;
  final bool hasData;
  final WidgetBuilder contentBuilder;

  const AccordionSection({
    super.key,
    required this.title,
    required this.tint,
    required this.expanded,
    required this.onToggle,
    required this.hasData,
    required this.contentBuilder,
    this.meta,
    this.gradient,
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
          gradient: gradient,
          expanded: expanded,
          onTap: onToggle,
        ),
        if (expanded)
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
  final Gradient? gradient;
  final bool expanded;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    required this.meta,
    required this.tint,
    required this.gradient,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: gradient == null ? tint : Colors.transparent,
      child: Ink(
        decoration: gradient == null ? null : BoxDecoration(gradient: gradient),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AccordionTheme.ink.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AccordionTheme.secName),
                      // Subheading is collapsed-only — see class doc.
                      if (!expanded && meta != null && meta!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(meta!, style: AccordionTheme.secMeta),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Chevron(expanded: expanded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final bool expanded;

  const _Chevron({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: expanded ? AccordionTheme.ink : Colors.transparent,
        border: Border.all(
          color: expanded ? AccordionTheme.ink : AccordionTheme.ink.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Icon(
        expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: 16,
        color: expanded ? AccordionTheme.white : AccordionTheme.ink3,
      ),
    );
  }
}

/// The expanded-but-no-data state — see [AccordionSection]'s class doc.
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
