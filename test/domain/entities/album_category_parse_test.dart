library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';

void main() {
  group('AlbumCategory._parseInt via fromJson', () {
    test('parse int direto', () {
      final cat = AlbumCategory.fromJson({'id_category': 42, 'name': 'X'});
      expect(cat.id, 42);
    });

    test('parse num (double) para int', () {
      final cat = AlbumCategory.fromJson({'id_category': 42.0, 'name': 'X'});
      expect(cat.id, 42);
    });

    test('parse String numerica', () {
      final cat = AlbumCategory.fromJson({'id_category': '99', 'name': 'Y'});
      expect(cat.id, 99);
    });

    test('parse String nao-numerica retorna 0', () {
      final cat = AlbumCategory.fromJson({'id_category': 'abc', 'name': 'Z'});
      expect(cat.id, 0);
    });

    test('parse null retorna 0', () {
      final cat = AlbumCategory.fromJson({'name': 'N'});
      expect(cat.id, 0);
    });

    test('parse bool retorna 0 (fallback)', () {
      final cat = AlbumCategory.fromJson({'id_category': true, 'name': 'B'});
      expect(cat.id, 0);
    });
  });

  group('AlbumCategory.toJson roundtrip', () {
    test('toJson com name null omite name', () {
      const cat = AlbumCategory(id: 5);
      final json = cat.toJson();
      expect(json.containsKey('name'), false);
      expect(json['id_category'], 5);
    });

    test('toJson com albums', () {
      final cat = AlbumCategory(id: 1, name: 'Test', albums: const []);
      final json = cat.toJson();
      expect(json['id_category'], 1);
      expect(json['name'], 'Test');
      expect(json['albums'], []);
    });
  });
}
