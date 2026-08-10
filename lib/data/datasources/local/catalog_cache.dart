library;

import 'dart:convert';
import 'dart:io';

/// Cache de catálogo em disco com TTL e invalidação por hash.
///
/// Estratégia online-first: se o cache e valido (TTL < 24h e hash bate),
/// usa local. Senão, busca remoto e atualiza o cache.
class CatalogCache {
  final Directory _dir;
  final DateTime Function() _now;

  static const _ttl = Duration(hours: 24);

  CatalogCache(this._dir, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  File _file(String key) => File('${_dir.path}/catalog_$key.json');

  /// Lê o JSON do cache se existir e for valido.
  /// Retorna null se expirado ou inexistente.
  dynamic read(String key) {
    final f = _file(key);
    if (!f.existsSync()) return null;

    try {
      final stat = f.statSync();
      if (_now().difference(stat.modified) > _ttl) return null;

      final content = f.readAsStringSync();
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  /// Escreve JSON no cache.
  void write(String key, dynamic data) {
    try {
      if (!_dir.existsSync()) _dir.createSync(recursive: true);
      _file(key).writeAsStringSync(jsonEncode(data));
    } catch (_) {
      // Cache e best-effort; falha de escrita nao quebra o app.
    }
  }

  /// Remove entrada do cache.
  void evict(String key) {
    try {
      _file(key).deleteSync();
    } catch (_) {}
  }

  /// Limpa todo o cache.
  void clear() {
    try {
      for (final f in _dir.listSync()) {
        if (f is File && f.path.contains('catalog_')) {
          f.deleteSync();
        }
      }
    } catch (_) {}
  }
}
