library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import 'palco_models.dart';
import 'palco_proxy.dart';
import 'palco_sender.dart';

/// Alvo Palco descoberto na rede (mDNS ou manual).
class PalcoTarget {
  const PalcoTarget({required this.name, required this.ip, this.wsPort = 7081});
  final String name;
  final String ip;
  final int wsPort;
}

/// Controla o Palco via WS — API espelhada no CastController (DLNA) para
/// que StageSession trate os dois transportes igual.
///
/// Fluxo (validado no spike): start() → TV conecta no WS → send(projection).
/// A TV é "display burro": aqui só enviamos mensagens e ouvimos eventos
/// (unlocked/ended/remote-key) — quem decide é o módulo chamador.
class PalcoController extends ChangeNotifier {
  PalcoController({PalcoSender? sender}) : _sender = sender ?? PalcoSender();
  final PalcoSender _sender;
  StreamSubscription<PalcoMessage>? _eventsSub;

  /// Porta WS efetiva do sender (efêmera em teste).
  int get wsPort => _sender.effectiveWsPort;

  PalcoTarget? target;
  String? _httpBase;

  bool get isConnected => _sender.clientCount > 0;
  int get clientCount => _sender.clientCount;

  /// Eventos receiver→sender expostos (unlocked, ended, remote-key...).
  Stream<PalcoMessage> get events => _sender.events;

  /// Liga o sender (HTTP+WS). A TV conecta sozinha ao abrir o app dela
  /// (host informado por QR/config) — nada de push pra TV aqui.
  Future<bool> connect(PalcoTarget tv) async {
    _sender.rendererSubnetHint = tv.ip;
    final base = await _sender.start();
    if (base == null) return false;
    _httpBase = base;
    target = tv;
    _eventsSub?.cancel();
    _eventsSub = _sender.events.listen((_) {}, onError: (_) {});
    debugPrint('[PALCO] conectado (sender ativo, TV=$tv.ip)');
    notifyListeners();
    return true;
  }

  Future<void> disconnect() async {
    await _eventsSub?.cancel();
    _eventsSub = null;
    await _sender.stop();
    _httpBase = null;
    target = null;
    notifyListeners();
  }

  /// Base HTTP do sender (pra construir URLs de proxy/mídia).
  String? get httpBase => _httpBase;

  /// URL de mídia externa envelopada no proxy do sender.
  String proxyUrl(String externalUrl) => _httpBase == null
      ? externalUrl
      : PalcoProxyHeaders.wrapForProxy(_httpBase!, externalUrl);

  /// Mídia local (bytes) servida e URL pronta pra mensagem.
  String? serveMedia(String name, List<int> bytes) {
    if (_httpBase == null) return null;
    _sender.serveMedia(name, bytes);
    return '$_httpBase/media/$name';
  }

  void clearMedia() => _sender.clearMedia();

  // ---- Envios (espelham o protocolo v2) ----

  void project({required String text, String footer = '', String? background}) {
    _sender.send(PalcoMessage.projection(
        text: text, footer: footer, background: background));
  }

  void projectIdle() {
    _sender.send(PalcoMessage.idleRequest);
  }

  void setPalcoBackground(String? url) {
    _sender.send(PalcoMessage.bgPalco(url));
  }

  void playAudio(String url,
      {String? title, String? subtitle, String? cover, Duration? position}) {
    // Paths locais (file path do celular) NÃO vão ao proxy — o receiver
    // não os alcança. O chamador (StageSession) deve ter convertido via
    // serveMedia; se chegou aqui, é bug: não manda URL quebrada.
    final isHttp = url.startsWith('http://') || url.startsWith('https://');
    final target = isHttp ? proxyUrl(url) : url;
    _sender.send(PalcoMessage.audio(target,
        title: title, subtitle: subtitle, cover: cover,
        positionMs: position?.inMilliseconds));
  }

  void pauseAudio() => _sender.send(const PalcoMessage(
      type: 'audio', fields: {'action': 'pause'}));

  void resumeAudio() => _sender.send(const PalcoMessage(
      type: 'audio', fields: {'action': 'play'}));

  void stopAudio() => _sender.send(const PalcoMessage(
      type: 'audio', fields: {'action': 'stop'}));

  /// Seek no receiver (segundos). F3.3: modo tv usa a TV como relógio.
  void seekAudio(double seconds) => _sender.send(PalcoMessage(
      type: 'audio', fields: {'action': 'seek', 'position': seconds}));

  void playVideo(String url) =>
      _sender.send(PalcoMessage.video(proxyUrl(url)));

  void stopVideo() => _sender.send(const PalcoMessage(
      type: 'video', fields: {'action': 'stop'}));

  void startTimer({required int duration, String mode = 'countdown', String label = ''}) =>
      _sender.send(PalcoMessage.timer(
          action: 'start', duration: duration, mode: mode, label: label));

  void stopTimer() =>
      _sender.send(PalcoMessage.timer(action: 'stop'));

}

/// Destino do áudio quando o Palco está ativo (F3.2).
enum PalcoAudioRoute {
  /// Áudio só no celular (comportamento pré-F3.2).
  local,

  /// Áudio SÓ na TV — celular vira controle (player local parado).
  tv,

  /// Espelho: toca no celular E na TV (drift aceitável, sem sync de clock).
  mirror,
}
