library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/loading_indicator.dart';

void main() {
  testWidgets('renderiza spinner sem label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingIndicator())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renderiza label opcional', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoadingIndicator(label: 'Carregando catálogo')),
      ),
    );
    expect(find.text('Carregando catálogo'), findsOneWidget);
  });
}
