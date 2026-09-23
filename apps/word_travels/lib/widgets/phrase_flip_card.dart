import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../models/phrase.dart';
import '../state/location_settings.dart';
import '../state/recent_phrases.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import 'ticket_row.dart';

/// A ticket-style row for one phrase. Tap the card to flip between the
/// target-language phrase and its English translation; the bookmark button
/// saves it to the vocab bank independently of the flip state.
class PhraseFlipCard extends StatefulWidget {
  const PhraseFlipCard({
    super.key,
    required this.phrase,
    this.showNotches = true,
  });

  final Phrase phrase;
  final bool showNotches;

  @override
  State<PhraseFlipCard> createState() => _PhraseFlipCardState();
}

class _PhraseFlipCardState extends State<PhraseFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    // Flipping is the "I needed this phrase" signal — it's the deliberate
    // lookup action, unlike a card merely scrolling into view.
    context.read<RecentPhrases>().recordView(widget.phrase.id);
    if (_controller.value == 0) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.select<VocabBank, bool>(
      (bank) => bank.isSaved(widget.phrase.id),
    );

    final country = context.select<LocationSettings, String?>((r) => r.country);
    final phrase = widget.phrase.forCountry(country);
    // A live-translated phrase belongs to no curated category, so it falls
    // back to the same neutral tint its result card uses on Translate —
    // the saved flashcard then looks like the card it came from.
    final tint = categoryById(widget.phrase.categoryId)?.tint ?? PTTints.basics;

    return TicketRow(
      tint: tint,
      showNotches: widget.showNotches,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('phrase_flip_tap_area'),
              onTap: _flip,
              // Without this, the detector only hit-tests the flip card's
              // painted content — here the text itself, which for a short
              // phrase leaves most of the row untappable. Opaque plus a
              // full-width container (below) makes the whole row (minus the
              // bookmark button next to it) flip the card.
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                alignment: Alignment.topLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final angle = _controller.value * pi;
                        final showBack = _controller.value > 0.5;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          // Both faces stay mounted (one just hidden), so
                          // the card's size is the taller of the two
                          // throughout — English is one line, but the
                          // target phrase is often two or more. Swapping
                          // the widget out entirely (rather than hiding it)
                          // let the row shrink to whichever face was
                          // showing, so after flipping to English the tap
                          // area shrank down to just that line and tapping
                          // the rest of the row no longer flipped it back.
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Visibility(
                                key: const Key('phrase_flip_target_face'),
                                visible: !showBack,
                                maintainState: true,
                                maintainAnimation: true,
                                maintainSize: true,
                                child: _TargetFace(phrase: phrase, tint: tint),
                              ),
                              // Filled rather than left to shrink-wrap: the
                              // card's height comes from the target face, so
                              // only by taking that full height can the one
                              // English line sit in the vertical middle of
                              // it instead of at the top.
                              Positioned.fill(
                                child: Visibility(
                                  key: const Key('phrase_flip_english_face'),
                                  visible: showBack,
                                  maintainState: true,
                                  maintainAnimation: true,
                                  maintainSize: true,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(pi),
                                    child: _EnglishFace(
                                      text: widget.phrase.english,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: -2,
                      right: 0,
                      child: Icon(
                        Icons.swap_horiz,
                        size: 14,
                        color: PTColors.inkSoft.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.read<VocabBank>().toggle(widget.phrase.id),
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              color: saved ? PTColors.mustard : PTColors.inkSoft,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetFace extends StatelessWidget {
  const _TargetFace({required this.phrase, required this.tint});

  final Phrase phrase;
  final PTTint tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: phrase.variesByCountry
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CountryFlag(),
                for (final v in phrase.variants) ...[
                  const SizedBox(height: 8),
                  Text(
                    v.countryLabel.toUpperCase(),
                    style: ptMono(size: 10, color: PTColors.inkSoft),
                  ),
                  const SizedBox(height: 1),
                  _TargetLines(
                    target: v.target,
                    pronunciation: v.pronunciation,
                    ink: tint.ink,
                  ),
                ],
              ],
            )
          : _TargetLines(
              target: phrase.target,
              pronunciation: phrase.pronunciationGuide,
              ink: tint.ink,
            ),
    );
  }
}

class _TargetLines extends StatelessWidget {
  const _TargetLines({
    required this.target,
    required this.pronunciation,
    required this.ink,
  });

  final String target;
  final String pronunciation;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    // Capped rather than left to wrap freely: the pronunciation especially
    // has few natural break points, and in the narrow "recently looked up"
    // strip an uncapped long phrase could wrap across many lines, making
    // that one card balloon in height far past its neighbors — reading as
    // "bigger" for the wrong reason, not because it's the primary card.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          target,
          style: ptHeading(size: 15.5, color: ink),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Skip the line rather than leaving a gap when there's no guide.
        if (pronunciation.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            pronunciation,
            style: ptMono(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Marks a phrase whose wording differs by country.
class _CountryFlag extends StatelessWidget {
  const _CountryFlag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PTColors.mustardTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public, size: 11, color: PTColors.mustardInk),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Varies by country',
              style: ptMono(size: 10, color: PTColors.mustardInk),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The English translation, alone on the back of the card: left-aligned like
/// every other line, but sitting in the vertical middle rather than riding
/// at the top of the height the target face sets.
class _EnglishFace extends StatelessWidget {
  const _EnglishFace({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Text(
          text,
          style: ptBody(size: 14, weight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
