import 'package:flutter_test/flutter_test.dart';

import 'package:louvorja_piano_mobile/core/constants/api_config.dart';

/// Fallback em cascata de APIs (RF: app sempre com onde fazer requisicao).
/// Ordem: primaria (pianolouvorja) → louvorja → workers.dev (mirror comunidade).
void main() {
  group('ApiConfig — cascade de hosts', () {
    test('defaults: primaria = api.pianolouvorja.com.br', () {
      expect(
        ApiConfig.urlDatabase,
        'https://api.pianolouvorja.com.br/json_db',
      );
      expect(ApiConfig.urlFiles, 'https://api.pianolouvorja.com.br/file');
    });

    test('databaseUrls: primaria + 2 fallbacks na ordem, sem duplicar', () {
      final urls = ApiConfig.databaseUrls();
      expect(urls, [
        'https://api.pianolouvorja.com.br/json_db',
        'https://api.louvorja.com.br/json_db',
        'https://api.louvorja.workers.dev/json_db',
      ]);
    });

    test('filesUrls: mesma cascata com /file', () {
      final urls = ApiConfig.filesUrls();
      expect(urls, [
        'https://api.pianolouvorja.com.br/file',
        'https://api.louvorja.com.br/file',
        'https://api.louvorja.workers.dev/file',
      ]);
    });

    test('primaryHost deriva da urlDatabase', () {
      expect(ApiConfig.primaryHost, 'https://api.pianolouvorja.com.br');
    });

    test('fallbackHosts nao contem a primaria', () {
      expect(
        ApiConfig.fallbackHosts.any((h) => h.contains('pianolouvorja')),
        isFalse,
      );
    });
  });
}
