library;

import '../services/connectivity_service.dart';
import '../services/offline_music_port.dart';

/// Download sob demanda: ouvir já baixa.
///
/// Quando uma faixa remota começa a tocar, este serviço dispara em
/// BACKGROUND o download pela infra offline existente (Dio + índice v2),
/// com metadados. A reprodução NÃO espera nem falha se o download falhar
/// — é fire-and-forget puro.
///
/// Guardas:
/// - Só em Wi-Fi (decisão Rafael: dados móveis não baixa automático)
/// - Só se a faixa ainda não está no disco
/// - Adaptador sem capacidade de metadados (port antigo) baixa sem meta
class StreamCacheService {
  final OfflineMusicPort offline;
  final Future<bool> Function()? wifiCheck;

  const StreamCacheService({required this.offline, this.wifiCheck});

  /// Torna [musicId] disponível offline após este play, se aplicável.
  ///
  /// Retorna true se o download foi disparado (não se concluiu).
  Future<bool> onRemotePlay({
    required int musicId,
    required String url,
    required String title,
    String? number,
    int? albumId,
    String? albumName,
  }) async {
    try {
      // Já baixada: nada a fazer (offline-first resolve no próximo play).
      final existing = await offline.localPathFor(musicId);
      if (existing != null) return false;

      final isWifi = wifiCheck != null
          ? await wifiCheck!()
          : await ConnectivityService().isWifi;
      if (!isWifi) return false;

      await offline.download(musicId: musicId, url: url);
      final port = offline;
      if (port is OfflineLibraryPort) {
        await (port as OfflineLibraryPort).saveMetadata(
          musicId: musicId,
          title: title,
          number: number,
          albumId: albumId,
          albumName: albumName,
        );
      }
      return true;
    } catch (_) {
      // Cache de stream nunca derruba a reprodução.
      return false;
    }
  }
}
