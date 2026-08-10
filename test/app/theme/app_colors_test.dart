library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/theme/app_colors.dart';

void main() {
  group('AppBrandColors', () {
    test('primary é #2196F3', () {
      expect(AppBrandColors.primary, const Color(0xFF2196F3));
    });

    test('primarySoft é #9ECAFF', () {
      expect(AppBrandColors.primarySoft, const Color(0xFF9ECAFF));
    });

    test('secondary é #78D6D2', () {
      expect(AppBrandColors.secondary, const Color(0xFF78D6D2));
    });

    test('brandYellow é #F8C800 (logo oficial)', () {
      expect(AppBrandColors.brandYellow, const Color(0xFFF8C800));
    });

    test('brandBlueAlt é #0097D7', () {
      expect(AppBrandColors.brandBlueAlt, const Color(0xFF0097D7));
    });
  });

  group('EtherealLumensColors (dark)', () {
    test('background é #131313', () {
      expect(EtherealLumensColors.background, const Color(0xFF131313));
    });

    test('surface é #131313 (igual ao background)', () {
      expect(EtherealLumensColors.surface, const Color(0xFF131313));
    });

    test('surfaceElevated é #1E1E1E', () {
      expect(EtherealLumensColors.surfaceElevated, const Color(0xFF1E1E1E));
    });

    test('surfaceCard é #242424', () {
      expect(EtherealLumensColors.surfaceCard, const Color(0xFF242424));
    });

    test('onSurface é #E5E2E1', () {
      expect(EtherealLumensColors.onSurface, const Color(0xFFE5E2E1));
    });

    test('onSurfaceVariant é #BFC7D4', () {
      expect(EtherealLumensColors.onSurfaceVariant, const Color(0xFFBFC7D4));
    });

    test('outline tem alpha 0x0D (5%)', () {
      // 0x0D = 13 (alpha em int 0-255)
      expect(EtherealLumensColors.outline.a, closeTo(13 / 255, 0.01));
    });

    test('tertiary é #FFB77B', () {
      expect(EtherealLumensColors.tertiary, const Color(0xFFFFB77B));
    });
  });

  group('LuminousClarityColors (light)', () {
    test('background é #F8F9FF', () {
      expect(LuminousClarityColors.background, const Color(0xFFF8F9FF));
    });

    test('surface é #F8F9FF', () {
      expect(LuminousClarityColors.surface, const Color(0xFFF8F9FF));
    });

    test('surfaceElevated é #FFFFFF', () {
      expect(LuminousClarityColors.surfaceElevated, const Color(0xFFFFFFFF));
    });

    test('onSurface é #191C20', () {
      expect(LuminousClarityColors.onSurface, const Color(0xFF191C20));
    });

    test('onSurfaceVariant é #43474E', () {
      expect(LuminousClarityColors.onSurfaceVariant, const Color(0xFF43474E));
    });

    test('primarySoft é #0061A4 (diferente do dark)', () {
      expect(LuminousClarityColors.primarySoft, const Color(0xFF0061A4));
    });
  });
}
