library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/app/theme/app_accents.dart';

void main() {
  group('AppAccents', () {
    test('defaultAccent é orange', () {
      expect(AppAccents.defaultAccent.id, 'orange');
    });

    test('tem exatamente 10 acentos', () {
      expect(AppAccents.all.length, 10);
    });

    test('orange tem primary #E0895A', () {
      expect(AppAccents.orange.primary, const Color(0xFFE0895A));
    });

    test('orange tem soft #F0C4A8', () {
      expect(AppAccents.orange.soft, const Color(0xFFF0C4A8));
    });

    test('azure tem primary #5B9BD5', () {
      expect(AppAccents.azure.primary, const Color(0xFF5B9BD5));
    });

    test('teal tem primary #4DB6AC', () {
      expect(AppAccents.teal.primary, const Color(0xFF4DB6AC));
    });

    test('violet tem primary #8B7BB8', () {
      expect(AppAccents.violet.primary, const Color(0xFF8B7BB8));
    });

    test('slate tem primary #7A8FA3', () {
      expect(AppAccents.slate.primary, const Color(0xFF7A8FA3));
    });

    test('byId retorna acento correto', () {
      expect(AppAccents.byId('orange').id, 'orange');
      expect(AppAccents.byId('azure').id, 'azure');
      expect(AppAccents.byId('teal').id, 'teal');
    });

    test('byId retorna default (orange) para ID inexistente', () {
      expect(AppAccents.byId('inexistente').id, 'orange');
    });

    test('todos os acentos têm label em português', () {
      for (final accent in AppAccents.all) {
        expect(accent.label, isNotEmpty);
        expect(accent.label, matches(r'[A-ZÁÉÍÓÚÂÊÔÃÕÇ]'));
      }
    });

    test('todos os acentos têm IDs únicos', () {
      final ids = AppAccents.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
