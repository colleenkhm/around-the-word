import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/phrase.dart';
import '../state/vocab_bank.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/pt_app_bar.dart';

enum _Result { unanswered, correct, incorrect }

/// Fill-in-the-blank practice, drawn only from what's in the vocab bank.
/// One phrase at a time: English prompt, target sentence with the blank
/// word missing, type the answer, check, move on.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

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
    _deck = context.read<VocabBank>().savedPhrases.toList()..shuffle();
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
    final correct = _current.checkAnswer(_answerController.text);
    setState(() {
      _result = correct ? _Result.correct : _Result.incorrect;
      if (correct) _correctCount++;
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
      _deck = context.read<VocabBank>().savedPhrases.toList()..shuffle();
      _index = 0;
      _correctCount = 0;
      _result = _Result.unanswered;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PTAppBar.back(title: 'Practice'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        const SizedBox(height: 16),
        Text(
          phrase.targetWithBlank,
          style: ptHeading(size: 17, weight: FontWeight.w500, color: PTColors.postalInk),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _answerController,
          focusNode: _focusNode,
          autofocus: true,
          enabled: _result == _Result.unanswered,
          onSubmitted: (_) => _check(),
          style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 15),
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
              backgroundColor: _result == _Result.unanswered ? PTColors.ink : PTColors.postal,
              foregroundColor: const Color(0xFFFBE9E2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(fontFamily: 'IBM Plex Sans', fontWeight: FontWeight.w500, fontSize: 14.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final correct = result == _Result.correct;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFE9EFE0) : const Color(0xFFF3DFDA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        correct ? 'Correct!' : 'Not quite — it\'s "$correctWord"',
        style: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
          color: correct ? PTColors.sageInk : PTColors.postalInk,
        ),
      ),
    );
  }
}
