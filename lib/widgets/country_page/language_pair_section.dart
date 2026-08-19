import 'package:flutter/material.dart';

import '../../models/language_content.dart';
import '../../theme/accordion_theme.dart';

/// The "Language" [AccordionSection]'s expanded content — official
/// languages side by side with a "Word of the day" card. Content-only,
/// no card chrome or heading.
class LanguagePairSection extends StatelessWidget {
  final List<String> officialLanguages;
  final Word? featuredWord;

  /// This section's flag color.
  final Color tint;

  /// Black or white, whichever reads on [tint].
  final Color textColor;

  /// A version of [tint] guaranteed to read on white.
  final Color accentOnWhite;

  const LanguagePairSection({
    super.key,
    required this.officialLanguages,
    required this.tint,
    required this.textColor,
    required this.accentOnWhite,
    this.featuredWord,
  });

  @override
  Widget build(BuildContext context) {
    final showLanguages = officialLanguages.isNotEmpty;
    final showWord = featuredWord != null;
    if (!showLanguages && !showWord) return const SizedBox.shrink();

    final languagesCard = showLanguages
        ? _LanguagesCard(languages: officialLanguages, tint: tint, textColor: textColor)
        : null;
    final wordCard = showWord
        ? _WordOfDayCard(
            word: featuredWord!,
            languageName: showLanguages ? officialLanguages.first : null,
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
  final List<String> languages;
  final Color tint;
  final Color textColor;

  const _LanguagesCard({required this.languages, required this.tint, required this.textColor});

  @override
  Widget build(BuildContext context) {
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
            for (var i = 0; i < languages.length; i++) ...[
              if (i != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(height: 1, color: textColor.withValues(alpha: 0.15)),
                ),
              _LanguageRow(name: languages[i], textColor: textColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String name;
  final Color textColor;

  const _LanguageRow({required this.name, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AccordionTheme.rowTitle.copyWith(color: textColor))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'official',
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
