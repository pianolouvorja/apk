library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:louvorja_piano_mobile/presentation/home/home_page.dart';

Widget _wrapHome() {
  return EasyLocalization(
    supportedLocales: const [Locale('pt', 'BR')],
    path: 'assets/translations',
    startLocale: const Locale('pt', 'BR'),
    saveLocale: false,
    child: Builder(
      builder: (context) => MaterialApp(
        home: const Scaffold(body: HomePage()),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    ),
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('HomePage', () {
    testWidgets('renderiza sem erros', (tester) async {
      await tester.pumpWidget(_wrapHome());
      // EasyLocalization precisa de varios frames pra carregar o asset
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);
    });

  });
}
