library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

/// Biblioteca local de faixas MP3.
///
/// Usa diretório privado do app: não exige permissão de arquivos no Android.
MusicOfflineRepository createMusicOfflineRepositoryImpl() =>
    throw UnsupportedError(
      'MusicOfflineRepository requer diretório privado explícito',
    );

class MusicOfflineRepository {
  static const _indexName = 'music_offline_index.json';

  final Dio _dio;
  final Directory _root;
  Map<String, String>? _index;

  MusicOfflineRepository(this._dio, String rootPath)
    : _root = Directory(rootPath);

  File get _indexFile => File('${_root.path}/$_indexName');

  Future<Map<String, String>> _loadIndex() async {
    if (_index != null) return _index!;
    try {
      if (!await _indexFile.exists()) return _index = {};
      final decoded =
          jsonDecode(await _indexFile.readAsString()) as Map<String, dynamic>;
      return _index = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (_) {
      return _index = {};
    }
  }

  Future<void> _persistIndex() async {
    await _root.create(recursive: true);
    await _indexFile.writeAsString(jsonEncode(_index));
  }

  Future<String?> localPathFor(int musicId, {bool instrumental = false}) async {
    final index = await _loadIndex();
    final path = index[_key(musicId, instrumental)];
    if (path == null || !await File(path).exists()) {
      if (path != null) {
        index.remove(_key(musicId, instrumental));
        await _persistIndex();
      }
      return null;
    }
    return path;
  }

  Future<String> download({
    required int musicId,
    required String url,
    bool instrumental = false,
    ProgressCallback? onReceiveProgress,
  }) async {
    final existing = await localPathFor(musicId, instrumental: instrumental);
    if (existing != null) return existing;

    await _root.create(recursive: true);
    final target = File('${_root.path}/${_key(musicId, instrumental)}.mp3');
    final partial = File('${target.path}.part');
    try {
      await _dio.download(
        url,
        partial.path,
        onReceiveProgress: onReceiveProgress,
      );
      await partial.rename(target.path);
      final index = await _loadIndex();
      index[_key(musicId, instrumental)] = target.path;
      await _persistIndex();
      return target.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }

  Future<void> remove(int musicId, {bool instrumental = false}) async {
    final index = await _loadIndex();
    final key = _key(musicId, instrumental);
    final path = index.remove(key);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _persistIndex();
  }

  String _key(int musicId, bool instrumental) =>
      '${musicId}_${instrumental ? 'instrumental' : 'vocal'}';
}
