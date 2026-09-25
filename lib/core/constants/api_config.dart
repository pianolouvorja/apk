library;

/// Configuracao central da API (API.md — Configuracao Flutter).
///
/// URLs podem ser sobrescritas via --dart-define, permitindo testar o APK
/// contra uma API local sem alterar codigo:
///   flutter build apk --release \
///     --dart-define=LOUVORJA_URL_DATABASE=http://192.168.1.192:3100/json_db \
///     --dart-define=LOUVORJA_URL_FILES=http://192.168.1.192:3100/file
class ApiConfig {
  static const String urlDatabase = String.fromEnvironment(
    'LOUVORJA_URL_DATABASE',
    defaultValue: 'https://api.louvorja.com.br/json_db',
  );

  static const String urlFiles = String.fromEnvironment(
    'LOUVORJA_URL_FILES',
    defaultValue: 'https://api.louvorja.com.br/file',
  );

  static const String apiToken = String.fromEnvironment(
    'API_TOKEN',
    defaultValue: '',
  );
}
