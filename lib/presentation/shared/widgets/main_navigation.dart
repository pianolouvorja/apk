library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// MainNavigation — bottom navigation com 5 tabs.
///
/// Fonte: pianolouvorja/app/src/shared/constants/navigation.ts
/// + DockFooter.vue
///
/// Tabs: Início, Hinos, Liturgia, Bíblia, Mais.
/// Tab ativa mostra ícone + label destacados (mesmo comportamento do Electron).
class MainNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigation({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(TablerIcons.home),
            selectedIcon: Icon(TablerIcons.homeFilled),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.playlist),
            selectedIcon: Icon(TablerIcons.playlistAdd),
            label: 'Hinos',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.clipboardText),
            selectedIcon: Icon(TablerIcons.clipboardCheck),
            label: 'Liturgia',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.book),
            selectedIcon: Icon(TablerIcons.book2),
            label: 'Bíblia',
          ),
          NavigationDestination(
            icon: Icon(TablerIcons.settings),
            selectedIcon: Icon(TablerIcons.settingsFilled),
            label: 'Mais',
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
