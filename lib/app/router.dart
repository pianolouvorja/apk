/// Configuração de rotas com go_router.
///
/// 5 tabs: Início, Hinos, Liturgia, Bíblia, Mais.
/// Usa StatefulShellRoute.indexedStack para preservar estado de cada tab.
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/bible/bible_page.dart';
import '../presentation/home/home_page.dart';
import '../presentation/hymns/hymns_page.dart';
import '../presentation/liturgy/liturgy_page.dart';
import '../presentation/settings/settings_page.dart';
import '../presentation/shared/widgets/main_navigation.dart';

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
        // Tab 0: Início
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
            ),
          ],
        ),
        // Tab 2: Liturgia
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/liturgy',
              builder: (context, state) => const LiturgyPage(),
            ),
          ],
        ),
        // Tab 3: Bíblia
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bible',
              builder: (context, state) => const BiblePage(),
            ),
          ],
        ),
        // Tab 4: Mais (Settings)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
