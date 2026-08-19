library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/slide_http_server.dart';
import '../../../core/services/dlna/stage_session.dart';
import '../../../core/services/palco/palco_controller.dart';
import 'palco_auto_connect_sheet.dart';
import '../../hymns/stage_customization_sheet.dart';

/// Botão Palco compartilhado: liga/desliga o cast global.
///
/// Ligado = TV no modo palco (background definido, aguardando conteúdo).
/// As telas projetam via StageSession.instance.project(...).
// F3.3q: botão LIMPAR na AppBar — só visível com palco ativo.
/// Ícone de borracha (distinto do cast/castOff), ao lado do StageCastButton.
class StageClearButton extends StatelessWidget {
  const StageClearButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StageSession.instance,
      builder: (context, _) {
        if (!StageSession.instance.isOn) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return IconButton(
          tooltip: 'Limpar projeção (voltar ao idle)',
          icon: Icon(TablerIcons.eraser, color: theme.colorScheme.error),
          onPressed: () => StageSession.instance.clearContent(),
        );
      },
    );
  }
}

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


  /// Salva IP do Palco para próxima vez.



  Future<void> _open() async {
    if (StageSession.instance.isOn) {
      await _openControls();
      return;
    }
    setState(() => _scanning = true);
    // F3.3ab: DLNA desativado — só Palco WS. IP local resolve async.
    await SlideHttpServer.resolveLocalIp();
    if (!mounted) return;
    setState(() => _scanning = false);

    // F3.3ae: conexão AUTO-FIRST — liga o sender, detecta a TV (DIAL) e
    // acompanha até o receiver conectar. Um toque só.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const PalcoAutoConnectSheet(),
    );
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
                // F3.3x: mostra nome + IP real da TV (via socket) quando
                // conectada; senão "aguardando a TV conectar".
                subtitle: ListenableBuilder(
                  listenable: session,
                  builder: (ctx2, _) {
                    final ip = session.receiverIp;
                    final name = session.rendererName ?? '';
                    return Text(
                      session.isPalcoMode && ip == null
                          ? '$name · aguardando a TV conectar…'
                          : ip != null ? '$name · TV $ip' : name,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: ip != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant),
                    );
                  },
                ),
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
                leading: Icon(TablerIcons.castOff,
                    color: theme.colorScheme.error, size: 28),
                title: Text('Limpar projeção',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600)),
                subtitle:
                    const Text('Volta ao idle SEM desligar o Palco'),
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
