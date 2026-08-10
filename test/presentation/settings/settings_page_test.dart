library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/core/services/settings_controller.dart';
import 'package:louvorja_piano_mobile/presentation/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _subject(SettingsController controller) {
  return ChangeNotifierProvider<SettingsController>.value(
    value: controller,
    child: EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR')],
      path: 'assets/translations',
      startLocale: const Locale('pt', 'BR'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          home: const SettingsPage(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        ),
      ),
    ),
  );
}

Future<void> _pumpSettings(WidgetTester tester, SettingsController controller) async {
  await tester.pumpWidget(_subject(controller));
  // Carrega tradução e encerra o timeout defensivo do PackageInfo.
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => <String, dynamic>{
              'appName': 'LouvorJA PIANO',
              'packageName': 'com.louvorja.piano.mobile',
              'version': '0.1.0-alpha',
              'buildNumber': '1',
              'buildSignature': '',
              'installerStore': null,
            });
  });

  testWidgets('renderiza todas as configurações', (tester) async {
    await _pumpSettings(tester, SettingsController());

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
  });

  testWidgets('controller atualiza tema, acento, interação e glass', (tester) async {
    final controller = SettingsController();
    await _pumpSettings(tester, controller);

    await controller.setThemeMode(ThemeMode.dark);
    await controller.setAccent(AccentKey.azure);
    await controller.setInteraction(InteractionKey.soft);
    await controller.setGlassIntensity(80);
    await tester.pump();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.accent, AccentKey.azure);
    expect(controller.interaction, InteractionKey.soft);
    expect(controller.glassIntensity, 80);
  });
}
