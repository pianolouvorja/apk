// coverage:ignore-file
// Executor de itens da liturgia -- depende de plataforma (player, url_launcher)
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:louvorja_piano_mobile/core/services/hymn_audio_player.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/liturgy_item.dart';

/// Executa a acao correspondente ao tipo do item da liturgia.
///
/// music -> toca audio via HymnAudioPlayer (carrega music_{id} da API)
/// site/online_video -> abre URL no navegador
/// video/images/pdf/presentation/other_files -> abre arquivo local
/// scheduled -> mostra detalhes do agendamento
class LiturgyItemExecutor {
  LiturgyItemExecutor._();

  static final _api = LouvorjaApiImpl(
    baseUrl: 'https://api.louvorja.com.br/json_db',
    filesUrl: 'https://api.louvorja.com.br/file',
    apiToken: const String.fromEnvironment('API_TOKEN', defaultValue: ''),
  );

  /// Executa a acao do item. Retorna uma mensagem de feedback.
  static Future<String> execute(BuildContext context, LiturgyItem item) async {
    switch (item.type) {
      case LiturgyItemType.music:
        return _executeMusic(context, item);

      case LiturgyItemType.site:
      case LiturgyItemType.onlineVideo:
        return _executeUrl(context, item);

      case LiturgyItemType.video:
      case LiturgyItemType.images:
      case LiturgyItemType.pdf:
      case LiturgyItemType.presentation:
      case LiturgyItemType.otherFiles:
        return _executeFile(context, item);

      case LiturgyItemType.scheduled:
        _showScheduledDetails(context, item);
        return '';

      case LiturgyItemType.annotation:
      case LiturgyItemType.notice:
      case LiturgyItemType.prayer:
      case LiturgyItemType.verse:
      case LiturgyItemType.category:
        // Nao executavel -- apenas visual
        return '';
    }
  }

  static Future<String> _executeMusic(
      BuildContext context, LiturgyItem item) async {
    if (item.musicId == null) {
      return 'Hino nao vinculado';
    }
    try {
      final hymn = await _api.fetchMusic(item.musicId!);
      final relativeUrl = hymn.urlMusic ?? '';
      if (relativeUrl.isEmpty) {
        return 'Audio nao disponivel';
      }
      final url = relativeUrl.startsWith('http')
          ? relativeUrl
          : 'https://api.louvorja.com.br/file/${relativeUrl.replaceFirst(RegExp(r'^/+'), '')}';
      await HymnAudioPlayer.instance.toggleUrl(url);
      return 'Tocando: ${hymn.title ?? item.name}';
    } catch (_) {
      return 'Erro ao carregar hino';
    }
  }

  static Future<String> _executeUrl(
      BuildContext context, LiturgyItem item) async {
    final url = item.url;
    if (url == null || url.trim().isEmpty) {
      return 'URL nao definida';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return 'URL invalida';
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return 'Abrindo: $url';
    } catch (_) {
      return 'Erro ao abrir URL';
    }
  }

  static Future<String> _executeFile(
      BuildContext context, LiturgyItem item) async {
    final path = item.filePath;
    if (path == null || path.trim().isEmpty) {
      return 'Arquivo nao selecionado';
    }
    // No mobile, abrir arquivo local com url_launcher (funciona pra file://)
    // No web, mostrar SnackBar (sem sistema de arquivos)
    try {
      final uri = Uri.file(path);
      await launchUrl(uri);
      return 'Abrindo: ${path.split('/').last}';
    } catch (_) {
      return 'Nao foi possivel abrir o arquivo';
    }
  }

  static void _showScheduledDetails(BuildContext context, LiturgyItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.scheduledAt != null)
              Text('Agendado para: ${item.scheduledAt}'),
            if (item.subtitle.isNotEmpty) Text(item.subtitle),
            if (item.notes != null && item.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.notes!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Verifica se o tipo de item e executavel (tem acao ao tap).
  static bool isExecutable(LiturgyItemType type) {
    switch (type) {
      case LiturgyItemType.music:
      case LiturgyItemType.site:
      case LiturgyItemType.onlineVideo:
      case LiturgyItemType.video:
      case LiturgyItemType.images:
      case LiturgyItemType.pdf:
      case LiturgyItemType.presentation:
      case LiturgyItemType.otherFiles:
      case LiturgyItemType.scheduled:
        return true;
      case LiturgyItemType.category:
      case LiturgyItemType.annotation:
      case LiturgyItemType.notice:
      case LiturgyItemType.prayer:
      case LiturgyItemType.verse:
        return false;
    }
  }
}
