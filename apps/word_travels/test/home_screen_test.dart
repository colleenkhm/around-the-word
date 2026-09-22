import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pocket_talk/screens/home_screen.dart';
import 'package:pocket_talk/state/location_settings.dart';
import 'package:pocket_talk/state/recent_phrases.dart';
import 'package:pocket_talk/state/vocab_bank.dart';

Widget _harness(RecentPhrases recentPhrases) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VocabBank()),
      ChangeNotifierProvider(create: (_) => LocationSettings()),
      ChangeNotifierProvider.value(value: recentPhrases),
    ],
    child: const MaterialApp(home: HomeScreen()),
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
}
