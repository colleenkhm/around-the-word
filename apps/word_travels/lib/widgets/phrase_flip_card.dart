import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/phrase.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import 'ticket_row.dart';

/// A ticket-style row for one phrase. Tap the card to flip between the
/// target-language phrase and its English translation; the bookmark button
/// saves it to the vocab bank independently of the flip state.
class PhraseFlipCard extends StatefulWidget {
  const PhraseFlipCard({super.key, required this.phrase});

  final Phrase phrase;

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

    return TicketRow(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _flip,
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
                        child: showBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _EnglishFace(text: widget.phrase.english),
                              )
                            : _TargetFace(
                                target: widget.phrase.target,
                                pronunciation: widget.phrase.pronunciation,
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
  const _TargetFace({required this.target, required this.pronunciation});

  final String target;
  final String pronunciation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(target, style: ptHeading(size: 15.5, color: PTColors.postalInk)),
          const SizedBox(height: 3),
          Text(pronunciation, style: ptMono()),
        ],
      ),
    );
  }
}

class _EnglishFace extends StatelessWidget {
  const _EnglishFace({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Text(text, style: ptBody(size: 14, weight: FontWeight.w500)),
      ),
    );
  }
}
