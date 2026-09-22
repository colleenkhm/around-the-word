import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocket_talk/state/recent_phrases.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recording a view puts it first', () async {
    final recent = RecentPhrases()..recordView('a');
    recent.recordView('b');
    expect(recent.ids, ['b', 'a']);
  });

  test('re-viewing an id moves it to the front instead of duplicating it', () {
    final recent = RecentPhrases()
      ..recordView('a')
      ..recordView('b')
      ..recordView('a');
    expect(recent.ids, ['a', 'b']);
  });

  test('older entries are dropped past the cap', () {
    final recent = RecentPhrases();
    for (var i = 0; i < RecentPhrases.maxEntries + 3; i++) {
      recent.recordView('id_$i');
    }
    expect(recent.ids.length, RecentPhrases.maxEntries);
    // Most recent first, oldest ones fell off the end.
    expect(recent.ids.first, 'id_${RecentPhrases.maxEntries + 2}');
    expect(recent.ids, isNot(contains('id_0')));
  });

  test('persists across a reload', () async {
    final first = RecentPhrases();
    await first.load();
    first.recordView('food_1');

    final second = RecentPhrases();
    await second.load();
    expect(second.ids, ['food_1']);
  });
}
