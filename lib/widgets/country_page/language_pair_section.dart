import 'package:flutter/material.dart';

import '../../models/language_content.dart';
import '../../theme/country_theme.dart';
import 'section_heading.dart';

/// The Overview tab's Language pair — official languages spoken, side by
/// side with a "Word of the day" card. New this pass, built against
/// `trip-dashboard-v3.html`'s `.lang-pair` (`.lang-l` + `.lang-r`).
///
/// **No per-language prevalence bars** — the mockup shows "Greek 99% /
/// English 51%" style bars, but nothing in [CountryFacts] tracks a
/// per-language usage percentage (only the flat `officialLanguages` list),
/// and no source for that number was identified. Rather than invent one,
/// this renders official languages as a plain list. Flagged as a loose end
/// in the scratch notes doc, not built around a guess.
///
/// **Word of the day is static, not a real "pick for today"** — [featuredWord]
/// is just whichever [Word] the caller passes in (CLAUDE.md lists word-of-
/// day notifications as a don't-build-without-being-asked feature; this is
/// the display half only, no rotation/selection logic). Its "Learn ___ →"
/// button is deliberately non-interactive — the language flow isn't wired
/// from the Overview tab yet, so a tappable button would promise a
/// destination that doesn't exist (same reasoning [CitiesSection] already
/// applies to its chevron).
class LanguagePairSection extends StatelessWidget {
  final List<String> officialLanguages;
  final Word? featuredWord;

  const LanguagePairSection({
    super.key,
    required this.officialLanguages,
    this.featuredWord,
  });

  @override
  Widget build(BuildContext context) {
    final showLanguages = officialLanguages.isNotEmpty;
    final showWord = featuredWord != null;
    if (!showLanguages && !showWord) return const SizedBox.shrink();

    final languagesCard = showLanguages ? _LanguagesCard(languages: officialLanguages) : null;
    final wordCard = showWord
        ? _WordOfDayCard(
            word: featuredWord!,
            languageName: showLanguages ? officialLanguages.first : null,
          )
        : null;

    final cards = showLanguages && showWord
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: languagesCard!),
                const SizedBox(width: 8),
                Expanded(child: wordCard!),
              ],
            ),
          )
        : (languagesCard ?? wordCard!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Languages'),
        cards,
      ],
    );
  }
}

/// The `.lang-badge` teal — a one-off content-type tag, not reused
/// anywhere else on the page, so it lives here rather than in
/// [CountryTheme] alongside tokens several widgets share.
const _badgeTeal = Color(0xFF1A6060);

class _LanguagesCard extends StatelessWidget {
  final List<String> languages;

  const _LanguagesCard({required this.languages});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(boxShadow: CountryTheme.cardShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
        child: ColoredBox(
          color: CountryTheme.card,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < languages.length; i++) ...[
                  if (i != 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(height: 1, color: CountryTheme.rule),
                    ),
                  _LanguageRow(name: languages[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String name;

  const _LanguageRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: CountryTheme.ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              'official',
              style: TextStyle(
                fontFamily: 'Courier Prime',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: _badgeTeal,
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

  /// First entry of [CountryFacts.officialLanguages], if known — feeds
  /// the "Learn ___ →" button's label. Falls back to generic copy when
  /// unknown rather than guessing.
  final String? languageName;

  const _WordOfDayCard({required this.word, this.languageName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(boxShadow: CountryTheme.cardShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CountryTheme.cardRadius),
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: CountryTheme.navy)),
            const Positioned(top: 0, left: 0, right: 0, child: SizedBox(height: 3, child: ColoredBox(color: CountryTheme.gold))),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WORD OF THE DAY',
                    style: CountryTheme.sectionLabel.copyWith(
                      color: CountryTheme.onNavyMuted,
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.lemma,
                    style: CountryTheme.listRowTitle.copyWith(
                      color: CountryTheme.onNavy,
                      fontSize: 20,
                    ),
                  ),
                  if (word.pronunciation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.pronunciation!,
                      style: CountryTheme.ticketStubSub.copyWith(color: CountryTheme.onNavyMuted),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    word.translation,
                    style: CountryTheme.listRowDetail.copyWith(
                      color: CountryTheme.onNavySoft,
                      fontSize: 12,
                    ),
                  ),
                  if (word.usageNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.usageNote!,
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontStyle: FontStyle.italic,
                        fontSize: 10.5,
                        color: CountryTheme.onNavyMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Static, not tappable — see class doc.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: CountryTheme.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      languageName == null ? 'Learn more →' : 'Learn $languageName →',
                      style: const TextStyle(
                        fontFamily: 'Courier Prime',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: CountryTheme.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
