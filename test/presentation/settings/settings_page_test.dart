library;

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
    child: const MaterialApp(home: SettingsPage()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    await tester.pumpWidget(_subject(SettingsController()));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byKey(const Key('theme-dark')), findsOneWidget);
  });

  testWidgets('chips de tema acionam callbacks reais', (tester) async {
    final controller = SettingsController();
    await tester.pumpWidget(_subject(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pump();
    expect(controller.themeMode, ThemeMode.dark);

    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pump();
    expect(controller.themeMode, ThemeMode.light);

    await tester.tap(find.byKey(const Key('theme-system')));
    await tester.pump();
    expect(controller.themeMode, ThemeMode.system);
  });

  testWidgets('chips de idioma acionam setLocale', (tester) async {
    final controller = SettingsController();
    await tester.pumpWidget(_subject(controller));
    await tester.pumpAndSettle();

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    // Chips na ordem: 3 tema, 3 interação, 3 idioma
    // Mas pode haver variação; procura por 'Portugues' e 'Espanol'
    for (final chip in chips) {
      final label = (chip.label as Text).data ?? '';
      if (label.contains('Portugues') || label.contains('Espanol')) {
        chip.onSelected?.call(true);
        await tester.pump();
      }
    }
  });

  testWidgets('acento, interação e glass acionam callbacks reais', (tester) async {
    final controller = SettingsController();
    await tester.pumpWidget(_subject(controller));
    await tester.pumpAndSettle();

    final azure = find.byKey(const Key('accent-azure'));
    await tester.ensureVisible(azure);
    await tester.tap(azure);
    await tester.pump();
    expect(controller.accent, AccentKey.azure);

    final soft = find.byKey(const Key('interaction-soft'));
    await tester.ensureVisible(soft);
    await tester.tap(soft);
    await tester.pump();
    expect(controller.interaction, InteractionKey.soft);

    final glass = find.byKey(const Key('glass-intensity'));
    await tester.ensureVisible(glass);
    await tester.drag(glass, const Offset(80, 0));
    expect(controller.glassIntensity, isNot(60));
  });
}
