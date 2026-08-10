/// MainNavigation — bottom navigation com 5 tabs.
///
/// Fonte: pianolouvorja/app/src/shared/constants/navigation.ts
/// + pianolouvorja/app/src/design-system/components/navigation/DockFooter.vue
///
/// Tabs idênticas ao Electron (exceto Bíblia que é nova no mobile).
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

class MainNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigation({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
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
              label: 'Liturgia',
            ),
            NavigationDestination(
              icon: Icon(TablerIcons.book),
              selectedIcon: Icon(TablerIcons.book2),
              label: 'Bíblia',
            ),
            NavigationDestination(
              icon: Icon(TablerIcons.settings),
              label: 'Mais',
            ),
          ],
        ),
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
