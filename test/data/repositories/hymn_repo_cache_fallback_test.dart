library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/bible_book.dart';
import 'package:louvorja_piano_mobile/domain/entities/bible_version.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';

/// API que sempre falha fetchAlbumHymns.
class _FailingApi implements LouvorjaApiClient {
  @override
  String languagePrefix = 'pt';

  @override
  Future<List<AlbumCategory>> fetchCategories() async => const [];
  @override
  Future<List<Hymn>> fetchAlbumHymns(int albumId) async =>
      throw Exception('network down');

  @override
  Future<Hymn> fetchMusic(int musicId) async => Hymn(id: musicId);
  @override
  Future<List<Hymn>> fetchHymnal() async => const [];
  @override
  Future<List<Hymn>> fetchHymnal1996() async => const [];
  @override
  Future<List<Hymn>> fetchMusicIndex() async => const [];
  @override
  String resolveMediaUrl(String p) => p;
@override
  Future<List<BibleBook>> fetchBibleBooks() async => const [];
  @override
  Future<List<BibleVersion>> fetchBibleVersions() async => const [];
  @override
  Future<Map<String, String>> fetchBibleChapter(int v, int b, int c) async => {};
}

void main() {
  late Directory tempDir;
  late CatalogCache cache;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('repo_cache_fallback');
    cache = CatalogCache(tempDir);
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('getHymnsByAlbum: cache invalido + API falha = usa cache no catch',
      () async {
    // Escreve cache com dados nao-List (parsed sera vazio)
    cache.write('album_42', 'not_a_list');

    final repo = HymnRepositoryImpl(_FailingApi(), cache);

    // Fluxo: le cache -> parsed e [] (not_a_list) -> tenta API -> falha
    // -> catch: cached != null -> return _parseHymns(cached) -> []
    final result = await repo.getHymnsByAlbum(42);
    expect(result, isEmpty);
  });

  test('getHymnsByAlbum: sem cache + API falha = rethrow', () async {
    final repo = HymnRepositoryImpl(_FailingApi(), cache);

    // Fluxo: le cache -> null -> tenta API -> falha
    // -> catch: cached == null -> rethrow
    expect(
      () => repo.getHymnsByAlbum(99),
      throwsA(isA<Exception>()),
    );
  });
}
