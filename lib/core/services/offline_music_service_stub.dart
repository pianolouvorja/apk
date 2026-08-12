library;

import 'package:dio/dio.dart';

class OfflineMusicService {
  const OfflineMusicService();

  bool get isSupported => false;

  Future<String?> localPathFor(
    int musicId, {
    bool instrumental = false,
  }) async => null;

  Future<void> remove(int musicId, {bool instrumental = false}) async {}

  Future<String> download({
    required int musicId,
    required String url,
    bool instrumental = false,
    ProgressCallback? onReceiveProgress,
  }) => throw UnsupportedError('Downloads offline não são suportados no Web');
}

OfflineMusicService createOfflineMusicService() => const OfflineMusicService();
