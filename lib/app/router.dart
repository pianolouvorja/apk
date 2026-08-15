/// Configuracao de rotas com go_router.
///
/// 4 tabs: Inicio, Hinos, Ferramentas, Mais.
/// Usa StatefulShellRoute.indexedStack para preservar estado de cada tab.
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/global_search_service.dart';
import '../domain/entities/hymn.dart';
import '../presentation/home/home_page.dart';
import '../presentation/hymns/hymns_page.dart';
import '../presentation/hymns/album_detail_page.dart';
import '../presentation/search/global_search_page.dart';
import '../presentation/settings/settings_page.dart';
import '../presentation/shared/widgets/main_navigation.dart';
import '../presentation/tools/tools_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigation(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Inicio
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Tab 1: Hinos
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/hymns',
              builder: (context, state) => const HymnsPage(),
              routes: [
                GoRoute(
                  path: ':albumId',
                  builder: (context, state) => AlbumDetailPage(
                    albumId: int.tryParse(state.pathParameters['albumId'] ?? '') ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Ferramentas (Liturgia + Biblia)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tools',
              builder: (context, state) => const ToolsPage(),
            ),
          ],
        ),
        // Tab 3: Mais (Settings)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    // Busca global (RF-08): fora do shell para abrir em tela cheia.
    GoRoute(
      path: '/search',
      builder: (context, state) {
        return GlobalSearchPage(
          service: GlobalSearchService(),
          hymnsProvider: () async => <Hymn>[],
          versesProvider: () async => <BibleVerseRef>[],
        );
      },
    ),
  ],
);
