library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:louvorja_piano_mobile/app/theme/app_accents.dart';
import 'package:louvorja_piano_mobile/app/theme/app_colors.dart';
import 'package:louvorja_piano_mobile/app/theme/app_theme.dart';

/// Testes do AppTheme usam testWidgets porque google_fonts precisa do
/// asset bundle do binding (inicializado automaticamente em testWidgets).
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme.dark (Ethereal Lumens)', () {
    testWidgets('useMaterial3 = true', (tester) async {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('brightness = dark', (tester) async {
      expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
    });

    testWidgets('surface = #131313', (tester) async {
      expect(AppTheme.dark().colorScheme.surface, EtherealLumensColors.surface);
    });

    testWidgets('onSurface = #E5E2E1', (tester) async {
      expect(
          AppTheme.dark().colorScheme.onSurface, EtherealLumensColors.onSurface);
    });

    testWidgets('primary = orange (accent default)', (tester) async {
      expect(AppTheme.dark().colorScheme.primary, AppAccents.orange.primary);
    });

    testWidgets('scaffoldBg = surface', (tester) async {
      final t = AppTheme.dark();
      expect(t.scaffoldBackgroundColor, t.colorScheme.surface);
    });

    testWidgets('cardTheme usa RoundedRectangleBorder', (tester) async {
      expect(AppTheme.dark().cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('navBarTheme height = 72', (tester) async {
      expect(AppTheme.dark().navigationBarTheme.height, 72);
    });
  });

  group('AppTheme.light (Luminous Clarity)', () {
    testWidgets('brightness = light', (tester) async {
      expect(AppTheme.light().colorScheme.brightness, Brightness.light);
    });

    testWidgets('surface = #F8F9FF', (tester) async {
      expect(
          AppTheme.light().colorScheme.surface, LuminousClarityColors.surface);
    });

    testWidgets('onSurface = #191C20', (tester) async {
      expect(AppTheme.light().colorScheme.onSurface,
          LuminousClarityColors.onSurface);
    });
  });

  group('AppTheme com accent customizado', () {
    testWidgets('dark com azure tem primary #5B9BD5', (tester) async {
      expect(AppTheme.dark(accent: AppAccents.azure).colorScheme.primary,
          AppAccents.azure.primary);
    });

    testWidgets('light com teal tem primary #4DB6AC', (tester) async {
      expect(AppTheme.light(accent: AppAccents.teal).colorScheme.primary,
          AppAccents.teal.primary);
    });

    testWidgets('dark com violet tem primary #8B7BB8', (tester) async {
      expect(AppTheme.dark(accent: AppAccents.violet).colorScheme.primary,
          AppAccents.violet.primary);
    });
  });
}
