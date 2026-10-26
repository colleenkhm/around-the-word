import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_theme/shared_theme.dart';

import '../models/phrase.dart';
import '../models/place.dart';
import '../state/practice_scores.dart';
import '../theme/word_travels_theme.dart';
import '../widgets/pt_app_bar.dart';

enum _Result {
  unanswered,
  correct,

  /// The right word without its accent. Scores as correct; shown differently,
  /// so the user sees the spelling they missed.
  correctWithoutAccents,

  incorrect;

  static _Result of(AnswerAccuracy accuracy) => switch (accuracy) {
    AnswerAccuracy.exact => _Result.correct,
    AnswerAccuracy.accentsMissing => _Result.correctWithoutAccents,
    AnswerAccuracy.wrong => _Result.incorrect,
  };
}

/// How many phrases one sitting asks. The deck a session is handed can be
/// the whole phrasebook — well over a hundred — and a round with no end in
/// sight is one nobody finishes, so a session takes a fixed bite off the top
/// of the weakest-first order. "Practice again" re-sorts against the scores
/// it just recorded, so the next round is the next-weakest, not a replay.
const int sessionLength = 20;

/// Fill-in-the-blank practice over one deck. One phrase at a time: English
/// prompt, target sentence with the blank word missing, type the answer,
/// check, move on.
///
/// The deck is handed in rather than read from the vocab bank, so drilling
/// one trip and drilling a whole language's worth of trips are the same
/// screen. [place] is the destination whose wording to quiz on — a phrase
/// that varies by country is asked the way that trip would say it.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.phrases,
    required this.place,
    this.title = 'Practice',
  });

  final List<Phrase> phrases;
  final Place place;
  final String title;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late List<Phrase> _deck;
  int _index = 0;
  int _correctCount = 0;
  _Result _result = _Result.unanswered;
  final _answerController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _deck = _newDeck();
  }

  /// One round, worded for its destination and weakest first: sorted by
  /// practice score ascending (a phrase missed more than it's been gotten
  /// right sits at negative, and sorts ahead of one that's rarely missed),
  /// so drilling time goes toward what actually still needs it. Shuffled
  /// first so phrases sharing a score (most starting out at 0) don't always
  /// land in the same order, then cut to [sessionLength].
  List<Phrase> _newDeck() {
    final scores = context.read<PracticeScores>();
    final deck = widget.phrases
        .map((p) => p.forCountry(widget.place.country))
        .toList()
      ..shuffle();
    deck.sort(
      (a, b) => scores.scoreFor(a.id).compareTo(scores.scoreFor(b.id)),
    );
    return deck.take(sessionLength).toList();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Phrase get _current => _deck[_index];
  bool get _isLast => _index == _deck.length - 1;
  bool get _isDone => _index >= _deck.length;

  void _check() {
    if (_result != _Result.unanswered) return;
    final accuracy = _current.grade(_answerController.text);
    final scores = context.read<PracticeScores>();
    if (accuracy.isCorrect) {
      scores.recordCorrect(_current.id);
    } else {
      scores.recordIncorrect(_current.id);
    }
    setState(() {
      _result = _Result.of(accuracy);
      if (accuracy.isCorrect) _correctCount++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      _result = _Result.unanswered;
      _answerController.clear();
    });
    if (!_isDone) _focusNode.requestFocus();
  }

  void _restart() {
    setState(() {
      _deck = _newDeck();
      _index = 0;
      _correctCount = 0;
      _result = _Result.unanswered;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PTAppBar.back(title: widget.title),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isDone ? _buildSummary() : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nice work', style: ptHeading(size: 22)),
          const SizedBox(height: 10),
          Text(
            '$_correctCount / ${_deck.length} correct',
            style: ptMono(size: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PTColors.postal,
              foregroundColor: const Color(0xFFFBE9E2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _restart,
            child: const Text('Practice again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final phrase = _current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_index + 1} of ${_deck.length}', style: ptMono(size: 11.5)),
        const SizedBox(height: 20),
        Text(phrase.english, style: ptHeading(size: 18)),
        if (phrase.practiceCountry != null) ...[
          const SizedBox(height: 6),
          Text(
            '${phrase.practiceCountry} version',
            style: ptMono(size: 11, color: PTColors.mustardInk),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          phrase.targetWithBlank,
          style: ptHeading(
            size: 17,
            weight: FontWeight.w500,
            color: PTColors.postalInk,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _answerController,
          focusNode: _focusNode,
          autofocus: true,
          enabled: _result == _Result.unanswered,
          onSubmitted: (_) => _check(),
          style: const TextStyle(fontFamily: AccordionTheme.dmSans, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Type the missing word',
            filled: true,
            fillColor: PTColors.cardRow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PTColors.line),
            ),
          ),
        ),
        if (_result != _Result.unanswered) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(result: _result, correctWord: phrase.blankWord),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _result == _Result.unanswered
                  ? PTColors.ink
                  : PTColors.postal,
              foregroundColor: const Color(0xFFFBE9E2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(
                fontFamily: AccordionTheme.dmSans,
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _result == _Result.unanswered
                ? _check
                : (_isLast ? () => setState(() => _index++) : _next),
            child: Text(
              _result == _Result.unanswered
                  ? 'Check'
                  : (_isLast ? 'See results' : 'Next'),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.result, required this.correctWord});

  final _Result result;
  final String correctWord;

  @override
  Widget build(BuildContext context) {
    // An accent-only miss reads as the win it scored, with the spelling
    // alongside it — the point is to teach the accent, not to dock a mark
    // for a keyboard that makes it awkward.
    final scored = result != _Result.incorrect;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scored ? const Color(0xFFE9EFE0) : const Color(0xFFF3DFDA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        switch (result) {
          _Result.correct => 'Correct!',
          _Result.correctWithoutAccents => 'Correct — with the accent: "$correctWord"',
          _ => 'Not quite — it\'s "$correctWord"',
        },
        style: TextStyle(
          fontFamily: AccordionTheme.dmSans,
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
          color: scored ? PTColors.sageInk : PTColors.postalInk,
        ),
      ),
    );
  }
}
