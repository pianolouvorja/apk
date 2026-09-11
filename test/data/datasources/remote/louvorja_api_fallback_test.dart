import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:louvorja_piano_mobile/core/constants/api_config.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';

/// Registra as URLs requisitadas e responde conforme o script.
class _ScriptedAdapter implements HttpClientAdapter {
  final List<String> requested = [];
  final Object? Function(String url) _responder;

  _ScriptedAdapter(this._responder);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());
    final result = _responder(options.uri.toString());
    if (result is int) {
      // simula erro HTTP sem corpo util
      return ResponseBody.fromString('{"error":"x"}', result);
    }
    // simulando host morto: lanca erro de conexao (sem statusCode)
    if (result == 'network') {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      result as String,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LouvorjaApiImpl fallback de hosts', () {
    test('host morto → failover imediato pro proximo e resposta', () async {
      final adapter = _ScriptedAdapter((url) {
        if (url.startsWith('https://primary.test')) return 'network';
        return '[{"id_hymn": 1, "title": "T", "number": 1, "category": "hino"}]';
      });
      final api = LouvorjaApiImpl(
        baseUrls: [
          'https://primary.test/json_db',
          'https://backup.test/json_db',
        ],
        filesUrls: ['https://primary.test/file', 'https://backup.test/file'],
        apiToken: '',
      )..dio.httpClientAdapter = adapter;

      final data = await api.fetchHymnal1996();

      expect(data, isNotNull);
      // falhou na primaria e foi pra backup
      expect(
        adapter.requested.first.startsWith('https://primary.test'),
        isTrue,
      );
      expect(
        adapter.requested.any((u) => u.startsWith('https://backup.test')),
        isTrue,
      );
      expect(api.activeUrlIndex, 1);
    });

    test('esgotou retries com 5xx na primaria → tenta fallback', () async {
      final adapter = _ScriptedAdapter((url) {
        if (url.startsWith('https://primary.test')) return 500;
        return '[{"id_hymn": 2, "title": "T2", "number": 2, "category": "hino"}]';
      });
      final api = LouvorjaApiImpl(
        baseUrls: [
          'https://primary.test/json_db',
          'https://backup.test/json_db',
        ],
        filesUrls: ['https://primary.test/file', 'https://backup.test/file'],
        apiToken: '',
      )..dio.httpClientAdapter = adapter;

      final data = await api.fetchHymnal1996();
      expect(data, isNotNull);
      expect(api.activeUrlIndex, 1);
    });

    test('primaria saudavel → fallback nunca acionado', () async {
      final adapter = _ScriptedAdapter(
        (url) =>
            '[{"id_hymn": 3, "title": "T3", "number": 3, "category": "hino"}]',
      );
      final api = LouvorjaApiImpl(
        baseUrls: [
          'https://primary.test/json_db',
          'https://backup.test/json_db',
        ],
        filesUrls: ['https://primary.test/file', 'https://backup.test/file'],
        apiToken: '',
      )..dio.httpClientAdapter = adapter;

      await api.fetchHymnal1996();
      expect(
        adapter.requested.every((u) => u.startsWith('https://primary.test')),
        isTrue,
      );
      expect(api.activeUrlIndex, 0);
    });

    test('failover altera resolveMediaUrl pro host ativo', () async {
      final adapter = _ScriptedAdapter((url) {
        if (url.startsWith('https://primary.test')) return 'network';
        return '[{"id_hymn": 4, "title": "T4", "number": 4, "category": "hino"}]';
      });
      final api = LouvorjaApiImpl(
        baseUrls: [
          'https://primary.test/json_db',
          'https://backup.test/json_db',
        ],
        filesUrls: ['https://primary.test/file', 'https://backup.test/file'],
        apiToken: '',
      )..dio.httpClientAdapter = adapter;

      expect(api.resolveMediaUrl('x.mp3'), 'https://primary.test/file/x.mp3');
      await api.fetchHymnal1996();
      expect(api.resolveMediaUrl('x.mp3'), 'https://backup.test/file/x.mp3');
    });
  });

  group('ApiConfig cadeia de fallback', () {
    test('databaseUrls/filesUrls incluem primaria + 2 fallbacks na ordem', () {
      final dbs = ApiConfig.databaseUrls();
      expect(dbs.first, ApiConfig.urlDatabase);
      expect(dbs, contains('https://api.louvorja.com.br/json_db'));
      expect(dbs, contains('https://api.louvorja.workers.dev/json_db'));
      // primaria vem primeiro
      expect(
        dbs.indexOf('https://api.louvorja.com.br/json_db'),
        lessThan(dbs.indexOf('https://api.louvorja.workers.dev/json_db')),
      );

      final files = ApiConfig.filesUrls();
      expect(files.first, ApiConfig.urlFiles);
      expect(files, contains('https://api.louvorja.com.br/file'));
      expect(files, contains('https://api.louvorja.workers.dev/file'));
    });
  });
}
