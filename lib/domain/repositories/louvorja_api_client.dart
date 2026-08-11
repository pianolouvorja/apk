library;

import '../../domain/entities/album_category.dart';
import '../../domain/entities/hymn.dart';

/// Contrato abstrato para acesso à API do LouvorJA.
///
/// O prefixo de idioma (ex: "pt", "en", "es") define quais catálogos
/// a API retorna. Isso garante que o conteúdo (hinos, áudio) corresponda
/// ao idioma selecionado na interface.
abstract interface class LouvorjaApiClient {
  /// Prefixo de idioma atual (ex: "pt", "en", "es").
  /// Define quais JSONs são buscados: {prefix}_categories, {prefix}_hymnal, etc.
  String get languagePrefix;

  /// Atualiza o prefixo de idioma. Próximas chamadas usam o novo prefixo.
  set languagePrefix(String value);

  /// GET json_db/{prefix}_categories → categorias + coletâneas.
  Future<List<AlbumCategory>> fetchCategories();

  /// GET json_db/album_{id} → hinos de uma coletânea.
  Future<List<Hymn>> fetchAlbumHymns(int albumId);

  /// GET json_db/music_{id} → metadados completos e URLs de áudio.
  Future<Hymn> fetchMusic(int musicId);

  /// GET json_db/{prefix}_hymnal → hinário adventista.
  Future<List<Hymn>> fetchHymnal();

  /// GET json_db/{prefix}_musics → índice global de músicas.
  Future<List<Hymn>> fetchMusicIndex();

  /// Constrói URL completa para mídia (capa, áudio).
  String resolveMediaUrl(String relativePath);
}
