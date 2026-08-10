library;

import '../../domain/entities/album_category.dart';
import '../../domain/entities/hymn.dart';

/// Contrato abstrato para acesso à API do LouvorJA.
///
/// Permite trocar a implementação (Dio, HTTP, mock) sem acoplar
/// o domínio a uma biblioteca de rede específica.
///
/// Fonte: API.md — endpoints JSON estáticos.
abstract interface class LouvorjaApiClient {
  /// GET json_db/pt_categories → categorias + coletâneas.
  Future<List<AlbumCategory>> fetchCategories();

  /// GET json_db/album_{id} → hinos de uma coletânea.
  Future<List<Hymn>> fetchAlbumHymns(int albumId);

  /// GET json_db/pt_hymnal → hinário adventista.
  Future<List<Hymn>> fetchHymnal();

  /// GET json_db/pt_musics → índice global de músicas.
  Future<List<Hymn>> fetchMusicIndex();

  /// Constrói URL completa para mídia (capa, áudio).
  String resolveMediaUrl(String relativePath);
}
