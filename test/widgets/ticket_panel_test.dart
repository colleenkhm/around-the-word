import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whereabout/widgets/country_page/ticket_panel.dart';

void main() {
  testWidgets('renders its child without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketPanel(child: Padding(padding: EdgeInsets.all(20), child: Text('Hi'))),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('renders inside an IntrinsicHeight without throwing', (tester) async {
    // TicketPanel wraps its content in ClipPath + CustomPaint, not
    // LayoutBuilder — both support intrinsic-dimension queries (they just
    // clip/paint over whatever size layout already resolved), unlike
    // LayoutBuilder (see section_heading_test.dart for the failure mode
    // this guards against). DividedCard builds on TicketPanel and gets
    // placed inside an IntrinsicHeight in TravelInfoSection's desktop
    // side-by-side layout, so this is worth confirming directly.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: TicketPanel(child: Text('short'))),
                Expanded(
                  child: TicketPanel(
                    child: Text('a good deal taller than the other column'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
