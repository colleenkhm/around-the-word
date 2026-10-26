import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../feature_flags.dart';
import '../../models/country_bundle.dart';
import '../../models/language_content.dart';

/// Word Travels, deployed under this site's /word-travels/ path.
final _wordTravelsUri = kIsWeb
    ? Uri.base.resolve('/word-travels/')
    : Uri.parse('https://www.whereabout.world/word-travels/');

/// Word Travels only teaches Spanish so far.
bool _hasWordTravels(List<LanguageEntry> languages) =>
    wordTravelsEnabled &&
    languages.any((l) => l.name.toLowerCase() == 'spanish');

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

    final learnUri = _hasWordTravels(languages) ? _wordTravelsUri : null;
    final learnLanguage = learnUri != null
        ? 'Spanish'
        : languages.where((l) => l.isOfficial).firstOrNull?.name ?? languages.firstOrNull?.name;
    final learnLabel = learnLanguage == null ? 'Learn →' : 'Learn $learnLanguage →';

    final languagesCard = showLanguages
        ? _LanguagesCard(
            languages: languages,
            tint: tint,
            textColor: textColor,
            // Link lives here when there's no word card to carry it.
            learnButton: !showWord && learnUri != null
                ? _LearnButton(label: learnLabel, uri: learnUri, background: textColor, foreground: tint)
                : null,
          )
        : null;
    final wordCard = showWord
        ? _WordOfDayCard(
            word: featuredWord!,
            accent: accentOnWhite,
            learnButton: _LearnButton(
              label: learnLabel,
              uri: learnUri,
              background: AccordionTheme.ink,
              foreground: AccordionTheme.white,
            ),
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
  final Widget? learnButton;

  const _LanguagesCard({required this.languages, required this.tint, required this.textColor, this.learnButton});

  /// Most-spoken first by [LanguageEntry.percentSpeakers] once every
  /// language has a figure; until then official first, so a partly
  /// researched country can't rank English above its own language.
  /// English always present, even when the source data has no entry for
  /// it, so a traveler can always see at a glance whether it's spoken
  /// here. Only runs once there's at least one real language on record; a
  /// country with none yet still reads "coming soon" rather than showing
  /// English alone.
  List<LanguageEntry> get _displayLanguages {
    final complete = languages.every((l) => l.percentSpeakers != null);
    final sorted = [...languages]..sort((a, b) {
      if (!complete && a.isOfficial != b.isOfficial) return a.isOfficial ? -1 : 1;
      final byPercent = (b.percentSpeakers ?? -1).compareTo(a.percentSpeakers ?? -1);
      if (byPercent != 0) return byPercent;
      if (a.isOfficial != b.isOfficial) return a.isOfficial ? -1 : 1;
      return 0;
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
            if (learnButton != null) ...[
              const SizedBox(height: 12),
              learnButton!,
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

  final Color accent;
  final Widget learnButton;

  const _WordOfDayCard({required this.word, required this.accent, required this.learnButton});

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
              learnButton,
            ],
          ),
        ),
      ),
    );
  }
}

/// "Learn ___ →" — links to Word Travels when [uri] is set, static otherwise.
class _LearnButton extends StatelessWidget {
  final String label;
  final Uri? uri;
  final Color background;
  final Color foreground;

  const _LearnButton({required this.label, required this.uri, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        // Same tab on web, so Back returns here.
        onTap: uri == null ? null : () => launchUrl(uri!, webOnlyWindowName: '_self'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AccordionTheme.dmMono,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
