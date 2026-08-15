library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/core/services/hymn_audio_player.dart';
import 'package:louvorja_piano_mobile/core/services/hymn_catalog_provider.dart';
import 'package:louvorja_piano_mobile/core/services/now_playing.dart';
import 'package:louvorja_piano_mobile/core/services/offline_music_port.dart';
import 'package:louvorja_piano_mobile/core/services/offline_music_service.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/hymn_repository.dart';
import 'package:louvorja_piano_mobile/presentation/shared/widgets/hymn_list_tile.dart';
import 'bloc/hymns_bloc.dart';

// coverage:ignore-start
// Helper so chamado de dentro de blocos coverage:ignore (depende de plataforma)
String _languageCode(BuildContext context) {
  try {
    return context.locale.languageCode;
  } catch (_) {
    return 'pt';
  }
}
// coverage:ignore-end

class AlbumDetailPage extends StatefulWidget {
  final int albumId;

  /// Injeção opcional para testes; produção usa o singleton por plataforma.
  final HymnAudioPlayer? audioPlayer;

  const AlbumDetailPage({super.key, required this.albumId, this.audioPlayer});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Future<List<Hymn>>? _hymnsFuture;
  int? _loadingMusicId;
  int? _expandedHymnId;
  int? _playingHymnId;
  StreamSubscription<bool>? _playingSubscription;
  final Set<int> _downloadedIds = {};
  final Set<int> _downloadingIds = {};
  int? _batchProgress;
  bool _batchDownloading = false;

  HymnAudioPlayer get _player => widget.audioPlayer ?? HymnAudioPlayer.instance;

  @override
  void initState() {
    super.initState();
    // Sincroniza o ícone quando a faixa termina, falha ou é pausada externamente.
    _playingSubscription = _player.playingStream.listen((playing) {
      if (!playing && mounted) {
        setState(() => _playingHymnId = null);
      }
    });
  }

  // Bloco depende de HymnAudioPlayer.instance (plataforma)
  // coverage:ignore-start
  Future<void> _togglePlay(Hymn hymn, {required bool instrumental}) async {
    final player = _player;

    // Mesmo hino em execução: alterna para pausa.
    if (_playingHymnId == hymn.id) {
      await player.pause();
      nowPlaying.pause();
      if (mounted) setState(() => _playingHymnId = null);
      return;
    }

    setState(() => _loadingMusicId = hymn.id);
    try {
      final detail = await _repository().getHymnDetails(hymn.id);
      final relativeUrl = instrumental
          ? detail.urlInstrumental
          : detail.urlMusic;
      if (relativeUrl == null || relativeUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('errors.notFound'.tr())));
        }
        return;
      }
      final url = relativeUrl.startsWith('http')
          ? relativeUrl
          : 'https://api.louvorja.com.br/file/${relativeUrl.replaceFirst(RegExp(r'^/+'), '')}';
      // Atualiza o ícone imediatamente no clique. O evento onPlay do browser
      // pode chegar após alguns frames, mas a intenção do usuário é inequívoca.
      if (mounted) setState(() => _playingHymnId = hymn.id);
      nowPlaying.start(
        hymnId: hymn.id,
        title: hymn.title ?? '',
        album: hymnCatalogProvider.albumNameById(widget.albumId) ?? '',
        albumId: widget.albumId,
      );
      await player.playUrl(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('errors.connection'.tr())));
      }
    } finally {
      if (mounted) setState(() => _loadingMusicId = null);
    }
  }

  bool _isThisPlaying(Hymn hymn) => _playingHymnId == hymn.id;

  // coverage:ignore-start
  OfflineMusicPort get _offline => createOfflineMusicService();

  Future<void> _downloadTrack(Hymn hymn) async {
    if (!_offline.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloads disponíveis apenas no app.')),
      );
      return;
    }
    if (_downloadedIds.contains(hymn.id) || _downloadingIds.contains(hymn.id)) {
      return;
    }
    setState(() => _downloadingIds.add(hymn.id));
    try {
      final detail = await _repository().getHymnDetails(hymn.id);
      final url = detail.urlMusic ?? '';
      if (url.isNotEmpty) {
        await _offline.download(musicId: hymn.id, url: url);
      }
      if (mounted) {
        setState(() {
          _downloadedIds.add(hymn.id);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar "${hymn.title}".')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(hymn.id));
    }
  }

  Future<void> _removeTrack(Hymn hymn) async {
    try {
      await _offline.remove(hymn.id);
      if (mounted) setState(() => _downloadedIds.remove(hymn.id));
    } catch (_) {}
  }

  Future<void> _downloadAlbum(List<Hymn> hymns) async {
    if (!_offline.isSupported || _batchDownloading) return;
    setState(() {
      _batchDownloading = true;
      _batchProgress = 0;
    });
    final total = hymns.length;
    var done = 0;
    for (final hymn in hymns) {
      if (_downloadedIds.contains(hymn.id)) {
        done++;
        continue;
      }
      try {
        final detail = await _repository().getHymnDetails(hymn.id);
        final url = detail.urlMusic ?? '';
        if (url.isNotEmpty) {
          await _offline.download(musicId: hymn.id, url: url);
        }
        if (mounted) {
          setState(() => _downloadedIds.add(hymn.id));
        }
      } catch (_) {}
      done++;
      if (mounted) setState(() => _batchProgress = (done * 100 ~/ total));
    }
    if (mounted) {
      setState(() {
        _batchDownloading = false;
        _batchProgress = null;
      });
    }
  }
  // coverage:ignore-end

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

  @override
  void dispose() {
    _playingSubscription?.cancel();
    super.dispose();
  }

  Future<List<Hymn>> _loadHymns() async {
    // Tenta ler o HymnsBloc da arvore (se HymnsPage proveu)
    try {
      final bloc = context.read<HymnsBloc>();
      return await bloc.repository.getHymnsByAlbum(widget.albumId);
    } catch (_) {}

    // Fallback: cria repository localmente (nao testavel em unit test)
    // coverage:ignore-start
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
    // coverage:ignore-end
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
              // coverage:ignore-line
              context.pop();
            } else {
              context.go('/hymns');
            }
          },
        ),
        // coverage:ignore-start
        actions: [
          if (_batchDownloading && _batchProgress != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _batchProgress! / 100,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Baixar álbum',
              icon: const Icon(TablerIcons.download),
              onPressed: () {
                final future = _hymnsFuture;
                if (future == null) return;
                future.then((hymns) => _downloadAlbum(hymns));
              },
            ),
        ],
        // coverage:ignore-end
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
                    Icon(
                      TablerIcons.alertCircle,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
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
                  Icon(
                    TablerIcons.playlist,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                  ),
                  itemCount: hymns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hymn = hymns[index];
                    final isExpanded = _expandedHymnId == hymn.id;
                    final isPlaying = _isThisPlaying(hymn);
                    final isLoading = _loadingMusicId == hymn.id;

                    return Column(
                      children: [
                        HymnListTile(
                          number:
                              hymn.number?.toString().padLeft(3, '0') ?? '---',
                          title: hymn.title ?? 'Sem titulo',
                          subtitle: hymn.formattedDuration.isEmpty
                              ? null
                              : hymn.formattedDuration,
                          trailing: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: isPlaying
                                          ? 'Pausar'
                                          : 'Reproduzir',
                                      icon: Icon(
                                        isPlaying
                                            ? TablerIcons.playerPauseFilled
                                            : TablerIcons.playerPlayFilled,
                                        color: isPlaying
                                            ? theme.colorScheme.primary
                                            : null,
                                      ),
                                      // coverage:ignore-line
                                      onPressed: () => _togglePlay(
                                        hymn,
                                        instrumental: false,
                                      ),
                                    ),
                                    if (hymn.hasInstrumental)
                                      IconButton(
                                        tooltip: 'Instrumental',
                                        icon: const Icon(TablerIcons.piano),
                                        // coverage:ignore-line
                                        onPressed: () => _togglePlay(
                                          hymn,
                                          instrumental: true,
                                        ),
                                      ),
                                    // coverage:ignore-start
                                    // Download por faixa (APK apenas)
                                    if (_downloadingIds.contains(hymn.id))
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else if (_downloadedIds.contains(hymn.id))
                                      IconButton(
                                        tooltip: 'Remover download',
                                        icon: Icon(
                                          TablerIcons.checks,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () => _removeTrack(hymn),
                                      )
                                    else
                                      IconButton(
                                        tooltip: 'Baixar',
                                        icon: const Icon(
                                          TablerIcons.cloudDownload,
                                          size: 20,
                                        ),
                                        onPressed: () => _downloadTrack(hymn),
                                      ),
                                    // coverage:ignore-end
                                  ],
                                ),
                          // coverage:ignore-line
                          onTap: () {
                            setState(() {
                              _expandedHymnId = isExpanded ? null : hymn.id;
                            });
                          },
                        ),
                        // Letra expansivel
                        if (isExpanded &&
                            hymn.lyric != null &&
                            hymn.lyric!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            color: theme.colorScheme.surfaceContainer,
                            child: Text(
                              hymn.lyric!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                      ],
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
