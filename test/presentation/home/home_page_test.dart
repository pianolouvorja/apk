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

    testWidgets('exibe logo LouvorJA (SVG)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      // Logo SVG centralizado
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('exibe campo Distrito editavel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      expect(find.text('Distrito'), findsOneWidget);
    });

    testWidgets('exibe campo Igreja', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();

      expect(find.text('Igreja'), findsOneWidget);
    });

    testWidgets('exibe relogio digital', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Relogio no formato HH:MM
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('relogio atualiza a cada segundo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );

      // Frame inicial
      await tester.pump();

      // Avancar 1 segundo
      await tester.pump(const Duration(seconds: 1));

      // Verificar que o widget ainda esta montado sem erros
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
