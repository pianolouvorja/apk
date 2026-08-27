library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Mantém multicast Wi-Fi ativo durante a varredura SSDP.
/// Android normalmente filtra pacotes multicast para economizar bateria;
/// sem isto a TV pode não aparecer embora esteja na mesma rede.
class MulticastLock {
  static const _channel = MethodChannel('app.louvorja/updater');

  static Future<void> acquire() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('acquireMulticastLock');
    } on PlatformException {
      // Desktop/testes: RawDatagramSocket funciona sem lock.
    } on MissingPluginException {
      // Plugin nativo ausente fora de Android.
    }
  }

  static Future<void> release() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('releaseMulticastLock');
    } on PlatformException {
      // Falha inofensiva fora de Android/Wi-Fi.
    } on MissingPluginException {
      // Plugin nativo ausente fora de Android.
    }
  }
}
