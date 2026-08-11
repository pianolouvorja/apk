library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/hymn_repository.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/presentation/hymns/album_detail_page.dart';
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
    return detail ?? Hymn(id: musicId, title: 'Test', urlMusic: '/musics/test.mp3');
  }

  @override
  Future<List<AlbumCategory>> fetchCategories() async => [];
  @override
  Future<List<Hymn>> fetchHymnal() async => [];
  @override
  Future<List<Hymn>> fetchMusicIndex() async => [];
  @override
  String resolveMediaUrl(String relativePath) => 'https://example.com/$relativePath';
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
    final api = _MockApi(hymns: [
      const Hymn(id: 1, title: 'Hino A', number: 1),
      const Hymn(id: 2, title: 'Hino B', number: 2, hasInstrumental: true),
    ]);
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.text('Hino A'), findsOneWidget);
    expect(find.text('Hino B'), findsOneWidget);
  });

  testWidgets('AlbumDetailPage mostra empty state quando sem hinos', (tester) async {
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

  testWidgets('AlbumDetailPage mostra botao play e instrumental', (tester) async {
    final api = _MockApi(hymns: [
      const Hymn(id: 1, title: 'Hino X', number: 1, hasInstrumental: true),
    ]);
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    // Botao play
    expect(find.byIcon(TablerIcons.playerPlay), findsOneWidget);
    // Botao instrumental (piano)
    expect(find.byIcon(TablerIcons.piano), findsOneWidget);
  });

  testWidgets('AlbumDetailPage sem instrumental so mostra play', (tester) async {
    final api = _MockApi(hymns: [
      const Hymn(id: 1, title: 'Hino Y', number: 1, hasInstrumental: false),
    ]);
    final repo = HymnRepositoryImpl(api, CatalogCache.noop());
    final bloc = HymnsBloc(repo);

    await tester.pumpWidget(_wrap(bloc, const AlbumDetailPage(albumId: 100)));
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.playerPlay), findsOneWidget);
    expect(find.byIcon(TablerIcons.piano), findsNothing);
  });
}
