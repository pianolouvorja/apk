library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/theme/app_radius.dart';

void main() {
  group('AppRadius — assimetria de marca TL+BR', () {
    test('sm tem topLeft arredondado (8)', () {
      expect(AppRadius.sm.topLeft, const Radius.circular(8));
    });

    test('sm tem bottomRight arredondado (8)', () {
      expect(AppRadius.sm.bottomRight, const Radius.circular(8));
    });

    test('sm NÃO tem topRight arredondado (deve ser 0)', () {
      expect(AppRadius.sm.topRight, Radius.zero);
    });

    test('sm NÃO tem bottomLeft arredondado (deve ser 0)', () {
      expect(AppRadius.sm.bottomLeft, Radius.zero);
    });

    test('md tem topLeft = 12', () {
      expect(AppRadius.md.topLeft, const Radius.circular(12));
    });

    test('md tem bottomRight = 12', () {
      expect(AppRadius.md.bottomRight, const Radius.circular(12));
    });

    test('md topRight = 0 (reta)', () {
      expect(AppRadius.md.topRight, Radius.zero);
    });

    test('lg tem topLeft = 16', () {
      expect(AppRadius.lg.topLeft, const Radius.circular(16));
    });

    test('lg tem bottomRight = 16', () {
      expect(AppRadius.lg.bottomRight, const Radius.circular(16));
    });

    test('xl tem topLeft = 24', () {
      expect(AppRadius.xl.topLeft, const Radius.circular(24));
    });

    test('xl tem bottomRight = 24', () {
      expect(AppRadius.xl.bottomRight, const Radius.circular(24));
    });

    test('full é circular (todos os cantos iguais)', () {
      expect(AppRadius.full.topLeft, AppRadius.full.topRight);
      expect(AppRadius.full.topLeft, AppRadius.full.bottomLeft);
      expect(AppRadius.full.topLeft, AppRadius.full.bottomRight);
    });

    test('eight é alias de sm (mesmo valor)', () {
      expect(AppRadius.eight.topLeft, AppRadius.sm.topLeft);
      expect(AppRadius.eight.bottomRight, AppRadius.sm.bottomRight);
    });
  });
}
