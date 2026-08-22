library;

import 'dart:convert';
import 'dart:math';

/// Protocolo "LouvorJA Remote v1" — JSON sobre WebSocket.
///
/// Envelope único, bidirecional. O APK é cliente quando controla o Desktop
/// (Electron = servidor WS :7070) e servidor quando controla o Web
/// (browser não aceita conexão de entrada → conecta no APK).
///
/// Regras (SPEC ~/.hermes/specs/2026-08-16-controle-remoto-apk.md):
/// - `v` SEMPRE 1; `v` diferente = mensagem de peer futuro → ignorar.
/// - Comandos são idempotentes e exigem ack; sem ack em 3s = erro de UI.
/// - Estado é COMPLETO (não delta) — reconexão resync total.
/// - Parser nunca lança: entrada inválida → null (peer ruim não derruba app).

enum RemoteAction {
  play('player.play'),
  pause('player.pause'),
  toggle('player.toggle'),
  next('player.next'),
  previous('player.previous'),
  stop('player.stop'),
  setVolume('player.setVolume'),
  seek('player.seek'),
  setMode('player.setMode'),
  open('player.open'),
  // Liturgia no desktop — prioridade (multiplos monitores + projetor).
  liturgyNext('liturgy.next'),
  liturgyPrevious('liturgy.previous'),
  liturgySelect('liturgy.select'),
  liturgyToggleDone('liturgy.toggleDone'),
  liturgyState('liturgy.state');

  const RemoteAction(this.wire);
  final String wire;

  static RemoteAction? fromWire(String? wire) {
    if (wire == null) return null;
    for (final a in RemoteAction.values) {
      if (a.wire == wire) return a;
    }
    return null;
  }
}

/// Modos aceitos por setMode/open (espelham o Media.js do desktop).
const kRemoteModes = {'audio', 'instrumental', 'video'};

sealed class RemoteMessage {
  const RemoteMessage();

  String encode();
}

/// APK → alvo: comando de player.
class RemoteCommand extends RemoteMessage {
  RemoteCommand({
    required this.id,
    required this.action,
    this.token,
    this.volume,
    this.position,
    this.mode,
    this.hymnId,
    this.index,
  }) : assert(volume == null || (volume >= 0 && volume <= 100), 'volume 0-100'),
       assert(position == null || !position.isNegative, 'seek >= 0');

  final String id;
  final RemoteAction action;
  String? token;
  final int? volume;
  final Duration? position;
  final String? mode;
  final int? hymnId;

  /// Índice do item da liturgia (liturgy.select/toggleDone).
  final int? index;

  @override
  String encode() {
    final map = <String, dynamic>{
      'v': 1,
      'type': 'command',
      'id': id,
      'action': action.wire,
      if (token != null) 'token': token,
      if (volume != null) 'value': volume,
      if (position != null) 'positionMs': position!.inMilliseconds,
      if (mode != null) 'mode': mode,
      if (hymnId != null) 'hymnId': hymnId,
      if (index != null) 'value': index,
    };
    return jsonEncode(map);
  }
}

/// Item da liturgia do desktop espelhado no APK.
class RemoteLiturgyItem {
  const RemoteLiturgyItem({
    required this.index,
    required this.type,
    required this.title,
    required this.done,
  });

  final int index;
  final String type;
  final String? title;
  final bool done;
}

/// Alvo → APK: estado COMPLETO do player (push na conexão e após comandos).
class RemotePlayerState extends RemoteMessage {
  const RemotePlayerState({
    this.hymnId,
    this.title,
    this.mode,
    required this.playing,
    required this.position,
    required this.duration,
    required this.slideIndex,
    required this.slideCount,
    required this.volume,
    required this.canPrevious,
    required this.canNext,
    this.liturgyItems = const [],
    this.liturgySelectedIndex,
  });

  final int? hymnId;
  final String? title;
  final String? mode;
  final bool playing;
  final Duration position;
  final Duration duration;
  final int slideIndex;
  final int slideCount;
  final int volume;
  final bool canPrevious;
  final bool canNext;

  /// Espelho da liturgia do desktop (v1.1) — vazio em peers antigos.
  final List<RemoteLiturgyItem> liturgyItems;
  final int? liturgySelectedIndex;

  @override
  String encode() {
    return jsonEncode({
      'v': 1,
      'type': 'state',
      'player': {
        if (hymnId != null) 'hymnId': hymnId,
        if (title != null) 'title': title,
        if (mode != null) 'mode': mode,
        'playing': playing,
        'positionMs': position.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'slideIndex': slideIndex,
        'slideCount': slideCount,
        'volume': volume,
        'canPrevious': canPrevious,
        'canNext': canNext,
      },
    });
  }
}

/// Alvo → APK: resultado de um comando.
class RemoteAck extends RemoteMessage {
  const RemoteAck({required this.id, required this.ok});

  final String id;
  final bool ok;

  @override
  String encode() => jsonEncode({'v': 1, 'type': 'ack', 'id': id, 'ok': ok});
}

/// Erro de protocolo (ação desconhecida, token inválido etc.).
class RemoteError extends RemoteMessage {
  const RemoteError({required this.id, required this.code, this.message});

  final String id;
  final String code;
  final String? message;

  @override
  String encode() => jsonEncode({
    'v': 1,
    'type': 'error',
    'id': id,
    'code': code,
    if (message != null) 'message': message,
  });
}

/// Heartbeat: cada lado manda a cada 15s; 10s sem resposta = conexão morta.
class RemotePing extends RemoteMessage {
  const RemotePing();

  @override
  String encode() => jsonEncode({'v': 1, 'type': 'ping'});
}

class RemotePong extends RemoteMessage {
  const RemotePong();

  final String type = 'pong';

  @override
  String encode() => jsonEncode({'v': 1, 'type': 'pong'});
}

/// Parser tolerante: NUNCA lança. Tudo que viola o protocolo v1 → null.
class RemoteProtocol {
  static RemoteMessage? parse(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['v'] != 1) return null;
    final type = decoded['type'];
    switch (type) {
      case 'command':
        return _parseCommand(decoded);
      case 'state':
        return _parseState(decoded);
      case 'ack':
        final id = decoded['id'];
        if (id is! String) return null;
        return RemoteAck(id: id, ok: decoded['ok'] == true);
      case 'error':
        final id = decoded['id'];
        final code = decoded['code'];
        if (id is! String || code is! String) return null;
        final msg = decoded['message'];
        return RemoteError(
          id: id,
          code: code,
          message: msg is String ? msg : null,
        );
      case 'ping':
        return const RemotePing();
      case 'pong':
        return const RemotePong();
      default:
        return null;
    }
  }

  static RemoteCommand? _parseCommand(Map<String, dynamic> m) {
    final id = m['id'];
    if (id is! String) return null;
    final action = RemoteAction.fromWire(m['action'] as String?);
    if (action == null) return null;

    int? volume;
    if (m.containsKey('value')) {
      final v = m['value'];
      if (v is! num || v < 0 || v > 100) return null;
      volume = v.toInt();
    }

    Duration? position;
    if (m.containsKey('positionMs')) {
      final p = m['positionMs'];
      if (p is! num || p < 0) return null;
      position = Duration(milliseconds: p.toInt());
    }

    String? mode;
    if (m.containsKey('mode')) {
      final md = m['mode'];
      if (md is! String || !kRemoteModes.contains(md)) return null;
      mode = md;
    }

    int? hymnId;
    if (m.containsKey('hymnId')) {
      final h = m['hymnId'];
      if (h is! num || h <= 0) return null;
      hymnId = h.toInt();
    }

    final token = m['token'];
    return RemoteCommand(
      id: id,
      action: action,
      token: token is String ? token : null,
      volume: volume,
      position: position,
      mode: mode,
      hymnId: hymnId,
    );
  }

  static RemotePlayerState? _parseState(Map<String, dynamic> m) {
    final p = m['player'];
    if (p is! Map<String, dynamic>) return null;

    int? intOrNull(Object? v) => v is num ? v.toInt() : null;

    final hymnId = intOrNull(p['hymnId']);
    if (p.containsKey('hymnId') && p['hymnId'] is num && hymnId == null) {
      return null;
    }
    final title = p['title'];
    final mode = p['mode'];
    final playing = p['playing'];
    if (playing is! bool) return null;

    final positionMs = p['positionMs'];
    final durationMs = p['durationMs'];
    if (positionMs is! num || durationMs is! num) return null;
    if (positionMs < 0 || durationMs < 0) return null;

    return RemotePlayerState(
      hymnId: hymnId,
      title: title is String ? title : null,
      mode: mode is String ? mode : null,
      playing: playing,
      position: Duration(milliseconds: positionMs.toInt()),
      duration: Duration(milliseconds: durationMs.toInt()),
      slideIndex: intOrNull(p['slideIndex']) ?? 0,
      slideCount: intOrNull(p['slideCount']) ?? 0,
      volume: intOrNull(p['volume']) ?? 0,
      canPrevious: p['canPrevious'] == true,
      canNext: p['canNext'] == true,
    );
  }
}

/// Token de emparelhamento: 6 chars [A-Z0-9], sem caracteres ambíguos
/// (0/O e 1/I excluídos) pra leitura humana no QR/URL.
class RemotePairing {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateToken([Random? random]) {
    final rng = random ?? Random.secure();
    return String.fromCharCodes(
      List.generate(
        6,
        (_) => _alphabet.codeUnitAt(rng.nextInt(_alphabet.length)),
      ),
    );
  }

  /// Compara em tempo constante (evita timing attack em LAN).
  static bool matches(String expected, String provided) {
    if (expected.length != provided.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ provided.codeUnitAt(i);
    }
    return diff == 0;
  }
}
