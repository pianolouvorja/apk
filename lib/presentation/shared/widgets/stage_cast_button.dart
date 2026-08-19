library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/cast_controller.dart';
import '../../../core/services/dlna/ssdp_discovery.dart';
import '../../../core/services/dlna/stage_session.dart';
import '../../../core/services/palco/palco_controller.dart';
import 'palco_connect_dialog.dart';
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
                      child: Text('stage.title'.tr(),
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('stage.noTvs'.tr()),
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(TablerIcons.cast),
                title: const Text('Palco LouvorJA (app na TV)'),
                subtitle: const Text('Conectar por IP — receiver webOS'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _connectPalcoManual(context);
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
      final err = StageSession.instance.castLastError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('stage.connectFail'.tr() +
              (err != null ? '\n($err)' : ''))));
    }
  }

  /// Conexão manual Palco WS: pede o IP da TV (receiver já aberto nela).
  Future<void> _connectPalcoManual(BuildContext context) async {
    final ip = await showDialog<String>(
      context: context,
      builder: (ctx) => const PalcoConnectDialog(),
    );
    if (ip == null || ip.isEmpty) return;
    final ok = await StageSession.instance.turnOnPalco(PalcoTarget(
      name: 'Palco ($ip)',
      ip: ip,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Palco ativo — abra o app LouvorJA Palco na TV (ela conecta sozinha)'
            : 'Falha ao iniciar o sender Palco (rede/porta)')));
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
                title: Text('stage.active'.tr()),
                subtitle: Text(session.rendererName ?? ''),
              ),
              // F3.2: roteamento de áudio (só em modo Palco WS).
              if (session.isPalcoMode)
                StatefulBuilder(builder: (ctx2, setSheet) => ListTile(
                  leading: const Icon(TablerIcons.volume),
                  title: const Text('Áudio'),
                  subtitle: const Text(
                      'Celular · TV · Ambos'),
                  trailing: SegmentedButton<PalcoAudioRoute>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: PalcoAudioRoute.local, label: Text('Celular')),
                      ButtonSegment(
                          value: PalcoAudioRoute.tv, label: Text('TV')),
                      ButtonSegment(
                          value: PalcoAudioRoute.mirror, label: Text('Ambos')),
                    ],
                    selected: {session.audioRoute},
                    onSelectionChanged: (sel) {
                      setSheet(() => session.audioRoute = sel.first);
                      // F3.2: re-roteia a faixa corrente com o modo novo.
                      session.rerouteCurrentAudio();
                    },
                  ),
                )),
              ListTile(
                leading: const Icon(TablerIcons.photo),
                title: Text('stage.background'.tr()),
                subtitle: Text('stage.backgroundHint'.tr()),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 90);
                  if (picked != null) {
                    await session.setBackgroundFromFile(picked.path);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('stage.backgroundUpdated'.tr())));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(TablerIcons.adjustments),
                title: Text('stage.customize'.tr()),
                subtitle: Text('stage.customizeHint'.tr()),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    // A03 (tela pequena): sheet enorme passava da altura da
                    // tela — constraint evita overflow/fechamento brusco.
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    builder: (_) => StageCustomizationSheet(
                      initial: session.settings,
                      onApply: (s) => session.updateSettings(s),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(TablerIcons.castOff),
                title: Text('stage.turnOff'.tr()),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await session.turnOff();
                },
              ),
              // F3.3p: volta ao idle SEM desligar o palco — libera a tela
              // (ex: passagem projetada acabou) mantendo a sessão viva.
              ListTile(
                leading: const Icon(TablerIcons.screenShareOff),
                title: const Text('Limpar projeção'),
                subtitle: const Text('Volta ao idle sem desligar o Palco'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  session.clearContent();
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
      tooltip: on ? 'stage.castOn'.tr() : 'stage.castOff'.tr(),
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
