library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Servidor HTTP local que serve o slide atual (PNG) para a TV baixar.
///
/// A TV faz HEAD antes do GET (validação LG do PoC) — ambos suportados.
/// A imagem fica em memória; trocar slide = trocar os bytes servidos.
class SlideHttpServer {
  HttpServer? _server;
  Uint8List? _currentSlide;
  int _slideCounter = 0;
  bool _jpegMode = false;

  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;

  /// Sobe em porta alta; resolve o IP local pra URL pública na LAN.
  Future<String?> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _server!.listen(_handle, onError: (_) {});
      final ip = await _localIp();
      if (ip == null) return null;
      return 'http://$ip:${_server!.port}';
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _currentSlide = null;
  }

  /// Atualiza o slide servido. Retorna a URL com counter (bust cache da TV).
  Future<String?> serveSlide(Uint8List imageBytes, {bool jpeg = false}) async {
    _currentSlide = imageBytes;
    _jpegMode = jpeg;
    _slideCounter++;
    final ip = await _localIp();
    if (ip == null || _server == null) return null;
    return 'http://$ip:${_server!.port}/slide'
        '${jpeg ? '.jpg' : '.png'}?v=$_slideCounter';
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    final bytes = _currentSlide;
    if (bytes == null) {
      res.statusCode = 404;
      await res.close();
      return;
    }
    res.headers.contentType =
        ContentType.parse(_jpegMode ? 'image/jpeg' : 'image/png');
    res.headers.set('Content-Length', bytes.length);
    if (req.method == 'HEAD') {
      await res.close();
      return;
    }
    res.add(bytes);
    await res.close();
  }

  static Future<String?> _localIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final it in interfaces) {
        for (final addr in it.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
