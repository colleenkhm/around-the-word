import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forin/widgets/country_page/paper_texture.dart';

void main() {
  testWidgets('renders its child without throwing, at a realistic screen size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PaperTexture(child: Center(child: Text('Costa Rica')))),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Costa Rica'), findsOneWidget);
  });
}
