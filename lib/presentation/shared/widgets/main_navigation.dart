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
/// Tab ativa: icone + label na cor primary, sem fundo.
/// Tabs inativas: icone + label em cinza (onSurfaceVariant).
class MainNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigation({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = navigationShell.currentIndex;

    final tabs = const [
      _NavTab(icon: TablerIcons.home, selectedIcon: TablerIcons.homeFilled, label: 'Início'),
      _NavTab(icon: TablerIcons.playlist, selectedIcon: TablerIcons.playlistAdd, label: 'Hinos'),
      _NavTab(icon: TablerIcons.clipboardText, selectedIcon: TablerIcons.clipboardCheck, label: 'Liturgia'),
      _NavTab(icon: TablerIcons.book, selectedIcon: TablerIcons.book2, label: 'Bíblia'),
      _NavTab(icon: TablerIcons.settings, selectedIcon: TablerIcons.settingsFilled, label: 'Mais'),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isSelected = i == currentIndex;
                final color = isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(i),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            size: 24,
                            color: color,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
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

class _NavTab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
