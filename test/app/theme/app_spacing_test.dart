library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    test('grade 8px: s0 = 0', () {
      expect(AppSpacing.s0, 0);
    });

    test('grade 8px: s1 = 4', () {
      expect(AppSpacing.s1, 4);
    });

    test('grade 8px: s2 = 8 (unidade base)', () {
      expect(AppSpacing.s2, 8);
    });

    test('grade 8px: s3 = 12', () {
      expect(AppSpacing.s3, 12);
    });

    test('grade 8px: s4 = 16', () {
      expect(AppSpacing.s4, 16);
    });

    test('grade 8px: s5 = 20', () {
      expect(AppSpacing.s5, 20);
    });

    test('grade 8px: s6 = 24', () {
      expect(AppSpacing.s6, 24);
    });

    test('grade 8px: s8 = 32', () {
      expect(AppSpacing.s8, 32);
    });

    test('pageMargin = 32 (margem padrão)', () {
      expect(AppSpacing.pageMargin, 32);
    });

    test('cardPadding = 20', () {
      expect(AppSpacing.cardPadding, 20);
    });

    test('navBarHeight = 72 (altura bottom nav)', () {
      expect(AppSpacing.navBarHeight, 72);
    });

    test('unit = 8 (grade base)', () {
      expect(AppSpacing.unit, 8);
    });

    test('gutterGrid = 24', () {
      expect(AppSpacing.gutterGrid, 24);
    });
  });
}
