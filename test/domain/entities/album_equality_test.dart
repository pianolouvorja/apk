library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';

void main() {
  test('Album == por id', () {
    const a = Album(id: 1, name: 'A');
    const b = Album(id: 1, name: 'B');
    const c = Album(id: 2, name: 'A');
    expect(a == b, true);
    expect(a == c, false);
    expect(a.hashCode, b.hashCode);
    expect(a.hashCode != c.hashCode, true);
  });

  test('Album == com objeto nao-Album', () {
    const a = Album(id: 1);
    expect(a == 'string', false);
    expect(a == 42, false);
  });

  test('AlbumCategory == por id', () {
    final a = AlbumCategory(id: 1, name: 'A');
    final b = AlbumCategory(id: 1, name: 'B');
    final c = AlbumCategory(id: 2, name: 'A');
    expect(a == b, true);
    expect(a == c, false);
    expect(a.hashCode, b.hashCode);
    expect(a.hashCode != c.hashCode, true);
  });

  test('AlbumCategory == com objeto nao-AlbumCategory', () {
    final a = AlbumCategory(id: 1);
    expect(a == 'string', false);
    expect(a == 42, false);
  });
}
