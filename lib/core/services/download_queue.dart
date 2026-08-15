library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'offline_music_port.dart';

/// Item da fila de downloads, persistivel em disco.
class DownloadQueueItem {
  final int musicId;
  final String title;
  final String url;

  const DownloadQueueItem({
    required this.musicId,
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toJson() =>
      {'musicId': musicId, 'title': title, 'url': url};

  factory DownloadQueueItem.fromJson(Map<String, dynamic> json) =>
      DownloadQueueItem(
        musicId: json['musicId'] as int,
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

/// Progresso da faixa corrente (bytes recebidos / total).
class DownloadQueueProgress {
  final int musicId;
  final String title;
  final int received;
  final int total;

  const DownloadQueueProgress({
    required this.musicId,
    required this.title,
    required this.received,
    required this.total,
  });
}

/// Persistencia do estado da fila (JSON string).
abstract interface class DownloadQueueStorage {
  Future<String> read();
  Future<void> write(String json);
}

/// Fila SERIAL de downloads com estado persistido.
///
/// - Um download por vez (nunca simultaneos) — respeita rate limiting.
/// - Pendencias gravadas em disco a cada mudanca: se o app fechar, a fila
///   e retomada no proximo boot (faixas concluidas sao puladas porque o
///   repositorio offline ja as tem no indice local).
/// - Item que falha NAO fica em loop no mesmo drain: permanece persistido
///   para retentativa no proximo boot (ou proximo enqueue).
/// - Pausa configuravel entre itens (rate limit da API).
class DownloadQueue {
  final OfflineMusicPort offline;
  final DownloadQueueStorage storage;
  final Duration interItemDelay;

  /// Progresso da faixa corrente (null quando ocioso).
  final ValueNotifier<DownloadQueueProgress?> notifier =
      ValueNotifier<DownloadQueueProgress?>(null);

  final List<DownloadQueueItem> _pending = [];
  /// Itens que falharam neste drain — ficam no disco p/ proximo boot.
  final List<DownloadQueueItem> _failedThisRun = [];
  final Set<int> _enqueuedIds = {};
  Completer<void>? _completer;
  bool _started = false;
  bool _restoring = false;

  DownloadQueue({
    required this.offline,
    required this.storage,
    this.interItemDelay = const Duration(milliseconds: 400),
  }) {
    // Restaura pendencias do disco no primeiro uso. Se houver pendencias
    // (app fechou no meio de um lote), o drain retoma automaticamente;
    // itens concluidos sao pulados pelo indice local do repositorio.
    _restoring = true;
    _completer = Completer<void>();
    _restoreAndStart();
  }

  /// Completes when the current drain finishes (no items pending).
  Future<void> get done {
    if (_restoring || _completer != null) {
      return _completer?.future ?? Future<void>.value();
    }
    return Future<void>.value();
  }

  /// Falhas do drain corrente/ultimo (exibidas como feedback ao usuario).
  int get failedCount => _failedThisRun.length;

  /// Adiciona itens e inicia o processamento serial.
  void enqueue(Iterable<DownloadQueueItem> items) {
    for (final item in items) {
      if (_enqueuedIds.contains(item.musicId)) continue;
      _enqueuedIds.add(item.musicId);
      _pending.add(item);
    }
    if (_restoring) {
      // o restore pendente vai processar os novos itens junto
      return;
    }
    _start();
  }

  Future<void> _restoreAndStart() async {
    try {
      final raw = await storage.read();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map['pending'] as List<dynamic>? ?? const [];
      for (final e in list) {
        final item = DownloadQueueItem.fromJson(e as Map<String, dynamic>);
        if (_enqueuedIds.contains(item.musicId)) continue;
        _enqueuedIds.add(item.musicId);
        _pending.add(item);
      }
    } catch (_) {
      // estado corrompido: comeca limpo
    }
    _restoring = false;
    if (_pending.isEmpty) {
      final c = _completer;
      _completer = null;
      c?.complete();
      return;
    }
    _started = true;
    _drain();
  }

  void _start() {
    if (_started) return;
    _started = true;
    // Novo drain retenta as falhas do drain anterior (elas permanecem
    // persistidas se falharem de novo).
    if (_failedThisRun.isNotEmpty) {
      _pending.insertAll(0, _failedThisRun);
      _failedThisRun.clear();
    }
    _completer ??= Completer<void>();
    _drain();
  }

  Future<void> _drain() async {
    while (_pending.isNotEmpty) {
      final item = _pending.removeAt(0);
      await _persist();
      try {
        final existing = await offline.localPathFor(item.musicId);
        if (existing == null) {
          await offline.download(
            musicId: item.musicId,
            url: item.url,
            onReceiveProgress: (received, total) {
              notifier.value = DownloadQueueProgress(
                musicId: item.musicId,
                title: item.title,
                received: received,
                total: total,
              );
            },
          );
        }
        _failedThisRun.removeWhere((e) => e.musicId == item.musicId);
      } catch (_) {
        // Falha: sem loop infinito no mesmo drain. O item permanece
        // persistido (via _failedThisRun) para o proximo boot/enqueue.
        _failedThisRun.add(item);
      }
      if (_pending.isNotEmpty && interItemDelay > Duration.zero) {
        await Future<void>.delayed(interItemDelay);
      }
    }
    notifier.value = null;
    _started = false;
    await _persist();
    final c = _completer;
    _completer = null;
    c?.complete();
  }

  /// Persiste pendencias restantes + falhas deste run.
  Future<void> _persist() async {
    try {
      await storage.write(jsonEncode({
        'pending': [..._pending, ..._failedThisRun]
            .map((e) => e.toJson())
            .toList(),
      }));
    } catch (_) {
      // persistencia best-effort: fila em memoria continua
    }
  }
}
