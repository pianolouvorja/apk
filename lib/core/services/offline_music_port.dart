library;

import 'package:dio/dio.dart';

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
