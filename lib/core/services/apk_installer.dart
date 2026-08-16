library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Instala um APK baixado.
///
/// Android: PackageInstaller.Session via platform channel
/// (`app.louvorja/updater`) — bytes vão direto pra sessão do SISTEMA,
/// sem FileProvider/URI content://. Imune ao processo do app ser
/// congelado pelo OneUI durante a instalação (bug do fluxo OpenFilex
/// 2026-08-16: instalador abria, "Atualizando…", abortava e a versão
/// não mudava).
///
/// Fallback (web/antigo): retorna false — chamador usa OpenFilex.
class ApkInstaller {
  static const _channel = MethodChannel('app.louvorja/updater');

  /// true se a instalação foi entregue à sessão do sistema.
  static Future<bool> install(String apkPath) async {
    if (kIsWeb) return false;
    try {
      await _channel.invokeMethod<bool>('installApk', {'path': apkPath});
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
