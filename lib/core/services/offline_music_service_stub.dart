library;

import 'package:dio/dio.dart';

import 'offline_music_port.dart';

class OfflineMusicService implements OfflineMusicPort {
  const OfflineMusicService();

  @override
  bool get isSupported => false;

  @override
  Future<String?> localPathFor(
    int musicId, {
    bool instrumental = false,
  }) async => null;

  @override
  Future<void> remove(int musicId, {bool instrumental = false}) async {}

  @override
  Future<String> download({
    required int musicId,
    required String url,
    bool instrumental = false,
    ProgressCallback? onReceiveProgress,
  }) => throw UnsupportedError('Downloads offline nao suportados no Web');
}

OfflineMusicService createOfflineMusicService() => const OfflineMusicService();
