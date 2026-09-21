import 'package:flutter/material.dart';

import '../../models/country_bundle.dart';
import '../../models/language_content.dart';
import '../../theme/accordion_theme.dart';

/// The "Language" [AccordionSection]'s expanded content — a country's
/// languages (official and commonly-spoken-but-not) side by side with a
/// "Word of the day" card. Content-only, no card chrome or heading.
class LanguagePairSection extends StatelessWidget {
  final List<LanguageEntry> languages;
  final Word? featuredWord;

  /// This section's flag color.
  final Color tint;

  /// Black or white, whichever reads on [tint].
  final Color textColor;

  /// A version of [tint] guaranteed to read on white.
  final Color accentOnWhite;

  const LanguagePairSection({
    super.key,
    required this.languages,
    required this.tint,
    required this.textColor,
    required this.accentOnWhite,
    this.featuredWord,
  });

  @override
  Widget build(BuildContext context) {
    final showLanguages = languages.isNotEmpty;
    final showWord = featuredWord != null;
    if (!showLanguages && !showWord) return const SizedBox.shrink();

    final languagesCard = showLanguages
        ? _LanguagesCard(languages: languages, tint: tint, textColor: textColor)
        : null;
    final wordCard = showWord
        ? _WordOfDayCard(
            word: featuredWord!,
            languageName: showLanguages ? languages.first.name : null,
            accent: accentOnWhite,
          )
        : null;

    if (showLanguages && showWord) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: languagesCard!),
            Container(width: 1, color: AccordionTheme.rule),
            Expanded(child: wordCard!),
          ],
        ),
      );
    }
    return languagesCard ?? wordCard!;
  }
}

class _LanguagesCard extends StatelessWidget {
  final List<LanguageEntry> languages;
  final Color tint;
  final Color textColor;

  const _LanguagesCard({required this.languages, required this.tint, required this.textColor});

  /// Official languages first, then by [LanguageEntry.percentSpeakers]
  /// descending (no-data entries last) — and English always present, even
  /// when the source data has no entry for it, so a traveler can always
  /// see at a glance whether it's spoken here. Only runs once there's at
  /// least one real language on record; a country with none yet still
  /// reads "coming soon" rather than showing English alone.
  List<LanguageEntry> get _displayLanguages {
    final sorted = [...languages]..sort((a, b) {
      if (a.isOfficial != b.isOfficial) return a.isOfficial ? -1 : 1;
      return (b.percentSpeakers ?? -1).compareTo(a.percentSpeakers ?? -1);
    });
    final hasEnglish = sorted.any((l) => l.name.toLowerCase() == 'english');
    if (!hasEnglish) sorted.add(const LanguageEntry(name: 'English', isOfficial: false));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final display = _displayLanguages;
    return ColoredBox(
      color: tint,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LANGUAGES', style: AccordionTheme.sLabel.copyWith(color: textColor.withValues(alpha: 0.75))),
            const SizedBox(height: 8),
            for (var i = 0; i < display.length; i++) ...[
              if (i != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(height: 1, color: textColor.withValues(alpha: 0.15)),
                ),
              _LanguageRow(entry: display[i], textColor: textColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final LanguageEntry entry;
  final Color textColor;

  const _LanguageRow({required this.entry, required this.textColor});

  static String _formatPercent(double percent) {
    final rounded = percent == percent.roundToDouble()
        ? percent.round().toString()
        : percent.toStringAsFixed(1);
    return '$rounded%';
  }

  @override
  Widget build(BuildContext context) {
    final percent = entry.percentSpeakers;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry.name, style: AccordionTheme.rowTitle.copyWith(color: textColor))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  entry.isOfficial ? 'official' : 'unofficial',
                  style: TextStyle(
                    fontFamily: AccordionTheme.dmMono,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          // No bar when there's no sourced figure — an empty/zero-filled
          // bar would misrepresent "we don't know" as "basically none".
          if (percent != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.5),
                    child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: textColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(textColor.withValues(alpha: 0.85)),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _formatPercent(percent),
                  style: TextStyle(
                    fontFamily: AccordionTheme.dmMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
          if (entry.usageNote != null) ...[
            const SizedBox(height: 3),
            Text(
              entry.usageNote!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AccordionTheme.dmMono,
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: textColor.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WordOfDayCard extends StatelessWidget {
  final Word word;

  /// First official language, if known — feeds the "Learn ___" label.
  final String? languageName;

  final Color accent;

  const _WordOfDayCard({required this.word, required this.accent, this.languageName});

  @override
  Widget build(BuildContext context) {
    // Inset ring: outer white fill for the gap, inner bordered box for the ring.
    return Container(
      color: AccordionTheme.white,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: AccordionTheme.white,
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WORD OF THE DAY', style: AccordionTheme.sLabel.copyWith(color: accent)),
              const SizedBox(height: 8),
              Text(
                word.lemma,
                style: AccordionTheme.sHead.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              if (word.pronunciation != null) ...[
                const SizedBox(height: 4),
                Text(word.pronunciation!, style: AccordionTheme.tfSub.copyWith(color: accent)),
              ],
              const SizedBox(height: 5),
              Text(
                word.translation,
                style: AccordionTheme.sBody.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AccordionTheme.ink2),
              ),
              if (word.usageNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  word.usageNote!,
                  style: AccordionTheme.sBody.copyWith(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AccordionTheme.ink3,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Static, not tappable.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AccordionTheme.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  languageName == null ? 'Learn →' : 'Learn $languageName →',
                  style: const TextStyle(
                    fontFamily: AccordionTheme.dmMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AccordionTheme.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
