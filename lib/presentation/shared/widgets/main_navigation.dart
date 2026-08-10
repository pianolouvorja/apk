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
/// Tab ativa mostra ícone destacado + label em negrito na cor primary.
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isSelected = i == currentIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicador: pílula com cor primary quando ativo
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            size: 24,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
