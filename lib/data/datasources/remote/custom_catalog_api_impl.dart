import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:louvorja_piano_mobile/domain/entities/custom_collection.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_collection_music.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_lyric_slide.dart';

/// Cliente da API custom (`/v1/custom/*`) para o APK — v1 SOMENTE LEITURA.
///
/// Consumo público (sem auth): lista coletâneas da comunidade, detalhe de
/// música com letra sincronizada e registro local de "coletâneas baixadas".
/// Escrita (upload/edição) continua exclusiva do desktop web/Electron.
typedef CustomFetch =
    Future<dynamic> Function(
      String method,
      String url, {
      Map<String, dynamic>? body,
      String? bearerToken,
    });

class CustomCatalogApiImpl {
  /// Função de rede injetável (Dio por padrão) — facilita testes sem mockar Dio.
  final CustomFetch _fetch;

  /// Base da API (ex.: https://api.louvorja.com.br) — monta /v1/custom/….
  final String apiBaseUrl;

  /// Base de arquivos (ex.: https://api.louvorja.com.br/file) — resolve URLs relativas.
  final String filesBaseUrl;

  static const _joinedKey = 'louvorja.custom.joined';

  CustomCatalogApiImpl({
    required CustomFetch fetch,
    required this.apiBaseUrl,
    required this.filesBaseUrl,
  }) : _fetch = fetch;

  /// Construtor de conveniência a partir de um [Dio] existente.
  factory CustomCatalogApiImpl.withDio({
    required Dio dio,
    required String apiBaseUrl,
    required String filesBaseUrl,
  }) {
    return CustomCatalogApiImpl(
      fetch: dioCustomFetch(dio),
      apiBaseUrl: apiBaseUrl,
      filesBaseUrl: filesBaseUrl,
    );
  }

  /// Adapta um [Dio] ao contrato [CustomFetch].
  static CustomFetch dioCustomFetch(Dio dio) {
    return (
      String method,
      String url, {
      Map<String, dynamic>? body,
      String? bearerToken,
    }) {
      return dio.request<dynamic>(
        url,
        data: body,
        options: Options(
          method: method,
          headers: {
            if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
          },
        ),
      );
    };
  }

  String _api(String path) => '$apiBaseUrl/v1/custom$path';

  /// Lista coletâneas custom públicas da comunidade.
  Future<List<CustomCollection>> fetchCollections({String? bearerToken}) async {
    final response = await _fetch(
      'GET',
      _api('/collections'),
      bearerToken: bearerToken,
    );
    final data = _decode(response);
    final list = (data['data'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(_mapCollection)
        .toList(growable: false);
  }

  /// Detalhe de uma música custom (letra sincronizada inclusa).
  Future<CustomMusicDetail> fetchMusicDetail(int musicId) async {
    final response = await _fetch('GET', _api('/musics/$musicId'));
    final data = _decode(response);
    final lyrics =
        (data['lyrics'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (l) => CustomLyricLine(
                id: (l['id_lyric'] as num).toInt(),
                text: (l['lyric'] as String?) ?? '',
                auxText: l['aux_lyric'] as String?,
                time: (l['time'] as String?) ?? '00:00.000',
                order: (l['order'] as num?)?.toInt() ?? 0,
                imageUrl: l['image_url'] as String?,
              ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return CustomMusicDetail(
      id: (data['id_music'] as num).toInt(),
      collectionId: (data['id_collection'] as num?)?.toInt() ?? 0,
      name: (data['name'] as String?) ?? '',
      durationMs: (data['duration'] as num?)?.toInt(),
      audioUrl: _resolveFile(
        data['audio_url'] as String? ?? data['id_file_audio'] as String?,
      ),
      instrumentalUrl: _resolveFile(data['instrumental_url'] as String?),
      lyrics: lyrics,
    );
  }

  /// Registra coletânea como baixada (persistência local p/ aba "Baixadas").
  Future<void> joinCollection(CustomCollection collection) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_joinedKey) ?? const <String>[]).toSet();
    ids.add('${collection.id}');
    await prefs.setStringList(_joinedKey, ids.toList());
  }

  /// Cria uma coletânea nova (requer auth). Retorna o id criado.
  Future<int> createCollection({
    required String name,
    String? description,
    String? authorName,
    String? bearerToken,
  }) async {
    final response = await _fetch(
      'POST',
      _api('/collections'),
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (authorName != null && authorName.isNotEmpty)
          'author_name': authorName,
      },
      bearerToken: bearerToken,
    );
    final data = _decode(response);
    return (data['id_collection'] as num?)?.toInt() ?? 0;
  }

  /// Adiciona um hino OFICIAL a uma coletânea custom (atalho por
  /// official_music_id — não copia letra/áudio). Requer auth + ser dono.
  Future<void> addMusicToCollection({
    required int collectionId,
    required int officialMusicId,
    String? bearerToken,
  }) async {
    await _fetch(
      'POST',
      _api('/collections/$collectionId/musics'),
      body: {'official_music_id': officialMusicId},
      bearerToken: bearerToken,
    );
  }

  /// Remove uma música de uma coletânea custom (dono apenas).
  Future<void> removeMusicFromCollection({
    required int musicId,
    String? bearerToken,
  }) async {
    await _fetch('DELETE', _api('/musics/$musicId'), bearerToken: bearerToken);
  }

  /// Músicas de uma coletânea (dono ou público).
  Future<List<CustomCollectionMusic>> fetchCollectionMusics(
    int collectionId, {
    String? bearerToken,
  }) async {
    final response = await _fetch(
      'GET',
      _api('/collections/$collectionId/musics'),
      bearerToken: bearerToken,
    );
    final data = _decode(response);
    final list = data['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomCollectionMusic.fromJson)
        .toList(growable: false);
  }

  /// Renomeia/descreve uma coletânea (dono apenas).
  Future<void> updateCollection(
    int collectionId, {
    String? name,
    String? description,
    String? coverUrl,
    String? bearerToken,
  }) async {
    await _fetch(
      'PUT',
      _api('/collections/$collectionId'),
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
      },
      bearerToken: bearerToken,
    );
  }

  /// Exclui a coletânea (cascade em músicas; dono apenas).
  Future<void> deleteCollection(int collectionId, {String? bearerToken}) async {
    await _fetch(
      'DELETE',
      _api('/collections/$collectionId'),
      bearerToken: bearerToken,
    );
  }

  /// Cria uma música custom com letra (dono da coletânea). Retorna o id.
  Future<int> createMusic({
    required int collectionId,
    required String name,
    String? lyric,
    int? idFileAudio,
    int? durationMs,
    String? bearerToken,
  }) async {
    final response = await _fetch(
      'POST',
      _api('/collections/$collectionId/musics'),
      body: {
        'name': name,
        if (lyric != null && lyric.isNotEmpty) 'lyric': lyric,
        if (idFileAudio != null) 'id_file_audio': idFileAudio,
        if (durationMs != null) 'duration': durationMs,
      },
      bearerToken: bearerToken,
    );
    final data = _decode(response);
    return (data['id_music'] as num?)?.toInt() ?? 0;
  }

  /// Adiciona uma estrofe com timing numa música custom. Retorna o id.
  Future<int> addLyric({
    required int musicId,
    required String lyric,
    String? time,
    int? order,
    String? auxLyric,
    String? bearerToken,
  }) async {
    final response = await _fetch(
      'POST',
      _api('/musics/$musicId/lyrics'),
      body: {
        'lyric': lyric,
        if (time != null) 'time': time,
        if (order != null) 'order': order,
        if (auxLyric != null) 'aux_lyric': auxLyric,
      },
      bearerToken: bearerToken,
    );
    final data = _decode(response);
    return (data['id_lyric'] as num?)?.toInt() ?? 0;
  }

  /// Estrofes de uma música custom (ordenadas pela API).
  Future<List<CustomLyricSlide>> fetchLyrics(
    int musicId, {
    String? bearerToken,
  }) async {
    final response = await _fetch(
      'GET',
      _api('/musics/$musicId/lyrics'),
      bearerToken: bearerToken,
    );
    final data = _decode(response);
    final list = data['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomLyricSlide.fromJson)
        .toList(growable: false);
  }

  /// Remove uma estrofe.
  Future<void> deleteLyric(int lyricId, {String? bearerToken}) async {
    await _fetch('DELETE', _api('/lyrics/$lyricId'), bearerToken: bearerToken);
  }

  /// Atualiza tempo/texto de uma estrofe — gravação de timing (v3.1c).
  Future<void> updateLyric(
    int lyricId, {
    String? time,
    String? lyric,
    int? order,
    int? idFileImage,
    String? bearerToken,
  }) async {
    await _fetch(
      'PUT',
      _api('/lyrics/$lyricId'),
      body: {
        if (time != null) 'time': time,
        if (lyric != null) 'lyric': lyric,
        if (order != null) 'order': order,
        if (idFileImage != null) 'id_file_image': idFileImage,
      },
      bearerToken: bearerToken,
    );
  }

  /// IDs das coletâneas baixadas localmente.
  Future<Set<int>> fetchJoinedCollectionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_joinedKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  CustomCollection _mapCollection(Map<String, dynamic> json) =>
      CustomCollection(
        id: (json['id_collection'] as num).toInt(),
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        authorName: json['author_name'] as String?,
        coverUrl: _resolveFile(json['cover_url'] as String?),
        musicsCount: (json['musics_count'] as num?)?.toInt() ?? 0,
        isOwner: (json['is_owner'] as num?)?.toInt() == 1,
      );

  String? _resolveFile(String? relative) {
    if (relative == null || relative.isEmpty) return null;
    if (relative.startsWith('http')) return relative;
    final clean = relative.startsWith('/') ? relative.substring(1) : relative;
    return '$filesBaseUrl/$clean';
  }

  Map<String, dynamic> _decode(dynamic raw) {
    // Dio real devolve Response<dynamic>; os fakes de teste devolvem o Map puro.
    if (raw is Response) return _decode(raw.data);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    throw ArgumentError(
      'Resposta inesperada da API custom: ${raw.runtimeType}',
    );
  }
}
