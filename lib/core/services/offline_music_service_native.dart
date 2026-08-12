library;

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/repositories/music_offline_repository.dart';
import 'offline_music_port.dart';

class OfflineMusicService implements OfflineMusicPort {
  MusicOfflineRepository? _repository;

  @override
  bool get isSupported => true;

  Future<MusicOfflineRepository> _repositoryForApp() async {
    if (_repository != null) return _repository!;
    final documents = await getApplicationDocumentsDirectory();
    _repository = MusicOfflineRepository(
      Dio(),
      '${documents.path}/music-offline',
    );
    return _repository!;
  }

  @override
  Future<String?> localPathFor(int musicId, {bool instrumental = false}) async =>
      (await _repositoryForApp()).localPathFor(
        musicId,
        instrumental: instrumental,
      );

  @override
  Future<void> remove(int musicId, {bool instrumental = false}) async =>
      (await _repositoryForApp()).remove(musicId, instrumental: instrumental);

  @override
  Future<String> download({
    required int musicId,
    required String url,
    bool instrumental = false,
    ProgressCallback? onReceiveProgress,
  }) async =>
      (await _repositoryForApp()).download(
        musicId: musicId,
        url: url,
        instrumental: instrumental,
        onReceiveProgress: onReceiveProgress,
      );
}

OfflineMusicService createOfflineMusicService() => OfflineMusicService();
