import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/live_data.dart';
import 'package:around_the_word/widgets/country_page/right_now_strip.dart';

void main() {
  testWidgets('shows a Convert link once an exchange rate is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RightNowStrip(
            utcOffsetMinutes: -360,
            exchangeRate: ExchangeRate(
              currencyCode: 'CRC',
              rateFromUsd: 519.8,
              fetchedAt: DateTime(2026, 8, 6),
            ),
            currencyName: 'Costa Rican Colón',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Convert'), findsOneWidget);
  });

  testWidgets('omits the Convert link when there is no exchange rate', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RightNowStrip(utcOffsetMinutes: -360)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Convert'), findsNothing);
  });

  testWidgets('local-time subtitle pairs the date with the UTC offset', (tester) async {
    // Added 2026-08-11, per Colleen: the offset alone doesn't make it
    // obvious a country is already on tomorrow's date relative to here.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RightNowStrip(utcOffsetMinutes: -360)),
      ),
    );

    expect(tester.takeException(), isNull);
    final dateAndOffset = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          RegExp(r'^[A-Z][a-z]{2} \d{1,2} · UTC-\d+$').hasMatch(widget.data ?? ''),
    );
    expect(dateAndOffset, findsOneWidget);
  });

  testWidgets('local-time column falls back to an em dash with no offset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RightNowStrip(utcOffsetMinutes: null)),
      ),
    );

    expect(tester.takeException(), isNull);
    // Season and $1 USD also fall back to an em dash with no data of their
    // own passed in, so all three columns show one — not just this one.
    expect(find.text('—'), findsNWidgets(3));
  });
}
