library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/palco/palco_orchestrator.dart';

/// Seletor rapido de slot ativo na AppBar.
class SlotSelector extends StatelessWidget {
  const SlotSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final orch = PalcoOrchestrator.instance;
    if (orch.slots.length <= 1) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: orch,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final slot in orch.slots)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: slot.isConnected
                        ? Icon(
                            TablerIcons.deviceTv,
                            size: 16,
                            color: slot.id == orch.activeSlotId
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          )
                        : Icon(
                            TablerIcons.deviceTvOff,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    label: Text(
                      slot.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: slot.id == orch.activeSlotId
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: slot.id == orch.activeSlotId
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    onPressed: slot.isConnected
                        ? () => orch.setActiveSlot(slot.id)
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
