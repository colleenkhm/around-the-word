import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/travel_info.dart';
import '../../theme/accordion_theme.dart';
import '../../utils/format_date.dart';
import 'external_link.dart';
import 'flip_reveal.dart';

/// The "Visa & Entry" [AccordionSection]'s expanded content. No invented
/// "No visa required" headline — [VisaInfo.summary] is free text only.
///
/// **Never wrap an [ExternalLink] (or anything else with its own tap
/// gesture) inside [FlipReveal].** A link's whole point is that tapping
/// it does something (opens a URL); layering a second, independent tap
/// gesture on top of it — as an earlier version of this file did — means
/// a single tap ambiguously both flips the label's language *and* tries
/// to launch the link. Every link on this page shows a static label in
/// the country's primary language instead: it's a control (it has its
/// own icon, `↗`), not a flashcard. See HANDOFF.md's flashcard_layout
/// entries for the fuller reasoning.
class VisaSection extends StatelessWidget {
  final VisaInfo visa;
  final RegionalNote? regionalNote;

  /// This section's dark accent.
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
              Text(visa.issuingAuthority, style: AccordionTheme.sLabel),
              const SizedBox(height: 5),
              FlipReveal(
                front: Text(
                  'Para titulares de pasaporte ${visa.nationalityIsoCode}',
                  style: AccordionTheme.sHead,
                ),
                back: Text(
                  'For ${visa.nationalityIsoCode} passport holders',
                  style: AccordionTheme.sHead,
                ),
              ),
              const SizedBox(height: 6),
              if (visa.summaryLocal != null)
                FlipReveal(
                  front: Text(visa.summaryLocal!, style: AccordionTheme.sBody),
                  back: Text(visa.summary, style: AccordionTheme.sBody),
                )
              else
                Text(visa.summary, style: AccordionTheme.sBody),
              if (visa.applicationUrl != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: ExternalLink(
                    label: 'Solicitar',
                    url: visa.applicationUrl!,
                    color: accent,
                    fontFamily: AccordionTheme.dmMono,
                  ),
                ),
              ],
              if (regionalNote != null) ...[
                const SizedBox(height: 10),
                _RegionalNoteWarning(summary: regionalNote!.summary),
              ],
              if (visa.prohibitedOnEntry != null ||
                  visa.prohibitedOnExit != null)
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
                        _ProhibitedNote(
                          labelEn: 'Declare on entry',
                          labelEs: 'Declarar al ingresar',
                          bodyEn: visa.prohibitedOnEntry!,
                          bodyLocal: visa.prohibitedOnEntryLocal,
                        ),
                      if (visa.prohibitedOnEntry != null &&
                          visa.prohibitedOnExit != null)
                        const SizedBox(height: 8),
                      if (visa.prohibitedOnExit != null)
                        _ProhibitedNote(
                          labelEn: 'Declare on exit',
                          labelEs: 'Declarar al salir',
                          bodyEn: visa.prohibitedOnExit!,
                          bodyLocal: visa.prohibitedOnExitLocal,
                        ),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(top: 11),
                padding: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AccordionTheme.rule)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FlipReveal(
                      front: Text(
                        'Información de visa y entrada verificada el '
                        '${formatShortDate(visa.lastVerifiedAt, spanish: true)}',
                        style: AccordionTheme.srcRow,
                      ),
                      back: Text(
                        'Visa & entry info verified ${formatShortDate(visa.lastVerifiedAt)}',
                        style: AccordionTheme.srcRow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ExternalLink(
                        label: 'Fuente',
                        url: visa.officialUrl,
                        color: accent,
                        fontFamily: AccordionTheme.dmMono,
                      ),
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
            child: _RegionalStamp(
              groupSlug: regionalNote!.groupSlug,
              accent: accent,
            ),
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
        style: AccordionTheme.sBody.copyWith(
          fontSize: 12.5,
          color: AccordionTheme.warn,
        ),
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
  final String labelEn;
  final String labelEs;
  final String bodyEn;

  /// Null when this row has no translation on file — falls back to
  /// showing [bodyEn] on both sides of the label flip, same degrade as
  /// every other `*Local`-backed field on this page.
  final String? bodyLocal;

  const _ProhibitedNote({
    required this.labelEn,
    required this.labelEs,
    required this.bodyEn,
    required this.bodyLocal,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AccordionTheme.sLabel.copyWith(color: AccordionTheme.danger);
    final englishBody = Text(bodyEn, style: AccordionTheme.sBody);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlipReveal(
          front: Text(labelEs.toUpperCase(), style: labelStyle),
          back: Text(labelEn.toUpperCase(), style: labelStyle),
        ),
        const SizedBox(height: 3),
        bodyLocal == null
            ? englishBody
            : FlipReveal(
                front: Text(bodyLocal!, style: AccordionTheme.sBody),
                back: englishBody,
              ),
      ],
    );
  }
}
