import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/screens/translate_screen.dart';
import 'trip_support.dart';
import 'package:pocket_talk/state/recent_phrases.dart';
import 'package:pocket_talk/state/vocab_bank.dart';
import 'package:pocket_talk/widgets/phrase_flip_card.dart';

const _englishFaceKey = Key('phrase_flip_english_face');

bool _showingEnglish(WidgetTester tester, Finder card) => tester
    .widget<Visibility>(
      find.descendant(of: card, matching: find.byKey(_englishFaceKey)),
    )
    .visible;

Widget _harness(RecentPhrases recentPhrases) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VocabBank()),
      ChangeNotifierProvider.value(value: tripsWithOne()),
      ChangeNotifierProvider.value(value: recentPhrases),
    ],
    child: const MaterialApp(home: TranslateScreen()),
  );
}

void main() {
  testWidgets('no quick-access strip when nothing has been looked up yet', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(RecentPhrases()));

    expect(find.textContaining('RECENTLY LOOKED UP'), findsNothing);
  });

  testWidgets('a recently viewed phrase shows in the quick-access strip', (
    tester,
  ) async {
    final recentPhrases = RecentPhrases()..recordView('basics_1');
    await tester.pumpWidget(_harness(recentPhrases));

    expect(find.textContaining('RECENTLY LOOKED UP'), findsOneWidget);
    expect(find.text('Por favor'), findsOneWidget);
  });

  testWidgets(
    'tapping a recent card flips that card, not one it swapped places with',
    (tester) async {
      // Recorded oldest-to-newest, so the strip starts as [Please, Thank
      // you, Good morning] — most recently viewed first.
      final recentPhrases = RecentPhrases()
        ..recordView('basics_3') // Good morning
        ..recordView('basics_2') // Thank you
        ..recordView('basics_1'); // Please
      await tester.pumpWidget(_harness(recentPhrases));

      // Tap the last card, not the first — this is the one that moves,
      // which is what exposes the bug (cards keyed by list position, not
      // by phrase, get their flip animation reassigned to whichever phrase
      // now lands on that position after the tap reorders the strip).
      final goodMorningCard = find.ancestor(
        of: find.text('Buenos días'),
        matching: find.byType(PhraseFlipCard),
      );
      await tester.tap(goodMorningCard);
      await tester.pumpAndSettle();

      // The card the user actually tapped should be the one now showing
      // English — found again by its content, since a phrase's card can
      // move position but its content always identifies it correctly.
      final flippedGoodMorning = find.ancestor(
        of: find.text('Good morning'),
        matching: find.byType(PhraseFlipCard),
      );
      expect(_showingEnglish(tester, flippedGoodMorning), isTrue);

      // No other card should have flipped along with it.
      final thankYouCard = find.ancestor(
        of: find.text('Gracias'),
        matching: find.byType(PhraseFlipCard),
      );
      expect(_showingEnglish(tester, thankYouCard), isFalse);

      final pleaseCard = find.ancestor(
        of: find.text('Por favor'),
        matching: find.byType(PhraseFlipCard),
      );
      expect(_showingEnglish(tester, pleaseCard), isFalse);
    },
  );

  testWidgets(
    'flipping a card in the strip does not reshuffle the strip',
    (tester) async {
      final recentPhrases = RecentPhrases()
        ..recordView('basics_3') // Good morning
        ..recordView('basics_2') // Thank you
        ..recordView('basics_1'); // Please
      await tester.pumpWidget(_harness(recentPhrases));

      List<Key?> cardKeysLeftToRight() => tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(Row),
              matching: find.byWidgetPredicate((w) => w is SizedBox && w.key != null),
            ),
          )
          .map((w) => w.key)
          .toList();

      final before = cardKeysLeftToRight();

      final goodMorningCard = find.ancestor(
        of: find.text('Buenos días'),
        matching: find.byType(PhraseFlipCard),
      );
      await tester.tap(goodMorningCard);
      await tester.pumpAndSettle();

      // The tap moved "Good morning" to the front of RecentPhrases' own
      // list, but the strip itself should still read left-to-right exactly
      // as it did before the tap.
      expect(recentPhrases.ids.first, 'basics_3');
      expect(cardKeysLeftToRight(), before);
    },
  );

  testWidgets(
    'a genuinely new lookup elsewhere still refreshes the strip',
    (tester) async {
      final recentPhrases = RecentPhrases()..recordView('basics_1');
      await tester.pumpWidget(_harness(recentPhrases));

      expect(find.text('Por favor'), findsOneWidget);
      expect(find.text('Gracias'), findsNothing);

      // Simulate looking up a different phrase elsewhere (e.g. a category
      // screen), which is how the strip is meant to pick up new lookups.
      recentPhrases.recordView('basics_2');
      await tester.pump();

      expect(find.text('Gracias'), findsOneWidget);
    },
  );

  testWidgets('the most recent card is a bit bigger than the rest', (
    tester,
  ) async {
    final recentPhrases = RecentPhrases()
      ..recordView('basics_3')
      ..recordView('basics_2')
      ..recordView('basics_1');
    await tester.pumpWidget(_harness(recentPhrases));

    final primary = tester.getSize(find.byKey(const ValueKey('basics_1')));
    final others = [
      tester.getSize(find.byKey(const ValueKey('basics_2'))),
      tester.getSize(find.byKey(const ValueKey('basics_3'))),
    ];

    expect(others[0].width, others[1].width);
    expect(primary.width, greaterThan(others[0].width));
  });

  testWidgets(
    'a long phrase does not balloon its card height in the narrow strip',
    (tester) async {
      // food_4's pronunciation is short; transportation_1's is one of the
      // longest in the data set and has few natural line-break points. At
      // the strip's narrow non-primary width, an uncapped Text used to wrap
      // it across many lines, making that one card much taller than its
      // neighbor — reading as "bigger" for the wrong reason.
      final recentPhrases = RecentPhrases()
        ..recordView('food_4')
        ..recordView('transportation_1')
        ..recordView('basics_1'); // primary, keeps the other two non-primary
      await tester.pumpWidget(_harness(recentPhrases));

      final shortCard = tester.getSize(
        find.byKey(const ValueKey('food_4')),
      );
      final longCard = tester.getSize(
        find.byKey(const ValueKey('transportation_1')),
      );

      expect((longCard.height - shortCard.height).abs(), lessThan(50));
    },
  );

  testWidgets(
    'a country-flagged phrase does not overflow at the narrow strip width',
    (tester) async {
      // transportation_2 varies by country ("Varies by country" pill plus a
      // wording per country) — at the strip's non-primary width the pill's
      // label used to be wider than the space available for it.
      final recentPhrases = RecentPhrases()
        ..recordView('transportation_2')
        ..recordView('basics_1'); // primary, keeps transportation_2 non-primary
      await tester.pumpWidget(_harness(recentPhrases));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a phrase with many country versions does not overflow the page',
    (tester) async {
      // emergencies_17 (lifeguard) has four country versions — the tallest
      // case in the data set. With no cap on the strip, a short screen plus
      // this phrase as the most recent lookup could push the whole page
      // (title, search, strip, category grid) past the available height.
      final recentPhrases = RecentPhrases()
        ..recordView('emergencies_17')
        ..recordView('basics_1');
      await tester.pumpWidget(_harness(recentPhrases));

      expect(tester.takeException(), isNull);
    },
  );
}
