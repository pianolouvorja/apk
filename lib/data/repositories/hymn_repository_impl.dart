library;

import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/hymn_repository.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';

/// Implementação offline-first de [HymnRepository].
///
/// Estratégia:
/// 1. Tenta cache local (TTL 24h).
/// 2. Se cache expirado/inexistente, busca remoto.
/// 3. Se remoto falhar, usa cache expirado como fallback.
/// 4. Sempre atualiza cache após sucesso remoto.
class HymnRepositoryImpl implements HymnRepository {
  final LouvorjaApiClient _api;
  final CatalogCache _cache;

  /// IDs excluídos do catálogo (hardcoded no Electron).
  static const _excludedAlbumIds = {712, 629};

  /// Cache em memória das categorias já processadas.
  List<AlbumCategory>? _categoriesCache;
  List<Album>? _flatAlbumsCache;

  HymnRepositoryImpl(this._api, this._cache);

  @override
  Future<List<AlbumCategory>> getCategories() async {
    if (_categoriesCache != null) return _categoriesCache!;

    // Tenta cache local primeiro
    final cached = _cache.read('categories');
    if (cached != null) {
      final parsed = _parseCategories(cached);
      if (parsed.isNotEmpty) {
        _categoriesCache = parsed;
        return parsed;
      }
    }

    // Busca remoto
    try {
      final categories = await _api.fetchCategories();
      _categoriesCache = _filterExcluded(categories);
      _flatAlbumsCache = null; // invalida cache flat
      return _categoriesCache!;
    } catch (_) {
      // Fallback: cache expirado
      if (cached != null) {
        final parsed = _filterExcluded(_parseCategories(cached));
        return parsed;
      }
      rethrow;
    }
  }

  @override
  Future<List<Hymn>> getHymnsByAlbum(int albumId) async {
    final cacheKey = 'album_$albumId';

    final cached = _cache.read(cacheKey);
    if (cached != null) {
      final parsed = _parseHymns(cached);
      if (parsed.isNotEmpty) return parsed;
    }

    try {
      final hymns = await _api.fetchAlbumHymns(albumId);
      _cache.write(cacheKey, hymns.map((h) => h.toJson()).toList());
      return hymns;
    } catch (_) {
      if (cached != null) return _parseHymns(cached);
      rethrow;
    }
  }

  @override
  Future<List<Hymn>> searchHymns(String query) async {
    final hymns = await _api.fetchMusicIndex();
    final q = query.toLowerCase().trim();
    return hymns.where((h) {
      final title = (h.title ?? '').toLowerCase();
      final number = h.number?.toString() ?? '';
      return title.contains(q) || number.contains(q);
    }).toList();
  }

  @override
  Future<Hymn?> getHymn(int id) async {
    final hymns = await _api.fetchMusicIndex();
    for (final h in hymns) {
      if (h.id == id) return h;
    }
    return null;
  }

  @override
  List<Album> getAllAlbums() {
    if (_flatAlbumsCache != null) return _flatAlbumsCache!;
    final result = <Album>[];
    for (final cat in _categoriesCache ?? const <AlbumCategory>[]) {
      result.addAll(cat.albums);
    }
    _flatAlbumsCache = result;
    return result;
  }

  List<AlbumCategory> _filterExcluded(List<AlbumCategory> categories) {
    return categories.map((cat) {
      final filtered = cat.albums
          .where((a) => !_excludedAlbumIds.contains(a.id))
          .toList();
      return AlbumCategory(id: cat.id, name: cat.name, albums: filtered);
    }).toList();
  }

  List<AlbumCategory> _parseCategories(dynamic data) {
    if (data is! List) return const [];
    return data
        .map((e) => AlbumCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Hymn> _parseHymns(dynamic data) {
    if (data is! List) return const [];
    return data
        .map((e) => Hymn.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
