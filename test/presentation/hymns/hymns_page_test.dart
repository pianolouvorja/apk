library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvorja_piano_mobile/domain/entities/album.dart';
import 'package:louvorja_piano_mobile/domain/entities/album_category.dart';
import 'package:louvorja_piano_mobile/domain/entities/hymn.dart';
import 'package:louvorja_piano_mobile/domain/repositories/louvorja_api_client.dart';
import 'package:louvorja_piano_mobile/data/datasources/local/catalog_cache.dart';
import 'package:louvorja_piano_mobile/data/repositories/hymn_repository_impl.dart';
import 'package:louvorja_piano_mobile/presentation/hymns/bloc/hymns_bloc.dart';
import 'package:louvorja_piano_mobile/presentation/hymns/hymns_page.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

class _MockApi implements LouvorjaApiClient {
  @override
  String languagePrefix = 'pt';

  final bool fail;
  final bool empty;

  _MockApi({this.fail = false, this.empty = false});

  @override
  Future<List<AlbumCategory>> fetchCategories() async {
    if (fail) throw Exception('network error');
    if (empty) return const [];
    return [
      AlbumCategory(id: 1, name: 'Test Cat', albums: [
        const Album(id: 10, name: 'Album X', subtitle: '2024'),
        const Album(id: 20, name: 'Album Y'),
      ]),
    ];
  }

  @override
  Future<List<Hymn>> fetchAlbumHymns(int albumId) async => const [];
  @override
  Future<Hymn> fetchMusic(int musicId) async => Hymn(id: musicId);
  @override
  Future<List<Hymn>> fetchHymnal() async => const [];
  @override
  Future<List<Hymn>> fetchMusicIndex() async => const [];
  @override
  String resolveMediaUrl(String relativePath) => '';
}

HymnsBloc _bloc({_MockApi? api}) {
  final repo = HymnRepositoryImpl(api ?? _MockApi(), CatalogCache.noop());
  return HymnsBloc(repo);
}

void main() {
  testWidgets('HymnsPage mostra loading inicial', (tester) async {
    final bloc = _bloc();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HymnsBloc>.value(
          value: bloc,
          child: const HymnsPage(),
        ),
      ),
    );
    // Antes de pumpAndSettle, deve mostrar loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HymnsPage mostra coletaneas apos carregar', (tester) async {
    final bloc = _bloc();
    bloc.add(HymnsLoadRequested());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HymnsBloc>.value(
          value: bloc,
          child: HymnsPage(testBloc: bloc),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Album X'), findsOneWidget);
    expect(find.text('Album Y'), findsOneWidget);
  });

  testWidgets('HymnsPage mostra erro quando API falha', (tester) async {
    final bloc = _bloc(api: _MockApi(fail: true));
    bloc.add(HymnsLoadRequested());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HymnsBloc>.value(
          value: bloc,
          child: HymnsPage(testBloc: bloc),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.wifiOff), findsOneWidget);
  });

  testWidgets('HymnsPage mostra empty state quando sem coletaneas', (tester) async {
    final bloc = _bloc(api: _MockApi(empty: true));
    bloc.add(HymnsLoadRequested());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HymnsBloc>.value(
          value: bloc,
          child: HymnsPage(testBloc: bloc),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(TablerIcons.playlist), findsOneWidget);
  });
}
