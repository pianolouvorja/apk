library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';

void main() {
  group('Album', () {
    test('fromJson com campos numéricos', () {
      final a = Album.fromJson({
        'id_album': 5,
        'name': 'Louvor JA Vol. 1',
        'subtitle': 'Jovens',
        'url_image': '/covers/lj1.png',
      });

      expect(a.id, 5);
      expect(a.name, 'Louvor JA Vol. 1');
      expect(a.subtitle, 'Jovens');
      expect(a.coverUrl, '/covers/lj1.png');
    });

    test('fromJson com id como string', () {
      final a = Album.fromJson({'id_album': '5', 'name': 'Teste'});
      expect(a.id, 5);
    });

    test('toJson round-trip', () {
      final original = Album(id: 10, name: 'Album X', subtitle: 'Sub');
      final restored = Album.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.subtitle, original.subtitle);
    });

    test('igualdade por id', () {
      expect(const Album(id: 1), const Album(id: 1));
      expect(const Album(id: 1) == const Album(id: 2), isFalse);
    });
  });

  group('AlbumCategory', () {
    test('fromJson com álbuns', () {
      final cat = AlbumCategory.fromJson({
        'id_category': 1,
        'name': 'Hinário Adventista',
        'albums': [
          {'id_album': 100, 'name': 'Hinário 2022'},
          {'id_album': 200, 'name': 'Hinário 1996'},
        ],
      });

      expect(cat.id, 1);
      expect(cat.name, 'Hinário Adventista');
      expect(cat.albums.length, 2);
      expect(cat.albums[0].id, 100);
      expect(cat.albums[1].name, 'Hinário 1996');
    });

    test('fromJson sem álbuns', () {
      final cat = AlbumCategory.fromJson({'id_category': 2, 'name': 'Vazio'});
      expect(cat.albums, isEmpty);
    });

    test('toJson round-trip', () {
      final original = AlbumCategory(
        id: 3,
        name: 'Teste',
        albums: [const Album(id: 1, name: 'A')],
      );
      final restored = AlbumCategory.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.albums.length, 1);
    });

    test('igualdade por id', () {
      expect(const AlbumCategory(id: 1), const AlbumCategory(id: 1));
      expect(const AlbumCategory(id: 1) == const AlbumCategory(id: 2), isFalse);
    });
  });
}
