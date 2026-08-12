// ignore_for_file: unused_import, unused_element_parameter
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/bible_book.dart';
import 'package:louvorja_piano_mobile/domain/entities/bible_version.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/hymn_repository.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/presentation/hymns/album_detail_page.dart';
import 'package:louvorja_piano_mobile/core/services/hymn_audio_player.dart';
import 'package:louvorja_piano_mobile/presentation/hymns/bloc/hymns_bloc.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

class _MockApi implements LouvorjaApiClient {
  @override
  String languagePrefix = 'pt';

  final List<Hymn> hymns;
  final Hymn? detail;
  final bool fail;

  _MockApi({this.hymns = const [], this.detail, this.fail = false});

  @override
  Future<List<Hymn>> fetchAlbumHymns(int albumId) async {
    if (fail) throw Exception('network');
    return hymns;
  }

  @override
  Future<Hymn> fetchMusic(int musicId) async {
    if (fail) throw Exception('network');
    return detail ??
        Hymn(id: musicId, title: 'Test', urlMusic: '/musics/test.mp3');
  }

  @override
  Future<List<AlbumCategory>> fetchCategories() async => [];
  @override
  Future<List<Hymn>> fetchHymnal() async => [];
  @override
  Future<List<Hymn>> fetchHymnal1996() async => const [];
  @override
  Future<List<Hymn>> fetchMusicIndex() async => [];
  @override
  String resolveMediaUrl(String relativePath) =>
      'https://example.com/$relativePath';
  @override
  Future<List<BibleBook>> fetchBibleBooks() async => const [];
  @override
  Future<List<BibleVersion>> fetchBibleVersions() async => const [];
  @override
  Future<Map<String, String>> fetchBibleChapter(int v, int b, int c) async =>
      {};
}

class _FakePlayer implements HymnAudioPlayer {
  final _stream = StreamController<bool>.broadcast();
  bool paused = false;
  String? playedUrl;

  @override
  String? get currentUrl => playedUrl;
  @override
  bool get isPlaying => playedUrl != null && !paused;
  @override
  Stream<bool> get playingStream => _stream.stream;
  @override
  Future<void> pause() async {
    paused = true;
    _stream.add(false);
  }

  @override
  Future<void> playUrl(String url) async {
    playedUrl = url;
    paused = false;
    _stream.add(true);
  }

  @override
  Future<void> stop() async {
    paused = true;
    playedUrl = null;
    _stream.add(false);
  }

  @override
  Future<void> toggleUrl(String url) async =>
      isPlaying && playedUrl == url ? pause() : playUrl(url);
  @override
  void dispose() => _stream.close();
}

Widget _wrap(HymnsBloc bloc, Widget child) => MaterialApp(
  home: BlocProvider<HymnsBloc>.value(value: bloc, child: child),
);

void main() {
  testWidgets('AlbumDetailPage mostra loading', (tester) async {
    final repo = HymnRepositoryImpl(
      _MockApi(hymns: [const Hymn(id: 1, title: 'Hino 1')]),
      CatalogCache.noop(),
    );
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    // Antes do pumpAndSettle, deve ter loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AlbumDetailPage mostra lista de hinos', (tester) async {
    final api = _MockApi(
      hymns: [
        const Hymn(id: 1, title: 'Hino A', number: 1),
        const Hymn(id: 2, title: 'Hino B', number: 2, hasInstrumental: true),
      ],
    );
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Hino A'), findsOneWidget);
    expect(find.text('Hino B'), findsOneWidget);
  });

  testWidgets('AlbumDetailPage mostra empty state quando sem hinos', (
    tester,
  ) async {
    final repo = HymnRepositoryImpl(_MockApi(hymns: []), CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.playlist), findsOneWidget);
  });

  testWidgets('AlbumDetailPage mostra erro quando API falha', (tester) async {
    final repo = HymnRepositoryImpl(_MockApi(fail: true), CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.alertCircle), findsOneWidget);
  });

  testWidgets('AlbumDetailPage tem campo de busca', (tester) async {
    final api = _MockApi(hymns: [const Hymn(id: 1, title: 'Hino 1')]);
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.search), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('AlbumDetailPage mostra botao play e instrumental', (
    tester,
  ) async {
    final api = _MockApi(
      hymns: [
        const Hymn(id: 1, title: 'Hino X', number: 1, hasInstrumental: true),
      ],
    );
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    // Botao play
    expect(find.byIcon(TablerIcons.playerPlayFilled), findsOneWidget);
    // Botao instrumental (piano)
    expect(find.byIcon(TablerIcons.piano), findsOneWidget);
  });

  testWidgets('AlbumDetailPage sem instrumental so mostra play', (
    tester,
  ) async {
    final api = _MockApi(
      hymns: [
        const Hymn(id: 1, title: 'Sem Instrumental', hasInstrumental: false),
      ],
    );
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.playerPlayFilled), findsOneWidget);
    expect(find.byIcon(TablerIcons.piano), findsNothing);
  });

  testWidgets('play muda para pause e pause restaura play', (tester) async {
    final player = _FakePlayer();
    final api = _MockApi(
      hymns: [const Hymn(id: 1, title: 'Hino tocável', durationMs: 125000)],
      detail: const Hymn(id: 1, urlMusic: '/musics/test.mp3'),
    );
    final bloc = HymnsBloc(HymnRepositoryImpl(api, CatalogCache.noop()));

    await tester.pumpWidget(
      _wrap(bloc, AlbumDetailPage(albumId: 100, audioPlayer: player)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Reproduzir'));
    // Duas fronteiras async: fallback offline Web e detalhe remoto do hino.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(player.playedUrl, contains('/musics/test.mp3'));
    expect(find.byTooltip('Pausar'), findsOneWidget);
    expect(find.byIcon(TablerIcons.playerPauseFilled), findsOneWidget);

    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(player.paused, isTrue);
    expect(find.byTooltip('Reproduzir'), findsOneWidget);
  });

  testWidgets('tap no hino expande e recolhe a letra', (tester) async {
    final api = _MockApi(
      hymns: [
        const Hymn(
          id: 1,
          title: 'Hino com letra',
          lyric: 'Primeira linha\nSegunda linha',
        ),
      ],
    );
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Primeira linha\nSegunda linha'), findsNothing);
    await tester.tap(find.text('Hino com letra'));
    await tester.pump();
    expect(find.text('Primeira linha\nSegunda linha'), findsOneWidget);

    await tester.tap(find.text('Hino com letra'));
    await tester.pump();
    expect(find.text('Primeira linha\nSegunda linha'), findsNothing);
  });
}
