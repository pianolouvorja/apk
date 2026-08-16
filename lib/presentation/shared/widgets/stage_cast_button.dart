library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/cast_controller.dart';
import '../../../core/services/dlna/ssdp_discovery.dart';
import '../../../core/services/dlna/stage_session.dart';
import '../../hymns/stage_customization_sheet.dart';

/// Botão Palco compartilhado: liga/desliga o cast global.
///
/// Ligado = TV no modo palco (background definido, aguardando conteúdo).
/// As telas projetam via StageSession.instance.project(...).
class StageCastButton extends StatefulWidget {
  const StageCastButton({super.key});

  @override
  State<StageCastButton> createState() => _StageCastButtonState();
}

class _StageCastButtonState extends State<StageCastButton> {
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    StageSession.instance.addListener(_onSession);
  }

  @override
  void dispose() {
    StageSession.instance.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  Future<void> _open() async {
    if (StageSession.instance.isOn) {
      await _openControls();
      return;
    }
    setState(() => _scanning = true);
    final tvs = await CastController.discoverTvs();
    if (!mounted) return;
    setState(() => _scanning = false);

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Palco — transmitir para TV',
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
              if (_scanning)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tvs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Nenhuma TV encontrada. Verifique a TV na mesma rede com DLNA ativo.'),
                )
              else
                for (final tv in tvs)
                  ListTile(
                    leading: const Icon(TablerIcons.deviceTv),
                    title: Text(tv.friendlyName ?? tv.ip),
                    subtitle: Text(
                        '${tv.ip} • ${tv.screenCapability.width}x${tv.screenCapability.height}'),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _connect(tv);
                    },
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connect(DlnaRenderer tv) async {
    final ok = await StageSession.instance.turnOn(tv);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível conectar à TV.')));
    }
  }

  /// Ligado: painel de controles do palco (personalizar/desligar).
  Future<void> _openControls() async {
    final session = StageSession.instance;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(TablerIcons.deviceTv,
                    color: theme.colorScheme.primary),
                title: const Text('Palco ativo'),
                subtitle: Text(session.rendererName ?? ''),
              ),
              ListTile(
                leading: const Icon(TablerIcons.photo),
                title: const Text('Imagem de fundo'),
                subtitle: const Text(
                    'Escolher da galeria (otimizada para a TV)'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 90);
                  if (picked != null) {
                    await session.setBackgroundFromFile(picked.path);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Fundo do palco atualizado.')));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(TablerIcons.adjustments),
                title: const Text('Personalizar'),
                subtitle: const Text('Cores, fonte, tamanho'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => StageCustomizationSheet(
                      initial: session.settings,
                      onApply: (s) => session.updateSettings(s),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(TablerIcons.castOff),
                title: const Text('Desligar palco'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await session.turnOff();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = StageSession.instance.isOn;
    return IconButton(
      tooltip: on ? 'Palco ativo' : 'Transmitir para TV',
      icon: _scanning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              on ? TablerIcons.cast : TablerIcons.castOff,
              color: on ? theme.colorScheme.primary : null,
            ),
      onPressed: _open,
    );
  }
}
