library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/liturgy_item.dart';
import 'package:louvorja_piano_mobile/presentation/liturgy/weekday_math.dart';

void main() {
  group('weekdayFromDart', () {
    test('sabado (dart weekday 6) retorna saturday', () {
      // Hoje e sabado; o app estava abrindo em friday (bug reportado).
      expect(weekdayFromDart(6), LiturgyWeekday.saturday);
    });

    test('domingo (dart weekday 7) retorna sunday', () {
      expect(weekdayFromDart(7), LiturgyWeekday.sunday);
    });

    test('segunda (dart weekday 1) retorna monday', () {
      expect(weekdayFromDart(1), LiturgyWeekday.monday);
    });

    test('todos os 7 dias mapeiam corretamente', () {
      const expected = [
        (7, LiturgyWeekday.sunday),
        (1, LiturgyWeekday.monday),
        (2, LiturgyWeekday.tuesday),
        (3, LiturgyWeekday.wednesday),
        (4, LiturgyWeekday.thursday),
        (5, LiturgyWeekday.friday),
        (6, LiturgyWeekday.saturday),
      ];
      for (final (wd, day) in expected) {
        expect(weekdayFromDart(wd), day, reason: 'dart weekday $wd');
      }
    });
  });
}
