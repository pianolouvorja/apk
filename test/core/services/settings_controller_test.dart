library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/core/services/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults seguem design system', () {
    final settings = SettingsController();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.accent, AccentKey.orange);
    expect(settings.interaction, InteractionKey.dynamic_);
    expect(settings.glassIntensity, 60);
  });

  test('persiste tema, acento, interação e glass', () async {
    final settings = SettingsController();
    await settings.setThemeMode(ThemeMode.dark);
    await settings.setAccent(AccentKey.teal);
    await settings.setInteraction(InteractionKey.soft);
    await settings.setGlassIntensity(78);

    final reloaded = SettingsController();
    await reloaded.loadSettings();
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.accent, AccentKey.teal);
    expect(reloaded.interaction, InteractionKey.soft);
    expect(reloaded.glassIntensity, 78);
  });

  test('clamp intensidade glass entre 0 e 100', () async {
    final settings = SettingsController();
    await settings.setGlassIntensity(999);
    expect(settings.glassIntensity, 100);
    await settings.setGlassIntensity(-20);
    expect(settings.glassIntensity, 0);
  });
}
