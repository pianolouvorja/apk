library;

import 'package:dio/dio.dart';

/// Web: download persistente de MP3 não é suportado nesta versão.
class MusicOfflineRepository {
  MusicOfflineRepository(Object _, Object __);

  Future<String?> localPathFor(
    int musicId, {
    bool instrumental = false,
  }) async => null;

  Future<String> download({
    required int musicId,
    required String url,
    bool instrumental = false,
    ProgressCallback? onReceiveProgress,
  }) => throw UnsupportedError('Downloads offline não são suportados no Web');

  Future<void> remove(int musicId, {bool instrumental = false}) async {}
}

MusicOfflineRepository createMusicOfflineRepositoryImpl() =>
    throw UnsupportedError('Downloads offline não são suportados no Web');
