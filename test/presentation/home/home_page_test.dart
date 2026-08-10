library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:louvorja_piano_mobile/presentation/home/home_page.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('HomePage', () {
    testWidgets('renderiza sem erros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('exibe "LouvorJA"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      expect(find.text('LouvorJA'), findsOneWidget);
    });

    testWidgets('exibe versão do app após scroll', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );

      await tester.scrollUntilVisible(
        find.textContaining('v0.1.0'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('v0.1.0'), findsOneWidget);
    });

    testWidgets('exibe 4 atalhos: Hinos, Liturgia, Bíblia, Timer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      expect(find.text('Hinos'), findsOneWidget);
      expect(find.text('Liturgia'), findsOneWidget);
      expect(find.text('Bíblia'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
    });

    testWidgets('exibe data atual em português', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      final now = DateTime.now();
      final months = [
        'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      final expectedMonth = months[now.month - 1];

      expect(find.textContaining(expectedMonth), findsOneWidget);
    });

    testWidgets('exibe codinome PIANO', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      expect(find.text('PIANO'), findsOneWidget);
    });
  });
}
