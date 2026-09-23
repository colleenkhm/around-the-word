import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/models/phrase.dart';
import 'package:pocket_talk/screens/translate_screen.dart';
import 'package:pocket_talk/services/translation_service.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/recent_phrases.dart';
import 'package:pocket_talk/state/vocab_bank.dart';
import 'package:pocket_talk/widgets/ticket_row.dart';

/// Stands in for the real translation API: records what it was asked for,
/// and answers with a canned translation (or a failure).
class _FakeTranslationProvider implements TranslationProvider {
  _FakeTranslationProvider({this.fails = false});

  static const answer = 'mi vuelo se ha retrasado';
  final bool fails;
  int calls = 0;
  String? lastText;
  String? lastFrom;
  String? lastTo;

  @override
  Future<String> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    calls++;
    lastText = text;
    lastFrom = from;
    lastTo = to;
    if (fails) throw Exception('offline');
    return answer;
  }
}

Widget _harness(
  _FakeTranslationProvider translator, {
  VocabBank? vocabBank,
  String? incomingQuery,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: vocabBank ?? VocabBank()),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider(create: (_) => RecentPhrases()),
      Provider<TranslationProvider>.value(value: translator),
    ],
    child: MaterialApp(home: TranslateScreen(incomingQuery: incomingQuery)),
  );
}

/// Types a query and waits out the debounce plus the fake's answer.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a query with no curated match is translated and shown', (
    tester,
  ) async {
    final translator = _FakeTranslationProvider();
    await tester.pumpWidget(_harness(translator));

    await _search(tester, 'my flight was delayed');

    expect(translator.calls, 1);
    expect(translator.lastText, 'my flight was delayed');
    expect(translator.lastFrom, 'en');
    expect(translator.lastTo, 'es');

    // Both sides visible at once on the result card — no tap/flip needed to
    // read it. Scoped to the card, since the query itself is also sitting in
    // the search field above.
    final card = find.byType(TicketRow);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('my flight was delayed')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('mi vuelo se ha retrasado')),
      findsOneWidget,
    );
  });

  testWidgets('the translation is saved to the practice deck on its own', (
    tester,
  ) async {
    final vocabBank = VocabBank();
    final translator = _FakeTranslationProvider();
    await tester.pumpWidget(_harness(translator, vocabBank: vocabBank));

    expect(vocabBank.savedPhrases, isEmpty);

    await _search(tester, 'my flight was delayed');

    // Saved with no extra tap, carrying its own content (it isn't in the
    // curated set), and tagged with the language it was looked up in.
    expect(vocabBank.savedPhrases, hasLength(1));
    final saved = vocabBank.savedPhrases.single;
    expect(saved.english, 'my flight was delayed');
    expect(saved.target, 'mi vuelo se ha retrasado');
    expect(saved.languageCode, 'es');
    expect(vocabBank.savedPhrasesForLanguage('es'), hasLength(1));
    expect(vocabBank.savedPhrasesForLanguage('fr'), isEmpty);
  });

  testWidgets('a curated match is used instead of hitting the API', (
    tester,
  ) async {
    final translator = _FakeTranslationProvider();
    await tester.pumpWidget(_harness(translator));

    await _search(tester, 'thank you');

    expect(translator.calls, 0);
    expect(find.text('Gracias'), findsOneWidget);
  });

  testWidgets('a failed translation reports instead of saving anything', (
    tester,
  ) async {
    final vocabBank = VocabBank();
    final translator = _FakeTranslationProvider(fails: true);
    await tester.pumpWidget(_harness(translator, vocabBank: vocabBank));

    await _search(tester, 'my flight was delayed');

    expect(find.textContaining("Couldn't translate"), findsOneWidget);
    expect(vocabBank.savedPhrases, isEmpty);
  });

  testWidgets('typing keeps debouncing instead of translating each keystroke', (
    tester,
  ) async {
    final translator = _FakeTranslationProvider();
    await tester.pumpWidget(_harness(translator));

    // Nothing curated matches "trampoline", so the settled query is a real
    // lookup — the point being it's looked up once, not once per keystroke.
    final field = find.byType(TextField).first;
    for (final partial in ['wh', 'where', 'where is the tr', 'where is the trampoline']) {
      await tester.enterText(field, partial);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(translator.calls, 1);
    expect(translator.lastText, 'where is the trampoline');
  });

  testWidgets('an unsaved lookup can be re-saved from the card', (
    tester,
  ) async {
    final vocabBank = VocabBank();
    final translator = _FakeTranslationProvider();
    await tester.pumpWidget(_harness(translator, vocabBank: vocabBank));

    await _search(tester, 'my flight was delayed');
    expect(vocabBank.savedPhrases, hasLength(1));

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    expect(vocabBank.savedPhrases, isEmpty);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('a lookup then shows in the recent strip as a flashcard', (
    tester,
  ) async {
    final translator = _FakeTranslationProvider();
    await tester.pumpWidget(_harness(translator));

    await _search(tester, 'my flight was delayed');

    // Clearing the query returns to the idle state, where the strip renders
    // the lookup through PhraseFlipCard — it belongs to no curated
    // category, which used to throw "Bad state: No element".
    await _search(tester, '');

    expect(tester.takeException(), isNull);
    expect(find.text('RECENTLY LOOKED UP'), findsOneWidget);
    expect(find.text(_FakeTranslationProvider.answer), findsOneWidget);
  });

  testWidgets('a query handed over from another tab is looked up', (
    tester,
  ) async {
    final translator = _FakeTranslationProvider();

    // Mirrors the tab bar: this screen is already alive when the phrasebook
    // hands its unmatched query over, so it arrives as a prop change.
    await tester.pumpWidget(_harness(translator));
    expect(translator.calls, 0);

    await tester.pumpWidget(
      _harness(translator, incomingQuery: 'my flight was delayed'),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(translator.lastText, 'my flight was delayed');
    expect(find.text(_FakeTranslationProvider.answer), findsOneWidget);
    // The handed-over text lands in the field, so it can be edited.
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'my flight was delayed',
    );
  });

  test('autoBlankWord picks a content word, not a function word', () {
    expect(autoBlankWord('mi vuelo se ha retrasado'), 'retrasado');
    expect(autoBlankWord('la cuenta'), 'cuenta');
    expect(autoBlankWord('¿Dónde está el baño?'), 'Dónde');
    expect(autoBlankWord('sí'), 'sí');
  });
}
