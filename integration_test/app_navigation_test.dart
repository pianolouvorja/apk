library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/app.dart';

/// Integration test: app completo com navegação entre todas as tabs.
///
/// Verifica que:
/// 1. App inicializa sem crash
/// 2. Tab Início está ativa por padrão
/// 3. Pode navegar para cada uma das 5 tabs
/// 4. Conteúdo correto aparece em cada tab
void main() {
  group('E2E: Navegação entre tabs', () {
    testWidgets('app inicializa na tab Início', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      // Início mostra "LouvorJA PIANO"
      expect(find.text('LouvorJA PIANO'), findsOneWidget);
    });

    testWidgets('navega para tab Hinos', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hinos').first);
      await tester.pumpAndSettle();

      // Placeholder aparece
      expect(find.text('Hinos'), findsWidgets);
    });

    testWidgets('navega para tab Liturgia', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liturgia').first);
      await tester.pumpAndSettle();

      expect(find.text('Liturgia'), findsWidgets);
    });

    testWidgets('navega para tab Bíblia', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bíblia'));
      await tester.pumpAndSettle();

      expect(find.text('Bíblia'), findsWidgets);
    });

    testWidgets('navega para tab Mais', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('volta para Início depois de navegar', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      // Vai pra Hinos
      await tester.tap(find.text('Hinos').first);
      await tester.pumpAndSettle();

      // Volta pra Início
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      expect(find.text('LouvorJA PIANO'), findsOneWidget);
    });

    testWidgets('5 NavigationDestinations existem', (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('navegação sequencial: Início -> Hinos -> Bíblia -> Mais -> Início',
        (tester) async {
      await tester.pumpWidget(const LouvorjaApp());
      await tester.pumpAndSettle();

      // Início
      expect(find.text('LouvorJA PIANO'), findsOneWidget);

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

      // -> Início
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();
      expect(find.text('LouvorJA PIANO'), findsOneWidget);
    });
  });
}
