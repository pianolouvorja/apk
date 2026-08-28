library;

import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/core/services/sync/sync_file_service.dart';
import 'package:louvorja_piano_mobile/core/services/sync/sync_package.dart';

void main() {
  test('fileNameFor gera nome canônico com data', () {
    final n = SyncFileService.fileNameFor(DateTime.utc(2026, 8, 16, 20));
    expect(n, 'louvorja-2026-08-16.louvorja');
  });

  test('isValidContent aceita pacote válido', () {
    final pkg = SyncPackage(
      appVersion: '0.1.17',
      platform: 'apk',
      exportedAt: DateTime.now().toUtc(),
    );
    expect(SyncFileService.isValidContent(pkg.encode()), isTrue);
  });

  test('isValidContent rejeita lixo e schema do futuro', () {
    expect(SyncFileService.isValidContent('não é json'), isFalse);
    expect(SyncFileService.isValidContent('{"schema": 99}'), isFalse);
    expect(SyncFileService.isValidContent('{}'), isFalse);
  });
}
