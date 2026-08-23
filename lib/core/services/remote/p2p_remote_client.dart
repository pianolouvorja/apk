// Cliente WebRTC do Controle Remoto P2P (web ↔ APK) — handshake 2-QR.
//
// Web mostra QR com o OFFER → APK escaneia → cria ANSWER → mostra QR +
// texto copiável (pro usuário colar no web sem webcam) → conectado.
// DataChannel roda o mesmo protocolo JSON do WS (RemoteCommand/State).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

class P2pRemoteClient {
  RTCPeerConnection? _pc;
  RTCDataChannel? _channel;

  final void Function(Map<String, dynamic> message)? onMessage;
  final void Function()? onOpen;
  final void Function()? onClose;

  P2pRemoteClient({this.onMessage, this.onOpen, this.onClose});

  bool get isOpen => _channel?.state == RTCDataChannelState.RTCDataChannelOpen;

  /// Passo 2: recebe o offer (JSON do QR do web), retorna o answer p/ QR.
  Future<String?> acceptOffer(String offerJson) async {
    try {
      final desc = jsonDecode(offerJson) as Map<String, dynamic>;
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });
      _pc!.onDataChannel = _bind;
      await _pc!.setRemoteDescription(
        RTCSessionDescription(desc['sdp'] as String, desc['type'] as String),
      );
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      // Espera ICE gathering (candidatos precisam ir no answer do QR).
      await _waitIce(_pc!);
      final local = await _pc!.getLocalDescription();
      if (local == null) return null;
      return jsonEncode({'sdp': local.sdp, 'type': local.type});
    } catch (_) {
      return null;
    }
  }

  Future<void> _waitIce(RTCPeerConnection pc) async {
    final completer = Completer<void>();
    var done = false;
    void finish() {
      if (!done && !completer.isCompleted) {
        done = true;
        completer.complete();
      }
    }

    pc.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) finish();
    };
    // timeout: segue com o que tiver
    Timer(const Duration(seconds: 5), finish);
    return completer.future;
  }

  void _bind(RTCDataChannel ch) {
    _channel = ch;
    ch.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) onOpen?.call();
      if (state == RTCDataChannelState.RTCDataChannelClosed) onClose?.call();
    };
    ch.onMessage = (data) {
      try {
        final m = jsonDecode(data.text) as Map<String, dynamic>;
        onMessage?.call(m);
      } catch (_) {}
    };
  }

  void send(Map<String, dynamic> payload) {
    if (isOpen) {
      _channel!.send(RTCDataChannelMessage(jsonEncode(payload)));
    }
  }

  void dispose() {
    _channel?.close();
    _pc?.dispose();
    _channel = null;
    _pc = null;
  }
}
