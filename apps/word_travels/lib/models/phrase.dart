/// A single phrase: shown as a flip card while browsing, and as a
/// fill-in-the-blank exercise once it's in the vocab bank.
///
/// [blankWord] is hand-picked per phrase (not auto-detected) — Spanish
/// articles/gender agreement make "just blank a random word" unreliable,
/// so the content word to drill is chosen deliberately.
class Phrase {
  final String id;
  final String categoryId;
  final String english;
  final String target;
  final String pronunciation;
  final String blankWord;

  const Phrase({
    required this.id,
    required this.categoryId,
    required this.english,
    required this.target,
    required this.pronunciation,
    required this.blankWord,
  });

  /// [target] with [blankWord] replaced by a blank, for the practice screen.
  String get targetWithBlank {
    final pattern = RegExp(RegExp.escape(blankWord), caseSensitive: false);
    final match = pattern.firstMatch(target);
    if (match == null) return target;
    final blank = '_' * blankWord.length;
    return target.replaceRange(match.start, match.end, blank);
  }

  bool checkAnswer(String attempt) {
    return _normalize(attempt) == _normalize(blankWord);
  }

  static String _normalize(String s) => s.trim().toLowerCase();
}
