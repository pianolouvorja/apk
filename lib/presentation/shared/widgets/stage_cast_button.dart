library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/slide_http_server.dart';
import '../../../core/services/dlna/stage_session.dart';
import '../../../core/services/palco/palco_controller.dart';
import 'palco_connect_dialog.dart';
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

  /// Lê último IP do Palco salvo (SharedPreferences).
  Future<String?> _getLastPalcoIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('palco_last_ip');
  }

  /// Salva IP do Palco para próxima vez.
  Future<void> _saveLastPalcoIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('palco_last_ip', ip);
  }

  /// Conecta no receiver webOS pelo IP salvo.
  Future<void> _connectPalcoByIp(String ip) async {
    final ok = await StageSession.instance.turnOnPalco(PalcoTarget(
      name: 'Palco ($ip)',
      ip: ip,
    ));
    if (!mounted) return;
    if (ok) {
      await _saveLastPalcoIp(ip);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Palco conectado em $ip'
            : 'stage.connectFail'.tr() +
                (StageSession.instance.castLastError != null
                    ? '\n(${StageSession.instance.castLastError})'
                    : ''))));
  }

  /// F3.3t: liga o sender e mostra o IP do celular pra digitar na TV.
  /// O receiver é cliente — conecta sozinho; IP da TV não é necessário.
  Future<void> _connectPalcoManual(BuildContext context) async {
    final localIp = SlideHttpServer.localIp;
    if (localIp == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Descobrindo IP da rede… tente de novo em instantes')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PalcoConnectDialog(mobileIp: localIp),
    );
    if (confirmed != true) return;
    // Sender aceita qualquer receiver que conectar — target é só informativo.
    final ok = await StageSession.instance
        .turnOnPalco(PalcoTarget(name: 'Palco (aguardando TV)', ip: localIp));
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('stage.connectFail'.tr() +
              (StageSession.instance.castLastError != null
                  ? '\n(${StageSession.instance.castLastError})'
                  : ''))));
      return;
    }
    await _saveLastPalcoIp(localIp);
    // F3.3y: espera o receiver conectar; se não, detecta a TV na rede e
    // orienta abrir o Palco nela (webOS não permite launch remoto).
    final hint = await StageSession.instance.checkTvNeedsPalcoOpen();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(hint ?? 'Palco conectado — TV $localIp'),
        duration: Duration(seconds: hint != null ? 6 : 3)));
  }

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

    // F3.3r: bottom sheet de descoberta/conexão — separa DLNA (slides) de Palco WS (receiver).
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final localIp = SlideHttpServer.localIp ?? 'descobrindo...';
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('stage.title'.tr(),
                            style: theme.textTheme.titleMedium),
                      ),
                      if (_scanning)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                // IP do celular — ESSENCIAL pro Palco WS
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('stage.yourIp'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              localIp,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar IP',
                            icon: const Icon(TablerIcons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: localIp));
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('IP copiado: $localIp')),
                              );
                            },
                          ),
                        ],
                      ),
                      Text('stage.ipHint'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // F3.3ab: seção DLNA removida — Palco WS é o único transporte.
                // Seção 2: Palco LouvorJA (receiver webOS) — último IP salvo
                FutureBuilder<String?>(
                  future: _getLastPalcoIp(),
                  builder: (ctx, snap) {
                    final lastIp = snap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                          child: Text('stage.palcoSection'.tr(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary)),
                        ),
                        if (lastIp != null && lastIp.isNotEmpty)
                          ListTile(
                            leading: const Icon(TablerIcons.deviceTv,
                                color: Colors.green),
                            title: Text('Última TV: $lastIp'),
                            subtitle: const Text('Toque para reconectar'),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              await _connectPalcoByIp(lastIp);
                            },
                          ),
                        ListTile(
                          leading: const Icon(TablerIcons.cast),
                          title: Text('stage.palcoManual'.tr()),
                          subtitle: Text('stage.palcoManualHint'.tr()),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await _connectPalcoManual(context);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
