library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/stage_session.dart';
import '../../../core/services/palco/palco_controller.dart'
    show PalcoAudioRoute;

/// Settings → Palco: configurações GERAIS da sessão de cast.
///
/// RF-01 (spec palco-v2): rota de áudio mora AQUI (saiu do menu do caster).
/// RF-02: BG padrão geral — vale pra todos os módulos sem override.
///
/// Quando o palco está desligado, os controles ficam desabilitados com hint
/// (a sessão não existe sem TV conectada).
class StageSection extends StatefulWidget {
  const StageSection({super.key});

  @override
  State<StageSection> createState() => _StageSectionState();
}

class _StageSectionState extends State<StageSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = StageSession.instance;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final on = session.isOn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Áudio (RF-01) ---
            _SettingsCard(
              icon: TablerIcons.volume,
              title: 'Áudio do Palco',
              enabled: on,
              hint: on
                  ? null
                  : 'Conecte o Palco (ícone de cast) para configurar o áudio',
              child: SegmentedButton<PalcoAudioRoute>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PalcoAudioRoute.local,
                    label: Text('Celular'),
                  ),
                  ButtonSegment(value: PalcoAudioRoute.tv, label: Text('TV')),
                  ButtonSegment(
                    value: PalcoAudioRoute.mirror,
                    label: Text('Ambos'),
                  ),
                ],
                selected: {session.audioRoute},
                onSelectionChanged: on
                    ? (sel) {
                        session.audioRoute = sel.first;
                        // Re-roteia a faixa corrente com o modo novo.
                        session.rerouteCurrentAudio();
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // --- BG padrão geral (RF-02) ---
            _SettingsCard(
              icon: TablerIcons.photo,
              title: 'Imagem de fundo padrão',
              enabled: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vale para todos os módulos sem personalização própria',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(TablerIcons.upload),
                    label: const Text('Escolher da galeria'),
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 90,
                      );
                      if (picked == null) return;
                      await session.setBackgroundFromFile(picked.path);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('stage.backgroundUpdated'.tr()),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Card de setting — espelha o _SettingsCard da SettingsPage (mesma cara).
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool enabled;
  final String? hint;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
        color: theme.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
