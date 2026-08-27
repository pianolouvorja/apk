library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Seção "Sincronização" das Configurações: exportar/importar `.louvorja`.
///
/// Handlers são injetáveis para teste (o file picker é channel — não
/// pertence ao widget test).
class SyncSection extends StatelessWidget {
  final Future<void> Function() onExport;
  final Future<void> Function() onImport;
  final bool busy;

  const SyncSection({
    super.key,
    required this.onExport,
    required this.onImport,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: TablerIcons.refresh,
          title: 'sync.sectionTitle'.tr(),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: TablerIcons.deviceMobile,
          title: 'sync.cardTitle'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sync.hint'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('sync-export'),
                      onPressed: busy ? null : () => onExport(),
                      icon: const Icon(TablerIcons.fileExport),
                      label: Text('sync.export'.tr()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('sync-import'),
                      onPressed: busy ? null : () => onImport(),
                      icon: const Icon(TablerIcons.fileImport),
                      label: Text('sync.import'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reutiliza os widgets visuais da página de configurações (mesma cara).
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
