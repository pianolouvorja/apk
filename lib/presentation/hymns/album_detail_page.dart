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
import 'package:louvorja_piano_mobile/core/services/download_queue.dart';
import 'package:louvorja_piano_mobile/core/services/download_queue_storage_factory.dart';
import 'package:louvorja_piano_mobile/core/services/download_url_builder.dart';
import 'package:louvorja_piano_mobile/core/services/connectivity_service.dart';
import 'package:louvorja_piano_mobile/core/services/now_playing.dart';
import 'package:louvorja_piano_mobile/core/services/hymn_player_adapter.dart';
import 'package:louvorja_piano_mobile/presentation/hymns/now_playing_page.dart';
import 'package:louvorja_piano_mobile/core/services/offline_library_filter.dart';
import 'package:louvorja_piano_mobile/core/services/stream_cache_service.dart';
import 'package:louvorja_piano_mobile/core/services/offline_music_port.dart';
import 'package:louvorja_piano_mobile/core/services/playback_resolver.dart';
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

  /// Porta offline injetável para testes; produção usa a factory nativa.
  final OfflineMusicPort? offlineService;

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    this.audioPlayer,
    this.offlineService,
  });

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
  bool _batchDownloading = false;
  String? _batchTrackTitle;
  int _batchTrackReceived = 0;
  int _batchTrackTotal = 0;

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
      // Offline-first: faixa baixada toca do disco sem consultar a API
      // (funciona sem internet e economiza requests).
      final local = await PlaybackResolver.localFor(
        musicId: hymn.id,
        instrumental: instrumental,
        offline: _offline,
      );
      String source;
      if (local != null) {
        source = local;
      } else {
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
        source = DownloadUrlBuilder.build(relativeUrl);
        // Download sob demanda (ouvir = baixar): em Wi-Fi, o play remoto
        // dispara em background o cache da faixa com metadados. Falha
        // silenciosa — reprodução nunca depende disto.
        unawaited(
          StreamCacheService(offline: _offline).onRemotePlay(
            musicId: hymn.id,
            url: source,
            title: hymn.title ?? 'Hino #${hymn.id}',
            number: hymn.number?.toString(),
            albumId: widget.albumId,
            albumName: hymnCatalogProvider.albumNameById(widget.albumId),
          ),
        );
      }
      // Atualiza o ícone imediatamente no clique. O evento onPlay do browser
      // pode chegar após alguns frames, mas a intenção do usuário é inequívoca.
      if (mounted) setState(() => _playingHymnId = hymn.id);
      nowPlaying.start(
        hymnId: hymn.id,
        title: hymn.title ?? '',
        album: hymnCatalogProvider.albumNameById(widget.albumId) ?? '',
        albumId: widget.albumId,
      );
      await player.playUrl(source);
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

  /// Abre o player modo vídeo (slides sincronizados — paridade Electron).
  /// Busca o detail (lyric estruturado) e abre a tela cheia; o áudio
  /// inicia pela URL remota ou arquivo local (PlaybackResolver).
  // coverage:ignore-start
  Future<void> _openNowPlaying(Hymn hymn, {bool instrumental = false}) async {
    setState(() => _loadingMusicId = hymn.id);
    try {
      var detail = hymn;
      if (hymn.lyricRaw == null) {
        detail = await _repository().getHymnDetails(hymn.id);
      }

      // Fonte de áudio: local baixada > URL remota.
      final local = await PlaybackResolver.localFor(
        musicId: hymn.id,
        instrumental: instrumental,
        offline: _offline,
      );
      final relativeUrl =
          instrumental ? detail.urlInstrumental : detail.urlMusic;
      if (local == null && (relativeUrl == null || relativeUrl.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('errors.notFound'.tr())));
        }
        return;
      }
      final source = local ?? DownloadUrlBuilder.build(relativeUrl!);

      nowPlaying.start(
        hymnId: hymn.id,
        title: hymn.title ?? '',
        album: hymnCatalogProvider.albumNameById(widget.albumId) ?? '',
        albumId: widget.albumId,
      );
      await _player.playUrl(source);

      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NowPlayingPage(
          detail: detail,
          instrumental: instrumental,
          player: HymnPlayerAdapter(_player),
          filesUrl: 'https://api.louvorja.com.br/file',
          audioSource: source, // F3.2: roteamento de áudio no Palco
          audioIsLocal: local != null,
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('errors.connection'.tr())));
      }
    } finally {
      if (mounted) setState(() => _loadingMusicId = null);
    }
  }
  // coverage:ignore-end

    OfflineMusicPort get _offline =>
        widget.offlineService ?? createOfflineMusicService();

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
        await _offline.download(
          musicId: hymn.id,
          url: DownloadUrlBuilder.build(url),
        );
        final OfflineMusicPort offline = _offline;
        if (offline is OfflineLibraryPort) {
          await (offline as OfflineLibraryPort).saveMetadata(
            musicId: hymn.id,
            title: hymn.title ?? 'Hino #${hymn.id}',
            number: hymn.number?.toString(),
            albumId: widget.albumId,
            albumName: hymnCatalogProvider.albumNameById(widget.albumId),
          );
        }
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

  DownloadQueue? _queue;

  /// Fila serial persistida: sobrevive ao fechamento do app (pendencias
  /// em disco) e mostra progresso por faixa (bytes recebidos/total).
  Future<void> _downloadAlbum(List<Hymn> hymns) async {
    if (!_offline.isSupported || _batchDownloading) return;
    final repo = _repository();
    final messenger = ScaffoldMessenger.of(context);
    final queue = _queue ??= DownloadQueue(
      offline: _offline,
      storage: createDownloadQueueStorage(),
    );

    setState(() {
      _batchDownloading = true;
    });

    // Resolve URLs primeiro (rate limit da API separado do download).
    final items = <DownloadQueueItem>[];
    for (final hymn in hymns) {
      if (_downloadedIds.contains(hymn.id)) continue;
      try {
        final detail = await repo.getHymnDetails(hymn.id);
        final url = detail.urlMusic ?? '';
        if (url.isNotEmpty) {
          items.add(DownloadQueueItem(
            musicId: hymn.id,
            title: hymn.title ?? '${hymn.id}',
            url: DownloadUrlBuilder.build(url),
          ));
        }
      } catch (_) {
        // detalhe falhou: item nao entra na fila agora (proximo lote)
      }
    }

    final total = items.length;
    queue.notifier.addListener(_onQueueProgress);
    queue.enqueue(items);
    await queue.done;
    final failed = queue.failedCount;
    queue.notifier.removeListener(_onQueueProgress);

    if (!mounted) return;
    // Reflete no UI o que a fila concluiu (consulta o indice offline real,
    // nao o estado em memoria da fila).
    final doneIds = <int>{};
    for (final item in items) {
      if (await _offline.localPathFor(item.musicId) != null) {
        doneIds.add(item.musicId);
      }
    }
    setState(() {
      _batchDownloading = false;
      _downloadedIds.addAll(doneIds);
      _batchTrackTitle = null;
      _batchTrackReceived = 0;
      _batchTrackTotal = 0;
    });
    if (failed > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('downloads.albumErrors'.tr(
              namedArgs: {'count': '$failed', 'total': '$total'}))),
      );
    }
  }

  void _onQueueProgress() {
    final p = _queue?.notifier.value;
    if (p == null || !mounted) return;
    setState(() {
      _batchTrackTitle = p.title;
      _batchTrackReceived = p.received;
      _batchTrackTotal = p.total;
    });
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
    _restoreDownloadedFlags();
  }

  /// Carrega do indice offline quais faixas deste album ja estao no disco.
  /// Nao confiar no estado em memoria: o usuario pode ter baixado em
  /// outra visita a pagina (ou noutra sessao do app).
  // coverage:ignore-start
  Future<void> _restoreDownloadedFlags() async {
    if (!_offline.isSupported) return;
    final future = _hymnsFuture;
    if (future == null) return;
    try {
      final hymns = await future;
      final downloaded = <int>{};
      for (final h in hymns) {
        if (await _offline.localPathFor(h.id) != null) {
          downloaded.add(h.id);
        }
      }
      if (mounted) setState(() => _downloadedIds.addAll(downloaded));
    } catch (_) {
      // indice offline inacessivel: mantem estado atual
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    _playingSubscription?.cancel();
    super.dispose();
  }

  /// Conectividade real consultada apenas para feedback do empty-state.
  // coverage:ignore-start
  Future<bool> _isOffline() async {
    try {
      return !(await ConnectivityService().isConnected);
    } catch (_) {
      return false; // sem veredito: assume online (nao mente offline)
    }
  }
  // coverage:ignore-end

  Future<List<Hymn>> _loadHymns() async {
    // Offline-first: SEM REDE e com downloads, a lista é a BIBLIOTECA
    // BAIXADA (tocável do disco). ONLINE mostra o catálogo completo —
    // baixadas e não baixadas (bug: filtro rodava também online e
    // escondia faixas não baixadas).
    // Timeout curto: em ambiente sem path_provider (test harness) o
    // índice pode pendurar; catálogo segue como fonte.
    try {
      final offlineNow = await _isOffline().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false, // sem veredito: assume online
      );
      if (offlineNow) {
        final localHymns = await OfflineLibraryFilter.hymnsForAlbum(
          albumId: widget.albumId,
          offline: _offline,
        ).timeout(const Duration(seconds: 2));
        if (localHymns != null && localHymns.isNotEmpty) return localHymns;
      }
    } catch (_) {
      // Índice offline inacessível: segue para as fontes de catálogo.
    }

    // Tenta ler o HymnsBloc da arvore (se HymnsPage proveu)
    try {
      if (!mounted) return const [];
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
          tooltip: 'common.back'.tr(),
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
          if (_batchDownloading)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_batchTrackTitle != null)
                      Text(
                        _batchTrackTitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      _batchTrackTotal > 0
                          ? '${(_batchTrackReceived / 1024 / 1024).toStringAsFixed(1)} / ${(_batchTrackTotal / 1024 / 1024).toStringAsFixed(1)} MB'
                          : 'downloads.downloading'.tr(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
            return FutureBuilder<bool>(
              future: _isOffline(),
              builder: (context, netSnap) {
                final offline = netSnap.data ?? false;
                // Feedback honesto: distingue coletanea vazia de problema
                // de rede/cache. Nunca renderiza 'vazio' silenciosamente.
                final message = offline
                    ? 'downloads.offlineEmpty'.tr()
                    : 'common.empty'.tr();
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        offline ? TablerIcons.wifiOff : TablerIcons.playlist,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4,
                        ),
                        child: Text(
                          message,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                                    // Modo vídeo (slides sincronizados)
                                    IconButton(
                                      tooltip: 'Modo vídeo',
                                      icon: const Icon(
                                        TablerIcons.slideshow,
                                        size: 20,
                                      ),
                                      onPressed: () => _openNowPlaying(hymn),
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
