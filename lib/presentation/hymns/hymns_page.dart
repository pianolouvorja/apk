library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'package:louvorja_piano_mobile/data/datasources/local/path_provider_web.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/datasources/remote/louvorja_api_impl.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'bloc/hymns_bloc.dart';

const _apiToken = String.fromEnvironment('API_TOKEN', defaultValue: '');

String _languageCode(BuildContext context) {
  try {
    return context.locale.languageCode;
  } catch (_) {
    // Testes/unitários ou host sem EasyLocalization.
    return 'pt';
  }
}

class HymnsPage extends StatefulWidget {
  final HymnsBloc? testBloc;

  const HymnsPage({super.key, this.testBloc});

  @override
  State<HymnsPage> createState() => _HymnsPageState();
}

class _HymnsPageState extends State<HymnsPage> {
  HymnsBloc? _bloc;
  String? _loadedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se um bloc de teste foi injetado, pula inicializacao assincrona.
    if (widget.testBloc != null) {
      _bloc ??= widget.testBloc;
      return;
    }
    final language = _languageCode(context);
    if (_loadedLanguage != language) {
      _loadedLanguage = language;
      _bloc?.close();
      _bloc = null;
      _initBloc(language);
    }
  }

  Future<void> _initBloc(String languagePrefix) async {
    final api = LouvorjaApiImpl(
      baseUrl: 'https://api.louvorja.com.br/json_db',
      filesUrl: 'https://api.louvorja.com.br/file',
      apiToken: _apiToken,
      languagePrefix: languagePrefix,
    );

    CatalogCache cache;
    if (kIsWeb) {
      // Web: nao tem dart:io; cache e no-op.
      cache = CatalogCache.noop();
    } else {
      // Mobile: cache em disco.
      final dir = await getApplicationDocumentsDirectory();
      cache = CatalogCache(dir);
    }

    final repo = HymnRepositoryImpl(api, cache);
    final bloc = HymnsBloc(repo);
    bloc.add(HymnsLoadRequested());
    if (mounted) setState(() => _bloc = bloc);
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bloc == null) {
      return Scaffold(
        appBar: AppBar(title: Text('hymns.title'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return BlocProvider<HymnsBloc>.value(
      value: _bloc!,
      child: const _HymnsView(),
    );
  }
}

class _HymnsView extends StatelessWidget {
  const _HymnsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('hymns.title'.tr())),
      body: BlocBuilder<HymnsBloc, HymnsState>(
        builder: (context, state) {
          if (state is HymnsLoading || state is HymnsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HymnsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.wifiOff, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      state.code.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    FilledButton.icon(
                      onPressed: () => context.read<HymnsBloc>().add(HymnsRefreshRequested()),
                      icon: const Icon(TablerIcons.refresh, size: 18),
                      label: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is HymnsLoaded) {
            final allAlbums = <Album>[];
            for (final cat in state.categories) {
              allAlbums.addAll(cat.albums);
            }
            if (allAlbums.isEmpty) {
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
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HymnsBloc>().add(HymnsRefreshRequested());
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s4),
                children: [
                  for (final cat in state.categories) ...[
                    if (cat.name != null && cat.albums.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s2),
                        child: Text(
                          cat.name!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    for (final album in cat.albums)
                      _AlbumCard(album: album),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = album.coverUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final fullCoverUrl = hasCover ? 'https://api.louvorja.com.br/file/$coverUrl' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/hymns/${album.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: fullCoverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: fullCoverUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _CoverPlaceholder(theme: theme),
                          errorWidget: (_, __, ___) => _CoverPlaceholder(theme: theme),
                        )
                      : _CoverPlaceholder(theme: theme),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name ?? 'Sem título',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (album.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          album.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  TablerIcons.chevronRight,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final ThemeData theme;

  const _CoverPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Icon(
        TablerIcons.music,
        size: 28,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
