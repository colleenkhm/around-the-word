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
/// **Subheading rendering is off for now** (2026-08-18, per Colleen:
/// "maybe we remove the subheaders or at least hide them for now") — see
/// [showSubheading]. `meta` itself is untouched: every `_xSection()`
/// builder in `CountryHeaderPreviewScreen` still computes and passes it,
/// so flipping [showSubheading] back on needs no other change.
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
  /// Whether the collapsed-row subheading (the [meta] summary, or
  /// "Coming soon") renders at all. **Off for now**, per Colleen — kept
  /// as a named flag rather than deleting the underlying plumbing, the
  /// same pattern `CountryHeaderPreviewScreen._useAccentPageBackground`
  /// already used for a capability kept-but-disabled. See this class's
  /// doc comment.
  static const bool showSubheading = false;

  final String title;
  final String? meta;
  final Color tint;

  /// Black or white, whichever reads on [tint] — see
  /// [SectionColors.textColor]. Colors the title/meta text and the
  /// collapsed-state chevron.
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
          // The perforated tear-line that used to sit here (2026-08-18,
          // three corrections' worth — see HANDOFF.md) is gone again,
          // per Colleen: "remove the perforated lines." The header/body
          // color change itself is the seam now — no divider element at
          // all between a [tint] row and its white content below.
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
          // This hairline is collapsed-only now (2026-08-18) — it used
          // to always render, which meant an expanded row showed it
          // stacked directly above the perforated tear-line below,
          // reading as two redundant dividers ("funky," per Colleen)
          // rather than one clear seam. Collapsed rows still want it:
          // it's what separates one collapsed row from the next.
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
                      style: AccordionTheme.secName.copyWith(color: textColor),
                    ),
                    // Subheading is collapsed-only, and currently off
                    // altogether — see AccordionSection.showSubheading.
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
    // Same outline-only treatment whether expanded or not — per Colleen,
    // 2026-08-18: the solid ink-filled "active" circle this used to
    // switch to on expand was redundant (the open body and the chevron's
    // own up/down direction already say that), so it's dropped rather
    // than kept as a third, competing signal.
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
