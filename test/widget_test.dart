import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:louvorja_piano_mobile/app/app.dart';

void main() {
  testWidgets('App renderiza sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(const LouvorjaApp());

    // Verifica que pelo menos um widget renderiza
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
