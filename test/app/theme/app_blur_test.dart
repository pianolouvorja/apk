library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/theme/app_blur.dart';

void main() {
  group('AppBlur', () {
    test('defaultIntensity = 60', () {
      expect(AppBlur.defaultIntensity, 60);
    });

    test('blurSigma(0) = 4 (mínimo)', () {
      expect(AppBlur.blurSigma(0), 4.0);
    });

    test('blurSigma(100) = 28 (máximo)', () {
      expect(AppBlur.blurSigma(100), 28.0);
    });

    test('blurSigma(50) = 16 (médio)', () {
      expect(AppBlur.blurSigma(50), 16.0);
    });

    test('blurSigma(60) = 18.4 (default)', () {
      expect(AppBlur.blurSigma(60), closeTo(18.4, 0.01));
    });

    test('fillAlpha(0) = 0.42 (42% mínimo)', () {
      expect(AppBlur.fillAlpha(0), closeTo(0.42, 0.001));
    });

    test('fillAlpha(100) = 0.82 (82% máximo)', () {
      expect(AppBlur.fillAlpha(100), closeTo(0.82, 0.001));
    });

    test('fillAlpha(60) = ~0.66 (default)', () {
      expect(AppBlur.fillAlpha(60), closeTo(0.66, 0.001));
    });

    test('clamp limita entre 0 e 100', () {
      expect(AppBlur.clamp(150), 100);
      expect(AppBlur.clamp(-10), 0);
      expect(AppBlur.clamp(50), 50);
    });

    test('clamp retorna default para NaN/Infinity', () {
      expect(AppBlur.clamp(double.nan), 60);
      expect(AppBlur.clamp(double.infinity), 60);
    });

    test('clamp arredonda para inteiro', () {
      expect(AppBlur.clamp(33.7), 34);
      expect(AppBlur.clamp(33.3), 33);
    });
  });
}
