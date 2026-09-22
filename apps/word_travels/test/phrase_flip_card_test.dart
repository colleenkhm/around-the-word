import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/recent_phrases.dart';
import 'package:pocket_talk/state/vocab_bank.dart';
import 'package:pocket_talk/widgets/phrase_flip_card.dart';

// A short phrase, so a text-sized (rather than row-wide) tap area would
// leave most of the row untappable — the bug this guards against.
const _phrase = Phrase(
  id: 'test_1',
  categoryId: 'basics',
  english: 'Yes',
  target: 'Sí',
  pronunciation: 'see',
  blankWord: 'Sí',
);

const _targetFaceKey = Key('phrase_flip_target_face');
const _englishFaceKey = Key('phrase_flip_english_face');
const _tapAreaKey = Key('phrase_flip_tap_area');

Widget _harness({RecentPhrases? recentPhrases}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VocabBank()),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider(create: (_) => recentPhrases ?? RecentPhrases()),
    ],
    child: const MaterialApp(
      home: Scaffold(body: PhraseFlipCard(phrase: _phrase)),
    ),
  );
}

/// Both faces stay mounted (see phrase_flip_card.dart); which one is showing
/// is the `Visibility.visible` flag, not text presence in the tree.
bool _showingEnglish(WidgetTester tester) =>
    tester.widget<Visibility>(find.byKey(_englishFaceKey)).visible;

void main() {
  testWidgets('the tap area spans the row, not just the short phrase text', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    final tapArea = tester.getSize(find.byKey(_tapAreaKey));
    final text = tester.getSize(find.text('Sí'));

    // "Sí" itself is only a few characters wide; the tap area should reach
    // well beyond it, out toward the bookmark button.
    expect(tapArea.width, greaterThan(text.width * 3));
  });

  testWidgets('tapping the row away from the short phrase text flips it', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    expect(_showingEnglish(tester), isFalse);

    // Tap near the far edge of the widened tap area, well clear of "Sí".
    final tapAreaRect = tester.getRect(find.byKey(_tapAreaKey));
    await tester.tapAt(Offset(tapAreaRect.right - 5, tapAreaRect.top + 10));
    await tester.pumpAndSettle();

    expect(_showingEnglish(tester), isTrue);
  });

  testWidgets(
    'the row stays the same size after flipping, so it can be tapped back',
    (tester) async {
      await tester.pumpWidget(_harness());

      // Target face (phrase + pronunciation, two lines) is taller than the
      // one-line English face — tap near its top so the flip forward always
      // lands regardless of the bug under test.
      final beforeRect = tester.getRect(find.byKey(_tapAreaKey));
      await tester.tapAt(Offset(beforeRect.right - 5, beforeRect.top + 5));
      await tester.pumpAndSettle();
      expect(_showingEnglish(tester), isTrue);

      // The tap area must not have shrunk down to just the English line.
      final afterRect = tester.getRect(find.byKey(_tapAreaKey));
      expect(afterRect.height, beforeRect.height);

      // Tap low in the row — where the (now-hidden) pronunciation line used
      // to be — to flip back. Before the fix this fell outside the shrunk
      // tap area and did nothing.
      await tester.tapAt(Offset(afterRect.right - 5, afterRect.bottom - 5));
      await tester.pumpAndSettle();

      expect(_showingEnglish(tester), isFalse);
    },
  );

  testWidgets('tapping the bookmark button does not flip the card', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    expect(_showingEnglish(tester), isFalse);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('flipping the card records it as recently viewed', (
    tester,
  ) async {
    final recentPhrases = RecentPhrases();
    await tester.pumpWidget(_harness(recentPhrases: recentPhrases));

    expect(recentPhrases.ids, isEmpty);

    final tapAreaRect = tester.getRect(find.byKey(_tapAreaKey));
    await tester.tapAt(Offset(tapAreaRect.right - 5, tapAreaRect.top + 10));
    await tester.pumpAndSettle();

    expect(recentPhrases.ids, [_phrase.id]);
  });

  testWidgets('the target face is still findable by its text', (
    tester,
  ) async {
    // find.text sees both faces regardless of which is visible (they're
    // both always mounted) — sanity-check that at least the content itself
    // is correct and unique per face, in case that ever changes.
    await tester.pumpWidget(_harness());
    expect(
      find.descendant(of: find.byKey(_targetFaceKey), matching: find.text('Sí')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_englishFaceKey),
        matching: find.text('Yes'),
      ),
      findsOneWidget,
    );
  });
}
