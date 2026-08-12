library;

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Banner nao-intrusivo exibido no topo quando ha uma nova versao.
class UpdateBanner extends StatelessWidget {
  final String version;
  final int? apkSizeBytes;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const UpdateBanner({
    super.key,
    required this.version,
    this.apkSizeBytes,
    required this.onUpdate,
    required this.onDismiss,
  });

  String get _sizeLabel {
    final bytes = apkSizeBytes;
    if (bytes == null) {
      return '';
    }
    if (bytes >= 1048576) {
      return ' (${(bytes / 1048576).toStringAsFixed(1)} MB)';
    }
    if (bytes >= 1024) {
      return ' (${(bytes / 1024).round()} KB)';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              TablerIcons.refreshAlert,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nova versao $version$_sizeLabel disponivel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(onPressed: onUpdate, child: const Text('Atualizar')),
            IconButton(
              icon: const Icon(TablerIcons.x, size: 18),
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
