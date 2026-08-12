// ignore_for_file: unrelated_type_equality_checks
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';

void main() {
  test('toString inclui id, number e title', () {
    const h = Hymn(id: 42, number: 10, title: 'Gracas Dou');
    expect(h.toString(), 'Hymn(id: 42, number: 10, title: Gracas Dou)');
  });

  test('Hymn == com objeto nao-Hymn', () {
    const h = Hymn(id: 1);
    expect(h == 'string', false);
    expect(h == 42, false);
  });
}
