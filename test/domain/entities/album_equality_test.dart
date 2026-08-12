// ignore_for_file: unrelated_type_equality_checks, unnecessary_null_comparison
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';

void main() {
  test('Album == por id (mesmo id, nomes diferentes)', () {
    const a = Album(id: 1, name: 'A');
    const b = Album(id: 1, name: 'B');
    const c = Album(id: 2, name: 'A');
    expect(a == b, true);
    expect(a == c, false);
    expect(a.hashCode, b.hashCode);
    expect(a.hashCode != c.hashCode, true);
  });

  test('Album == com tipo diferente e identical', () {
    const a = Album(id: 1);
    expect(a == a, true); // identical
    expect(a == Object(), false);
    expect(a == 42, false);
    expect(a == null, false);
  });

  test('AlbumCategory == por id', () {
    final a = AlbumCategory(id: 1, name: 'A');
    final b = AlbumCategory(id: 1, name: 'B');
    final c = AlbumCategory(id: 2, name: 'A');
    expect(a == b, true);
    expect(a == c, false);
    expect(a.hashCode, b.hashCode);
  });

  test('AlbumCategory == com tipo diferente e identical', () {
    final a = AlbumCategory(id: 1);
    expect(a == a, true); // identical
    expect(a == Object(), false);
    expect(a == 42, false);
    expect(a == null, false);
  });
}
