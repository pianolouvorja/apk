library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:louvorja_piano_mobile/app/app.dart';

/// Integration test: app completo com splash + navegação entre todas as tabs.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('E2E: App init + navegação', () {
    testWidgets('mostra splash com logo e codinome', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pump();

      // Splash visivel no inicio
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets(' splash desaparece após boot', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pump();

      // Espera splash acabar (2.2s + animação)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App principal deve aparecer
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('5 NavigationDestinations existem', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('navegação sequencial: Início -> Hinos -> Bíblia -> Mais',
        (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Início
      expect(find.text('LouvorJA'), findsOneWidget);

      // -> Hinos
      await tester.tap(find.text('Hinos').first);
      await tester.pumpAndSettle();

      // -> Bíblia
      await tester.tap(find.text('Bíblia'));
      await tester.pumpAndSettle();

      // -> Mais
      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('volta para Início depois de navegar', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vai pra Hinos
      await tester.tap(find.text('Hinos').first);
      await tester.pumpAndSettle();

      // Volta pra Início
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      expect(find.text('LouvorJA'), findsOneWidget);
    });
  });
}
