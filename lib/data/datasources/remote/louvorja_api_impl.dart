library;

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';

/// Implementação de [LouvorjaApiClient] usando Dio com retry e cache-buster.
///
/// Endpoints: JSON estáticos em {baseUrl}/json_db/{filename}?{YYYYMMDD}
/// Header: Api-Token
class LouvorjaApiImpl implements LouvorjaApiClient {
  final Dio _dio;
  final String baseUrl;
  final String filesUrl;
  final String apiToken;
  final DateTime Function() _now;

  static const _maxRetries = 5;

  LouvorjaApiImpl({
    required this.baseUrl,
    required this.filesUrl,
    required this.apiToken,
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
            ? jsonDecode(response.data as String)
            : response.data;
      } on DioException catch (e) {
        final shouldRetry = e.type == DioExceptionType.badResponse &&
            (e.response?.statusCode == 429 ||
                (e.response?.statusCode != null &&
                    e.response!.statusCode! >= 500));
        if (!shouldRetry || attempt >= _maxRetries - 1) rethrow;
      } on Exception catch (_) {
        if (attempt >= _maxRetries - 1) rethrow;
      }

      final delayMs = (1000 * pow(1.5, attempt)).toInt();
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    throw StateError('unreachable');
  }

  @override
  Future<List<AlbumCategory>> fetchCategories() async {
    final data = await _fetchJson('pt_categories');
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
  Future<List<Hymn>> fetchHymnal() async {
    final data = await _fetchJson('pt_hymnal');
    final list = data as List<dynamic>;
    return list.map((e) => Hymn.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Hymn>> fetchMusicIndex() async {
    final data = await _fetchJson('pt_musics');
    final list = data as List<dynamic>;
    return list.map((e) => Hymn.fromJson(e as Map<String, dynamic>)).toList();
  }
}
