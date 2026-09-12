library;

/// Configuracao central da API (API.md — Configuracao Flutter).
///
/// URLs podem ser sobrescritas via --dart-define, permitindo testar o APK
/// contra uma API local sem alterar codigo:
///   flutter build apk --release \
///     --dart-define=LOUVORJA_URL_DATABASE=http://192.168.1.192:3100/json_db \
///     --dart-define=LOUVORJA_URL_FILES=http://192.168.1.192:3100/file
///
/// FALLBACK (RF: app sempre com onde fazer requisicao):
/// Se a API primaria (configurada) cair, o app tenta as APIs de reserva.
/// A lista vem de LOUVORJA_FALLBACK_URLS (hosts separados por virgula);
/// sem dart-define, usa os defaults abaixo. Nada de host hardcoded fora
/// daqui — redundancia futura da nossa API = incluir o host na lista.
/// A ordem das reservas nao inclui a primaria (ela ja foi tentada).
class ApiConfig {
  static const String urlDatabase = String.fromEnvironment(
    'LOUVORJA_URL_DATABASE',
    defaultValue: 'https://api.pianolouvorja.com.br/json_db',
  );

  static const String urlFiles = String.fromEnvironment(
    'LOUVORJA_URL_FILES',
    defaultValue: 'https://api.pianolouvorja.com.br/file',
  );

  static const String _fallbackUrlsRaw = String.fromEnvironment(
    'LOUVORJA_FALLBACK_URLS',
    defaultValue:
        'https://api.louvorja.com.br,https://api.louvorja.workers.dev',
  );

  static const String apiToken = String.fromEnvironment(
    'API_TOKEN',
    defaultValue: '',
  );

  /// Host da API primaria, derivado de [urlDatabase] (mesma origem do json_db).
  static String get primaryHost {
    final uri = Uri.tryParse(urlDatabase);
    return uri?.origin ?? 'https://api.louvorja.com.br';
  }

  /// APIs de reserva (fallback), em ordem de prioridade, da env
  /// LOUVORJA_FALLBACK_URLS (virgula = separador). A primaria NAO esta
  /// aqui — o fallback so entra quando ela falha.
  static List<String> get fallbackHosts => _fallbackUrlsRaw
      .split(',')
      .map((h) => h.trim())
      .where((h) => h.isNotEmpty)
      .toList();

  /// Hosts candidatos pra database/json_db: primaria + fallbacks.
  /// Usado por quem precisa tentar hosts em cascata (LouvorjaApiImpl).
  static List<String> databaseUrls() => [
    urlDatabase,
    for (final host in fallbackHosts) '$host/json_db',
  ];

  /// Hosts candidatos pra files: primaria + fallbacks.
  static List<String> filesUrls() => [
    urlFiles,
    for (final host in fallbackHosts) '$host/file',
  ];
}
