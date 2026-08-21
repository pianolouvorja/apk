library;

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/palco/palco_orchestrator.dart';
import '../../../core/services/palco/palco_controller.dart';

/// Sheet para gerenciar slots de palco: adicionar, remover.
class SlotManagementSheet extends StatefulWidget {
  const SlotManagementSheet({super.key});

  @override
  State<SlotManagementSheet> createState() => _SlotManagementSheetState();
}

class _SlotManagementSheetState extends State<SlotManagementSheet> {
  @override
  Widget build(BuildContext context) {
    final orch = PalcoOrchestrator.instance;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerenciar Telas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...orch.slots.map(
              (slot) => ListTile(
                leading: Icon(
                  slot.isConnected
                      ? TablerIcons.deviceTv
                      : TablerIcons.deviceTvOff,
                  color: slot.isConnected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(slot.label),
                subtitle: Text(
                  slot.isConnected
                      ? 'TV ${slot.receiverIp ?? ''}  :${slot.wsPort}'
                      : 'Desconectado  :${slot.wsPort}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: orch.slots.length > 1
                    ? IconButton(
                        icon: const Icon(TablerIcons.trash, size: 18),
                        onPressed: () async {
                          await orch.removeSlot(slot.id);
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            if (orch.slots.length < PalcoOrchestrator.maxSlots)
              FilledButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(TablerIcons.plus, size: 18),
                label: const Text('Adicionar tela'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final c = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova tela'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome (ex: Monitor Lateral)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = c.text.trim();
              if (name.isNotEmpty) {
                final id = name.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9]'),
                  '_',
                );
                PalcoOrchestrator.instance.addSlot(id: id, label: name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
