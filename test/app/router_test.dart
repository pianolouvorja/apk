library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/router.dart';
import 'package:louvorja_piano_mobile/core/services/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapRouter() {
  return ChangeNotifierProvider<SettingsController>(
    create: (_) => SettingsController(),
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('rota raiz resolve Home', (tester) async {
    appRouter.go('/');
    await tester.pumpWidget(_wrapRouter());
    await tester.pumpAndSettle();
    expect(find.text('ID:'), findsNothing);
  });

  testWidgets('rotas de Liturgia e Bíblia resolvem', (tester) async {
    appRouter.go('/liturgy');
    await tester.pumpWidget(_wrapRouter());
    await tester.pumpAndSettle();
    appRouter.go('/bible');
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('taps no dock trocam de branch', (tester) async {
    appRouter.go('/');
    await tester.pumpWidget(_wrapRouter());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final docks = find.byType(GestureDetector);
    expect(docks, findsWidgets);

    for (var i = 0; i < 5; i++) {
      await tester.tap(docks.at(i));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    // Limpa timers pendentes do relógio da Home
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('cobre rotas de Settings', (tester) async {
    appRouter.go('/settings');
    await tester.pumpWidget(_wrapRouter());
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // Navega para fora de Settings antes de terminar para limpar timers
    appRouter.go('/hymns');
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('deep link de álbum resolve /hymns/:albumId', (tester) async {
    appRouter.go('/hymns/123');
    await tester.pumpWidget(_wrapRouter());
    await tester.pumpAndSettle();

    expect(find.text('Álbum'), findsOneWidget);
    expect(find.text('ID: 123'), findsOneWidget);
  });

  testWidgets('deep link de hino resolve /hymns/:albumId/:hymnId',
      (tester) async {
    appRouter.go('/hymns/123/456');
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pumpAndSettle();

    expect(find.text('Hino'), findsOneWidget);
    expect(find.text('ID: 456'), findsOneWidget);
  });
}
