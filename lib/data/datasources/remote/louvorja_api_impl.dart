library;

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';

/// Exceção user-friendly para erros de rede.
///
/// [code] mapeia para uma chave de tradução i18n.
/// [detail] mantém o erro técnico original para log.
class LouvorjaApiException implements Exception {
  final String code;
  final String detail;

  const LouvorjaApiException(this.code, this.detail);

  @override
  String toString() => 'LouvorjaApiException($code): $detail';
}

/// Implementação de [LouvorjaApiClient] usando Dio com retry e cache-buster.
class LouvorjaApiImpl implements LouvorjaApiClient {
  final Dio _dio;
  final String baseUrl;
  final String filesUrl;
  final String apiToken;
  final DateTime Function() _now;

  @override
  String languagePrefix;

  static const _maxRetries = 5;

  @visibleForTesting
  int get maxRetries => _maxRetries;

  LouvorjaApiImpl({
    required this.baseUrl,
    required this.filesUrl,
    required this.apiToken,
    this.languagePrefix = 'pt',
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Api-Token': apiToken},
        ));

  @visibleForTesting
  Dio get dio => _dio;

  String get _cacheBuster {
    final d = _now();
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }

  @override
  String resolveMediaUrl(String relativePath) {
    return '$filesUrl/$relativePath';
  }

  Future<dynamic> _fetchJson(String filename) async {
    final url = '$baseUrl/$filename?$_cacheBuster';

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _dio.get<dynamic>(url);
        return response.data is String
            ? jsonDecode(response.data as String) // coverage:ignore-line
            : response.data;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final shouldRetry = statusCode == 429 ||
            (statusCode != null && statusCode >= 500);

        if (!shouldRetry || attempt >= _maxRetries - 1) {
          if (statusCode == 401 || statusCode == 403) {
            throw const LouvorjaApiException('errors.authFailed', 'Token inválido ou ausente');
          } else if (statusCode == 404) {
            throw const LouvorjaApiException('errors.notFound', 'Recurso não encontrado');
          } else if (shouldRetry) {
            throw LouvorjaApiException('errors.serverBusy', 'Servidor ocupado após $_maxRetries tentativas');
          }
          throw LouvorjaApiException('errors.connection', 'Erro de conexão: $e');
        }

        // Respeita Retry-After se o servidor enviar
        final retryAfter = e.response?.headers.value('retry-after');
        if (retryAfter != null) {
          final raSec = int.tryParse(retryAfter) ?? 2;
          await Future.delayed(Duration(seconds: raSec));
          continue;
        }
      } on Exception catch (e) {
        if (attempt >= _maxRetries - 1) {
          throw LouvorjaApiException('errors.connection', 'Falha de rede: $e');
        }
      }

      final delayMs = (1500 * pow(1.5, attempt)).toInt();
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    throw const LouvorjaApiException('errors.unknown', 'Estado inalcançável');
  }

  @override
  Future<List<AlbumCategory>> fetchCategories() async {
    final data = await _fetchJson('${languagePrefix}_categories');
    final list = data as List<dynamic>;
    return list
        .map((e) => AlbumCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Hymn>> fetchAlbumHymns(int albumId) async {
    final data = await _fetchJson('album_$albumId');
    final map = data as Map<String, dynamic>;
    final musics = map['musics'] as List<dynamic>?;
    return musics
            ?.map((e) => Hymn.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
  }

  @override
  Future<Hymn> fetchMusic(int musicId) async {
    final data = await _fetchJson('music_$musicId');
    return Hymn.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Hymn>> fetchHymnal() async {
    final data = await _fetchJson('${languagePrefix}_hymnal');
    final list = data as List<dynamic>;
    return list.map((e) => Hymn.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Hymn>> fetchMusicIndex() async {
    final data = await _fetchJson('${languagePrefix}_musics');
    final list = data as List<dynamic>;
    return list.map((e) => Hymn.fromJson(e as Map<String, dynamic>)).toList();
  }
}
