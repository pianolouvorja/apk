import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:louvorja_piano_mobile/domain/entities/custom_collection.dart';
import 'package:louvorja_piano_mobile/domain/entities/custom_collection_music.dart';

/// Cliente da API custom (`/v1/custom/*`) para o APK — v1 SOMENTE LEITURA.
///
/// Consumo público (sem auth): lista coletâneas da comunidade, detalhe de
/// música com letra sincronizada e registro local de "coletâneas baixadas".
/// Escrita (upload/edição) continua exclusiva do desktop web/Electron.
typedef CustomFetch = Future<dynamic> Function(
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
        options: Options(method: method, headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        }),
      );
    };
  }

  String _api(String path) => '$apiBaseUrl/v1/custom$path';

  /// Lista coletâneas custom públicas da comunidade.
  Future<List<CustomCollection>> fetchCollections() async {
    final response = await _fetch('GET', _api('/collections'));
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
    final lyrics = (data['lyrics'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((l) => CustomLyricLine(
              id: (l['id_lyric'] as num).toInt(),
              text: (l['lyric'] as String?) ?? '',
              auxText: l['aux_lyric'] as String?,
              time: (l['time'] as String?) ?? '00:00.000',
              order: (l['order'] as num?)?.toInt() ?? 0,
              imageUrl: l['image_url'] as String?,
            ))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return CustomMusicDetail(
      id: (data['id_music'] as num).toInt(),
      collectionId: (data['id_collection'] as num?)?.toInt() ?? 0,
      name: (data['name'] as String?) ?? '',
      durationMs: (data['duration'] as num?)?.toInt(),
      audioUrl: _resolveFile(data['audio_url'] as String? ?? data['id_file_audio'] as String?),
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
    String? bearerToken,
  }) async {
    final response = await _fetch('POST', _api('/collections'), body: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    }, bearerToken: bearerToken);
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
    await _fetch('POST', _api('/collections/$collectionId/musics'), body: {
      'official_music_id': officialMusicId,
    }, bearerToken: bearerToken);
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
    String? bearerToken,
  }) async {
    await _fetch('PUT', _api('/collections/$collectionId'), body: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    }, bearerToken: bearerToken);
  }

  /// Exclui a coletânea (cascade em músicas; dono apenas).
  Future<void> deleteCollection(int collectionId,
      {String? bearerToken}) async {
    await _fetch('DELETE', _api('/collections/$collectionId'),
        bearerToken: bearerToken);
  }

  /// IDs das coletâneas baixadas localmente.
  Future<Set<int>> fetchJoinedCollectionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_joinedKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  CustomCollection _mapCollection(Map<String, dynamic> json) => CustomCollection(
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
    throw ArgumentError('Resposta inesperada da API custom: ${raw.runtimeType}');
  }
}
