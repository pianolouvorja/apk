library;

import 'package:shared_preferences/shared_preferences.dart';

/// Timestamps de última modificação por entidade sincronizável.
///
/// Necessário para LWW (last-write-wins): sem isso não há como saber
/// qual lado escreveu por último. Chave central `sync.modified.v1.<entidade>`
/// em SharedPreferences — cada plataforma usa o equivalente do seu storage
/// (web: localStorage; Electron: user_data).
class SyncTimestamps {
  static const _prefix = 'sync.modified.v1';

  static SharedPreferences? _prefs;

  SyncTimestamps._();

  /// Inicializa com instância explícita (testes) ou singleton (app).
  static Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  static DateTime get(String entity) {
    final raw = _prefs?.getString('$_prefix.$entity');
    return DateTime.tryParse(raw ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  /// Registra AGORA como última modificação da entidade.
  /// Deve ser chamado por TODO caminho de escrita da entidade.
  /// Lazy-init: se ainda não inicializado, resolve o singleton sozinho.
  static Future<void> touch(String entity) async {
    await set(entity, DateTime.now().toUtc());
  }

  /// Define o timestamp da entidade com valor explícito (import LWW).
  static Future<void> set(String entity, DateTime ts) async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        return; // sem storage disponível — no-op
      }
    }
    await _prefs?.setString('$_prefix.$entity', ts.toUtc().toIso8601String());
  }
}
