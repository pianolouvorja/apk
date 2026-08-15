library;

import 'offline_music_port.dart';

/// Resultado da resolução de playback de uma faixa.
class ResolvedPlayback {
  /// Fonte a tocar: caminho local OU URL remota.
  final String source;

  /// true quando toca arquivo baixado (offline).
  final bool isLocal;

  const ResolvedPlayback({required this.source, required this.isLocal});

  factory ResolvedPlayback.remote(String url) =>
      ResolvedPlayback(source: url, isLocal: false);
}

/// Resolve a fonte de áudio de uma faixa com prioridade OFFLINE-FIRST:
///
/// 1. Se a faixa existe no índice offline (baixada), toca o arquivo local.
/// 2. Caso contrário, faz streaming da URL remota.
///
/// Falhas na consulta offline NÃO derrubam o playback: caem para remoto.
class PlaybackResolver {
  const PlaybackResolver._();

  /// Caminho local da faixa, se baixada (null caso contrario).
  /// Falhas de consulta caem em null (nunca quebram o chamador).
  static Future<String?> localFor({
    required int musicId,
    bool instrumental = false,
    required OfflineMusicPort offline,
  }) async {
    try {
      if (!offline.isSupported) return null;
      final local = await offline.localPathFor(
        musicId,
        instrumental: instrumental,
      );
      if (local != null && local.isNotEmpty) return local;
    } catch (_) {
      // Indice offline inacessivel: trata como nao baixado.
    }
    return null;
  }

  static Future<ResolvedPlayback> resolve({
    required int musicId,
    required String onlineUrl,
    bool instrumental = false,
    required OfflineMusicPort offline,
  }) async {
    final local = await localFor(
      musicId: musicId,
      instrumental: instrumental,
      offline: offline,
    );
    if (local != null) {
      return ResolvedPlayback(source: local, isLocal: true);
    }
    return ResolvedPlayback.remote(onlineUrl);
  }
}
