library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/presentation/home/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('renderiza sem erros', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('exibe "LouvorJA PIANO"', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('LouvorJA PIANO'), findsOneWidget);
    });

    testWidgets('exibe versão do app', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.textContaining('v0.1.0-alpha'), findsOneWidget);
    });

    testWidgets('exibe 4 atalhos: Hinos, Liturgia, Bíblia, Timer',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Hinos'), findsOneWidget);
      expect(find.text('Liturgia'), findsOneWidget);
      expect(find.text('Bíblia'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
    });

    testWidgets('exibe data atual em português', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      final now = DateTime.now();
      final months = [
        'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      final expectedMonth = months[now.month - 1];

      expect(find.textContaining(expectedMonth), findsOneWidget);
    });

    testWidgets('tap num atalho mostra feedback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomePage()),
        ),
      );

      await tester.tap(find.text('Hinos'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
