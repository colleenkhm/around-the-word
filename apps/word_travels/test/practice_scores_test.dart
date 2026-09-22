import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_talk/state/practice_scores.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an unpracticed phrase scores 0', () {
    expect(PracticeScores().scoreFor('basics_1'), 0);
  });

  test('a correct answer adds a point, a miss subtracts one', () {
    final scores = PracticeScores();
    scores.recordCorrect('basics_1');
    expect(scores.scoreFor('basics_1'), 1);

    scores.recordIncorrect('basics_1');
    expect(scores.scoreFor('basics_1'), 0);

    scores.recordIncorrect('basics_1');
    scores.recordIncorrect('basics_1');
    expect(scores.scoreFor('basics_1'), -2);
  });

  test('scores are tracked separately per phrase', () {
    final scores = PracticeScores();
    scores.recordCorrect('basics_1');
    scores.recordIncorrect('basics_2');

    expect(scores.scoreFor('basics_1'), 1);
    expect(scores.scoreFor('basics_2'), -1);
    expect(scores.scoreFor('basics_3'), 0);
  });

  test('persists across a reload', () async {
    final first = PracticeScores();
    await first.load();
    first.recordIncorrect('basics_1');
    first.recordIncorrect('basics_1');
    first.recordCorrect('basics_2');

    final second = PracticeScores();
    await second.load();
    expect(second.scoreFor('basics_1'), -2);
    expect(second.scoreFor('basics_2'), 1);
  });
}
