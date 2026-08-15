library;

import 'download_queue.dart';

/// Web: sem persistencia de fila (localStorage ficaria para o futuro).
class MemoryDownloadQueueStorage implements DownloadQueueStorage {
  String _json = '{}';

  @override
  Future<String> read() async => _json;

  @override
  Future<void> write(String json) async => _json = json;
}

DownloadQueueStorage createDownloadQueueStorage() =>
    MemoryDownloadQueueStorage();
