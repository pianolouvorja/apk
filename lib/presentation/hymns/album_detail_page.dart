library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/core/services/hymn_audio_player.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/hymn_repository.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/hymn_list_tile.dart';
import 'bloc/hymns_bloc.dart';

String _languageCode(BuildContext context) {
  try {
    return context.locale.languageCode;
  } catch (_) {
    return 'pt';
  }
}

class AlbumDetailPage extends StatefulWidget {
  final int albumId;

  const AlbumDetailPage({super.key, required this.albumId});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Future<List<Hymn>>? _hymnsFuture;
  int? _loadingMusicId;

  // coverage:ignore-start -- Depende de HymnAudioPlayer.instance (plataforma)
  Future<void> _play(Hymn hymn, {required bool instrumental}) async {
    setState(() => _loadingMusicId = hymn.id);
    try {
      final detail = await _repository().getHymnDetails(hymn.id);
      final relativeUrl = instrumental ? detail.urlInstrumental : detail.urlMusic;
      if (relativeUrl == null || relativeUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('errors.notFound'.tr())),
          );
        }
        return;
      }
      final url = relativeUrl.startsWith('http')
          ? relativeUrl
          : 'https://api.louvorja.com.br/file/${relativeUrl.replaceFirst(RegExp(r'^/+'), '')}';
      await HymnAudioPlayer.instance.toggleUrl(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errors.connection'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMusicId = null);
    }
  }

  HymnRepository _repository() {
    try {
      return context.read<HymnsBloc>().repository;
    } catch (_) {
      final api = LouvorjaApiImpl(
        baseUrl: 'https://api.louvorja.com.br/json_db',
        filesUrl: 'https://api.louvorja.com.br/file',
        apiToken: const String.fromEnvironment('API_TOKEN', defaultValue: ''),
        languagePrefix: _languageCode(context),
      );
      return HymnRepositoryImpl(api, CatalogCache.noop());
    }
  }
  // coverage:ignore-end

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hymnsFuture ??= _loadHymns();
  }

  Future<List<Hymn>> _loadHymns() async {
    // Tenta ler o HymnsBloc da arvore (se HymnsPage proveu)
    try {
      final bloc = context.read<HymnsBloc>();
      return bloc.repository.getHymnsByAlbum(widget.albumId);
    } catch (_) {}

    // Fallback: cria repository localmente
    final api = LouvorjaApiImpl(
      baseUrl: 'https://api.louvorja.com.br/json_db',
      filesUrl: 'https://api.louvorja.com.br/file',
      apiToken: const String.fromEnvironment('API_TOKEN', defaultValue: ''),
    );

    HymnRepository repo;
    if (kIsWeb) {
      repo = HymnRepositoryImpl(api, CatalogCache.noop());
    } else {
      // Mobile: importa path_provider condicionalmente
      repo = HymnRepositoryImpl(api, CatalogCache.noop());
    }

    return repo.getHymnsByAlbum(widget.albumId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(TablerIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/hymns');
            }
          },
        ),
      ),
      body: FutureBuilder<List<Hymn>>(
        future: _hymnsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.alertCircle, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'errors.connection'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          final hymns = snapshot.data ?? const [];
          if (hymns.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(TablerIcons.playlist, size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.s2),
                  Text('common.empty'.tr(), style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'hymns.searchPlaceholder'.tr(),
                    prefixIcon: const Icon(TablerIcons.search),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  onChanged: (query) {
                    // TODO: filtro local com debounce
                  },
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                  itemCount: hymns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hymn = hymns[index];
                    return HymnListTile(
                      number: hymn.number?.toString().padLeft(3, '0') ?? '---',
                      title: hymn.title ?? 'Sem titulo',
                      subtitle: hymn.formattedDuration.isEmpty ? null : hymn.formattedDuration,
                      trailing: _loadingMusicId == hymn.id
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Reproduzir',
                                  icon: const Icon(TablerIcons.playerPlay),
                                  onPressed: () => _play(hymn, instrumental: false),
                                ),
                                if (hymn.hasInstrumental)
                                  IconButton(
                                    tooltip: 'Instrumental',
                                    icon: const Icon(TablerIcons.piano),
                                    onPressed: () => _play(hymn, instrumental: true),
                                  ),
                              ],
                            ),
                      onTap: () => _play(hymn, instrumental: false),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
