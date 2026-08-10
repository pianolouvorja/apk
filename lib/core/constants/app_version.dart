library;

import 'package:package_info_plus/package_info_plus.dart';

/// Versão do app lida dinamicamente do pubspec.yaml.
///
/// Nunca hardcodar versão em widgets -- sempre usar esta classe.
/// Quando o version do pubspec.yaml muda, todos os widgets atualizam.
class AppVersion {
  AppVersion._();

  static String? _cached;

  /// Retorna a versão completa (ex: "0.1.0-alpha").
  static Future<String> get versionString async {
    if (_cached != null) return _cached!;
    final info = await PackageInfo.fromPlatform();
    _cached = '${info.version}'
        '${info.buildNumber.isNotEmpty ? '+${info.buildNumber}' : ''}';
    return _cached!;
  }

  /// Retorna apenas o número de versão (ex: "0.1.0-alpha").
  static Future<String> get version async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Versão curta para splash/footer (ex: "v0.1.0-alpha").
  static Future<String> get displayVersion async {
    final v = await version;
    return 'v$v';
  }
}
