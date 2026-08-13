library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Resultado da verificacao de atualizacao.
class UpdateCheckResult {
  final bool hasUpdate;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final int? apkSize;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.apkSize,
  });

  static const none = UpdateCheckResult(hasUpdate: false);
}

/// Servico de auto-update via GitHub Releases.
///
/// Consulta a API do GitHub por tras. O usuario nunca ve o GitHub --
/// apenas um banner com "Nova versao disponivel" e um botao "Atualizar".
class UpdateService {
  final Dio _dio;
  final String _repo;
  final Future<PackageInfo> Function() _packageInfoProvider;

  UpdateService({
    Dio? dio,
    String repo = 'pianolouvorja/apk',
    Future<PackageInfo> Function()? packageInfoProvider,
  }) : _dio = dio ?? Dio(),
       _repo = repo,
       _packageInfoProvider = packageInfoProvider ?? PackageInfo.fromPlatform;

  /// Verifica se existe uma versao mais recente no GitHub Releases.
  /// Retorna [UpdateCheckResult.none] se nao houver update ou se falhar.
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      final response = await _dio.get<dynamic>(
        'https://api.github.com/repos/$_repo/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github+json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data is String
          // coverage:ignore-line
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final tagVersion = (data['tag_name'] ?? '').toString().replaceFirst(
        'v',
        '',
      );
      if (tagVersion.isEmpty) return UpdateCheckResult.none;

      final info = await _packageInfoProvider();
      final currentVersion = info.version;
      if (currentVersion.isEmpty) return UpdateCheckResult.none;

      // Compara versao atual com a da release.
      if (!_isNewer(tagVersion, currentVersion)) {
        return UpdateCheckResult.none;
      }

      // Procura o asset APK na release.
      final assets = data['assets'] as List? ?? const [];
      String? apkUrl;
      int? apkSize;
      for (final asset in assets.whereType<Map>()) {
        final name = (asset['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url']?.toString();
          apkSize = asset['size'] as int?;
          break;
        }
      }

      if (apkUrl == null) return UpdateCheckResult.none;

      return UpdateCheckResult(
        hasUpdate: true,
        latestVersion: tagVersion,
        downloadUrl: apkUrl,
        releaseNotes: data['body']?.toString(),
        apkSize: apkSize,
      );
    } catch (_) {
      return UpdateCheckResult.none;
    }
  }

  /// Baixa o APK para o cache externo do app.
  /// Retorna o caminho do arquivo baixado.
  // coverage:ignore-line
  Future<String> downloadApk(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    // coverage:ignore-line
    final dir = await Directory.systemTemp.createTemp('piano_update');
    // coverage:ignore-line
    final filePath = '${dir.path}/piano-louvorja-update.apk';
    // coverage:ignore-line
    await _dio.download(url, filePath, onReceiveProgress: onProgress);
    return filePath;
  }

  /// Compara se [remote] e mais recente que [local].
  /// Formato esperado: "0.1.0" (semver).
  bool _isNewer(String remote, String local) {
    final r = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final l = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Padding para mesmo tamanho.
    final maxLen = r.length > l.length ? r.length : l.length;
    while (r.length < maxLen) {
      // coverage:ignore-line
      r.add(0);
    }
    while (l.length < maxLen) {
      // coverage:ignore-line
      l.add(0);
    }

    for (var i = 0; i < maxLen; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }
}
