library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvorja_piano_mobile/presentation/splash/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('monta com logo, codename e loader de marca', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashScreen()),
      );
      await tester.pump();

      // Dois SVGs: logo grande + codename + logo dentro do loader.
      expect(find.byType(SvgPicture), findsNWidgets(3));
      expect(find.byType(RotationTransition), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando...'), findsOneWidget);
    });

    testWidgets('chama callback de boot uma única vez após 2.2 segundos',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(onInitializationComplete: () => calls += 1),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2200));
      expect(calls, 1);

      await tester.pump(const Duration(seconds: 2));
      expect(calls, 1);
    });
  });
}
