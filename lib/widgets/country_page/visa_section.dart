import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/travel_info.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_date.dart';
import 'external_link.dart';

/// The "Visa & Entry" [AccordionSection]'s expanded content — matches
/// `trip-dashboard-v5.html`'s `.sec-visa` card. Content-only (no heading,
/// no card chrome): [AccordionSection] already renders the section title
/// in its own row, so this just returns the white card body.
///
/// **Split out of the old combined `TravelInfoSection` 2026-08-18**, per
/// the v5 mockup treating Visa & Entry and Travel Advisory as two
/// independent, independently-collapsible sections rather than one shared
/// unit. See [AccordionTheme]'s class doc: this reverses the 2026-08-11
/// "one shared source, not two" call — each section now cites its own
/// source line even when (as for Costa Rica) it's really the same
/// State-Dept page as [TravelAdvisorySection]'s. Simpler than trying to
/// visually connect a shared footer across two cards a reader might
/// collapse independently.
///
/// **No invented "No visa required" headline** — the mockup shows one
/// (`.visa-ok`, bold green), but [VisaInfo] only has a free-text
/// [VisaInfo.summary], no boolean/enum "required or not" field to render
/// that headline from truthfully. Same restraint the pre-split version
/// used; flagged as an open idea in the data architecture doc, not
/// fabricated here.
class VisaSection extends StatelessWidget {
  final VisaInfo visa;
  final RegionalNote? regionalNote;

  /// This section's dark accent — 2026-08-18, colors the source/apply
  /// links and the regional stamp instead of the fixed
  /// `AccordionTheme.skyDark`. See [SectionPalette]'s class doc.
  final Color accent;

  const VisaSection({
    super.key,
    required this.visa,
    required this.accent,
    this.regionalNote,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('For ${visa.nationalityIsoCode} passport holders', style: AccordionTheme.sHead),
              const SizedBox(height: 6),
              Text(visa.summary, style: AccordionTheme.sBody),
              if (regionalNote != null) ...[
                const SizedBox(height: 10),
                _RegionalNoteWarning(summary: regionalNote!.summary),
              ],
              if (visa.prohibitedOnEntry != null || visa.prohibitedOnExit != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.only(top: 11),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AccordionTheme.rule)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visa.prohibitedOnEntry != null)
                        _ProhibitedNote(label: 'Declare on entry', body: visa.prohibitedOnEntry!),
                      if (visa.prohibitedOnEntry != null && visa.prohibitedOnExit != null)
                        const SizedBox(height: 8),
                      if (visa.prohibitedOnExit != null)
                        _ProhibitedNote(label: 'Declare on exit', body: visa.prohibitedOnExit!),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(top: 11),
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AccordionTheme.rule)),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text('Verified ${formatShortDate(visa.lastVerifiedAt)}', style: AccordionTheme.srcRow),
                    ExternalLink(
                      label: 'Official source',
                      url: visa.officialUrl,
                      color: accent,
                      fontFamily: AccordionTheme.dmMono,
                    ),
                    if (visa.applicationUrl != null)
                      ExternalLink(
                        label: 'Apply',
                        url: visa.applicationUrl!,
                        color: accent,
                        fontFamily: AccordionTheme.dmMono,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (regionalNote != null)
          Positioned(
            bottom: 14,
            right: 16,
            child: _RegionalStamp(groupSlug: regionalNote!.groupSlug, accent: accent),
          ),
      ],
    );
  }
}

/// The "upcoming requirement" highlight box — `.visa-warn`.
class _RegionalNoteWarning extends StatelessWidget {
  final String summary;

  const _RegionalNoteWarning({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AccordionTheme.warn.withValues(alpha: 0.08),
        border: Border.all(color: AccordionTheme.warn.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        summary,
        style: AccordionTheme.sBody.copyWith(fontSize: 12.5, color: AccordionTheme.warn),
      ),
    );
  }
}

/// `.visa-stamp` — a rotated corner stamp naming [RegionalNote.groupSlug]
/// (e.g. "Schengen").
class _RegionalStamp extends StatelessWidget {
  final String groupSlug;
  final Color accent;

  const _RegionalStamp({required this.groupSlug, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -5 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Text(
          groupSlug.toUpperCase(),
          style: TextStyle(
            fontFamily: AccordionTheme.dmMono,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: accent.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _ProhibitedNote extends StatelessWidget {
  final String label;
  final String body;

  const _ProhibitedNote({required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AccordionTheme.sLabel.copyWith(color: AccordionTheme.danger),
        ),
        const SizedBox(height: 3),
        Text(body, style: AccordionTheme.sBody),
      ],
    );
  }
}
