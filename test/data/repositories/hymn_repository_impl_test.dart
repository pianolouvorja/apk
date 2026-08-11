library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';

class _MockApi implements LouvorjaApiClient {
  @override
  String languagePrefix = 'pt';

  List<AlbumCategory> categoriesResult = const [];
  Map<int, List<Hymn>> albumHymns = {};
  List<Hymn> musicIndex = const [];
  bool shouldFail = false;

  @override
  Future<List<AlbumCategory>> fetchCategories() async {
    if (shouldFail) throw Exception('network error');
    return categoriesResult;
  }

  @override
  Future<List<Hymn>> fetchAlbumHymns(int albumId) async {
    if (shouldFail) throw Exception('network error');
    return albumHymns[albumId] ?? const [];
  }

  @override
  Future<Hymn> fetchMusic(int musicId) async => Hymn(id: musicId);

  @override
  Future<List<Hymn>> fetchHymnal() async => const [];

  @override
  Future<List<Hymn>> fetchMusicIndex() async {
    if (shouldFail) throw Exception('network error');
    return musicIndex;
  }

  @override
  String resolveMediaUrl(String relativePath) => 'https://example.com/$relativePath';
}

void main() {
  late _MockApi api;
  late CatalogCache cache;

  setUp(() {
    api = _MockApi();
    final tempDir = Directory.systemTemp.createTempSync('repo_test');
    cache = CatalogCache(tempDir);
  });

  test('getCategories filtra IDs 712 e 629', () async {
    api.categoriesResult = [
      AlbumCategory(id: 1, name: 'Cat 1', albums: [
        const Album(id: 100, name: 'Album A'),
        const Album(id: 712, name: 'Excluído 712'),
        const Album(id: 629, name: 'Excluído 629'),
        const Album(id: 200, name: 'Album B'),
      ]),
    ];

    final repo = HymnRepositoryImpl(api, cache);
    final result = await repo.getCategories();

    expect(result.length, 1);
    expect(result[0].albums.length, 2);
    expect(result[0].albums[0].id, 100);
    expect(result[0].albums[1].id, 200);
  });

  test('getCategories usa cache em memória na segunda chamada', () async {
    api.categoriesResult = [
      AlbumCategory(id: 1, name: 'Teste', albums: const [Album(id: 1)]),
    ];

    final repo = HymnRepositoryImpl(api, cache);
    await repo.getCategories();
    api.shouldFail = true;
    final result = await repo.getCategories();

    expect(result.length, 1);
  });

  test('getHymnsByAlbum retorna hinos', () async {
    api.albumHymns = {
      100: [const Hymn(id: 1, title: 'Hino 1'), const Hymn(id: 2, title: 'Hino 2')],
    };

    final repo = HymnRepositoryImpl(api, cache);
    final result = await repo.getHymnsByAlbum(100);

    expect(result.length, 2);
    expect(result[0].title, 'Hino 1');
  });

  test('searchHymns filtra por título', () async {
    api.musicIndex = [
      const Hymn(id: 1, title: 'Graças Dou', number: 1),
      const Hymn(id: 2, title: 'Coroai', number: 2),
      const Hymn(id: 3, title: 'Graças a Deus', number: 3),
    ];

    final repo = HymnRepositoryImpl(api, cache);
    final result = await repo.searchHymns('graças');

    expect(result.length, 2);
    expect(result[0].title, 'Graças Dou');
  });

  test('searchHymns filtra por número', () async {
    api.musicIndex = [
      const Hymn(id: 1, title: 'Hino A', number: 42),
      const Hymn(id: 2, title: 'Hino B', number: 100),
    ];

    final repo = HymnRepositoryImpl(api, cache);
    final result = await repo.searchHymns('42');

    expect(result.length, 1);
    expect(result[0].number, 42);
  });

  test('getHymn por ID', () async {
    api.musicIndex = [
      const Hymn(id: 10, title: 'Encontrado'),
      const Hymn(id: 20, title: 'Outro'),
    ];

    final repo = HymnRepositoryImpl(api, cache);
    final h = await repo.getHymn(10);

    expect(h, isNotNull);
    expect(h!.title, 'Encontrado');
  });

  test('getHymn retorna null se não existe', () async {
    api.musicIndex = [const Hymn(id: 1)];
    final repo = HymnRepositoryImpl(api, cache);
    expect(await repo.getHymn(999), isNull);
  });

  test('getAllAlbums扁平iza categorias', () async {
    api.categoriesResult = [
      AlbumCategory(id: 1, albums: [const Album(id: 1), const Album(id: 2)]),
      AlbumCategory(id: 2, albums: [const Album(id: 3)]),
    ];

    final repo = HymnRepositoryImpl(api, cache);
    await repo.getCategories();
    final albums = repo.getAllAlbums();

    expect(albums.length, 3);
  });
}
