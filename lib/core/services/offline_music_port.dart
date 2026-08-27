library;

import 'package:dio/dio.dart';

/// Faixa listável da biblioteca offline (sem depender da entidade Hymn
/// para não acoplar domain -> core).
class OfflineListedTrack {
  final int musicId;
  final String path;
  final String title;
  final String? number;
  final int? albumId;
  final String? albumName;

  const OfflineListedTrack({
    required this.musicId,
    required this.path,
    required this.title,
    this.number,
    this.albumId,
    this.albumName,
  });
}

/// Contrato mínimo e estável de playback/download. Não adicionar metadata
/// aqui: vários adaptadores/fakes dependem deste contrato.
abstract interface class OfflineMusicPort {
  bool get isSupported;

  Future<String?> localPathFor(int musicId, {bool instrumental = false});

  Future<String> download({
    required int musicId,
    required String url,
    bool instrumental = false,
    ProgressCallback? onReceiveProgress,
  });

  Future<void> remove(int musicId, {bool instrumental = false});
}

/// Capacidade opcional do adaptador nativo: listar biblioteca sem API.
/// Widgets devem testar `offline is OfflineLibraryPort` antes de usar.
abstract interface class OfflineLibraryPort {
  Future<List<OfflineListedTrack>> listDownloaded({int? albumId});

  /// Salva metadados após o download. Separado de [OfflineMusicPort.download]
  /// para não quebrar adaptadores existentes nem o playback.
  Future<void> saveMetadata({
    required int musicId,
    required String title,
    String? number,
    int? albumId,
    String? albumName,
    bool instrumental = false,
  });
}
