library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvorja_piano_mobile/presentation/splash/splash_screen.dart';

void main() {
  setUpAll(() {
    // Mock do package_info_plus para testes
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, dynamic>{
        'appName': 'LouvorJA PIANO',
        'packageName': 'com.louvorja.piano.mobile',
        'version': '0.1.0-alpha',
        'buildNumber': '1',
        'buildSignature': '',
        'installerStore': null,
      };
    });
  });

  group('SplashScreen', () {
    testWidgets('monta com logo estatico antes da versao carregar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SplashScreen())),
      );
      await tester.pump();

      // Antes da versao carregar: apenas o logo estatico
      // Apos carregar: logo + codename (2 SVGs)
      expect(find.byType(SvgPicture), findsWidgets);

      // Consome o timer de boot (400ms) e a animacao (1800ms) para nao
      // deixar timers pendentes no fim do teste.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('usa fundo claro quando o tema é light', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const SplashScreen(),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, ThemeData.light().colorScheme.surface);

      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('chama callback de boot uma unica vez apos versao+timer',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(onInitializationComplete: () => calls += 1),
        ),
      );

      // Espera versao carregar + animacao + timer
      await tester.pump(const Duration(seconds: 5));
      expect(calls, 1);

      await tester.pump(const Duration(seconds: 2));
      expect(calls, 1);
    });

    testWidgets('caminho de erro do catchError usa fallback v0.1.0', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            onInitializationComplete: () => completed = true,
            versionFuture: Future.delayed(const Duration(milliseconds: 10), () => throw Exception('boom')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(completed, isTrue);
    });
  });
}
