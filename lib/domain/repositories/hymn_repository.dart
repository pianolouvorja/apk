library;

import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';

/// Contrato do repositório de hinos.
abstract interface class HymnRepository {
  /// Lista todas as categorias com suas coletâneas.
  /// Filtra IDs 712 e 629 (hardcoded no Electron).
  Future<List<AlbumCategory>> getCategories();

  /// Lista hinos de uma coletânea específica.
  Future<List<Hymn>> getHymnsByAlbum(int albumId);

  /// Busca global por número ou título.
  Future<List<Hymn>> searchHymns(String query);

  /// Hino específico por ID.
  Future<Hymn?> getHymn(int id);

  /// Lista todas as coletâneas (flat, sem categoria).
  List<Album> getAllAlbums();
}
