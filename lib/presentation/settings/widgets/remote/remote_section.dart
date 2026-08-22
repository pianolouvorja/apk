library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_protocol.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_session.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Seção "Controle Remoto" das Configurações.
///
/// Dois fluxos (SPEC 2026-08-16-controle-remoto-apk):
/// - Desktop: operador digita IP:porta do Electron → APK conecta (cliente).
/// - Web: APK sobe servidor WS e mostra a URL `ws://…?t=…` para abrir no
///   navegador do desktop (browser não aceita conexão de entrada).
///
/// Conectado: controles do player do alvo (play/pause/prev/next/stop,
/// volume) espelhando o estado recebido em tempo real.
class RemoteSection extends StatefulWidget {
  const RemoteSection({super.key, this.session});

  /// Injetável para testes; default = singleton global.
  final RemoteSession? session;

  @override
  State<RemoteSection> createState() => _RemoteSectionState();
}

class _RemoteSectionState extends State<RemoteSection> {
  RemoteSession get _session => widget.session ?? RemoteSession.instance;

  final _hostCtrl = TextEditingController();
  var _hostValid = false;

  StreamSubscription? _statusSub;
  StreamSubscription? _statesSub;
  RemoteSessionStatus? _status;
  RemotePlayerState? _state;
  String? _webUrl;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl.addListener(_validateHost);
    _statusSub = _session.status.listen((s) {
      if (mounted) setState(() => _status = s);
    });
    _statesSub = _session.states.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  void _validateHost() {
    final raw = _hostCtrl.text.trim();
    // Aceita: IP (ex: 192.168.1.192) ou IP:porta (ex: 192.168.1.192:7070)
    final valid = RegExp(r'^\d{1,3}(\.\d{1,3}){3}(:\d{2,5})?$').hasMatch(raw);
    if (valid != _hostValid) setState(() => _hostValid = valid);
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _statesSub?.cancel();
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectDesktop() async {
    final parts = _hostCtrl.text.trim().split(':');
    final host = parts[0];
    final port = parts.length > 1 ? int.parse(parts[1]) : 7071;
    setState(() => _busy = true);
    final ok = await _session.connectDesktop(
      host: host,
      port: port,
      token: RemotePairing.generateToken(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar ao desktop.')),
      );
    }
  }

  Future<void> _startWebLink() async {
    setState(() => _busy = true);
    final url = await _session.startWebLink(
      token: RemotePairing.generateToken(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _webUrl = url;
    });
  }

  Future<void> _disconnect() async {
    await _session.disconnect();
    if (!mounted) return;
    setState(() {
      _webUrl = null;
      _state = null;
    });
  }

  Future<void> _send(RemoteAction action, {int? index}) async {
    await _session.send(
      RemoteCommand(id: _nonce(), action: action, index: index),
    );
  }

  String _nonce() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    return 'c$ts';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final connected =
        _session.mode != RemoteMode.idle &&
        (_status == RemoteSessionStatus.connected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(TablerIcons.cast, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'remote.title'.tr(),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('remote.subtitle'.tr(), style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        if (_session.mode == RemoteMode.idle) ...[
          TextField(
            key: const Key('remote-host'),
            controller: _hostCtrl,
            decoration: InputDecoration(
              labelText: 'remote.desktop_host'.tr(),
              hintText: 'remote.desktop_hint'.tr(),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.url,
            enabled: !_busy,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('remote-connect'),
                  onPressed: _hostValid && !_busy ? _connectDesktop : null,
                  icon: const Icon(TablerIcons.plugConnected),
                  label: Text('remote.connect'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('remote-weblink'),
                  onPressed: !_busy ? _startWebLink : null,
                  icon: const Icon(TablerIcons.world),
                  label: Text(
                    'remote.start_weblink'.tr(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          _buildActivePanel(theme, connected),
        ],
      ],
    );
  }

  Widget _buildActivePanel(ThemeData theme, bool connected) {
    final modeLabel = _session.mode == RemoteMode.desktop
        ? 'remote.mode_desktop'.tr()
        : 'remote.mode_web'.tr();
    final statusLabel = switch (_status) {
      RemoteSessionStatus.connected => 'remote.status_connected'.tr(),
      RemoteSessionStatus.connecting => 'remote.status_connecting'.tr(),
      RemoteSessionStatus.listening => 'remote.status_listening'.tr(),
      _ => 'remote.status_disconnected'.tr(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$modeLabel · $statusLabel',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: connected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              key: const Key('remote-disconnect'),
              tooltip: 'remote.disconnect'.tr(),
              onPressed: _disconnect,
              icon: const Icon(TablerIcons.plugConnectedX),
            ),
          ],
        ),
        if (_session.mode == RemoteMode.web &&
            _status == RemoteSessionStatus.listening &&
            _webUrl != null) ...[
          const SizedBox(height: 4),
          Text('remote.weblink_url'.tr(), style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          InkWell(
            key: const Key('remote-weblink-url'),
            onTap: () => Clipboard.setData(ClipboardData(text: _webUrl!)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _webUrl!.replaceFirst('ws://', ''),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('remote.weblink_waiting'.tr(), style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        _buildLiturgyMirror(theme),
        const SizedBox(height: 8),
        _buildPlayerControls(theme),
      ],
    );
  }

  /// Espelho da liturgia do desktop: mesma lista, tap = liturgy.select.
  Widget _buildLiturgyMirror(ThemeData theme) {
    final st = _state;
    final items = st?.liturgyItems ?? const <RemoteLiturgyItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final selected = st?.liturgySelectedIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'remote.liturgy'.tr(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) {
          final isSel = item.index == selected;
          return ListTile(
            key: Key('remote-liturgy-${item.index}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item.done ? TablerIcons.check : TablerIcons.circle,
              size: 18,
              color: isSel
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              item.title ?? item.type,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                color: item.done
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
            tileColor: isSel
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () => _send(RemoteAction.liturgySelect, index: item.index),
            onLongPress: () =>
                _send(RemoteAction.liturgyToggleDone, index: item.index),
          );
        }),
      ],
    );
  }

  Widget _buildPlayerControls(ThemeData theme) {
    final st = _state;
    if (st == null) {
      return Text(
        'remote.no_state'.tr(),
        key: const Key('remote-no-state'),
        style: theme.textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (st.title != null)
          Text(
            st.title!,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          '${_fmt(st.position)} / ${_fmt(st.duration)}'
          '${st.slideCount > 0 ? '  ·  ${st.slideIndex + 1}/${st.slideCount}' : ''}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              key: const Key('remote-cmd-previous'),
              tooltip: 'remote.previous'.tr(),
              onPressed: st.canPrevious
                  ? () => _send(RemoteAction.previous)
                  : null,
              icon: const Icon(TablerIcons.playerSkipBack),
            ),
            IconButton.filled(
              key: const Key('remote-cmd-toggle'),
              tooltip: st.playing ? 'remote.pause'.tr() : 'remote.play'.tr(),
              onPressed: () =>
                  _send(st.playing ? RemoteAction.pause : RemoteAction.play),
              icon: Icon(
                st.playing ? TablerIcons.playerPause : TablerIcons.playerPlay,
              ),
            ),
            IconButton(
              key: const Key('remote-cmd-next'),
              tooltip: 'remote.next'.tr(),
              onPressed: st.canNext ? () => _send(RemoteAction.next) : null,
              icon: const Icon(TablerIcons.playerSkipForward),
            ),
            IconButton(
              key: const Key('remote-cmd-stop'),
              tooltip: 'remote.stop'.tr(),
              onPressed: () => _send(RemoteAction.stop),
              icon: const Icon(TablerIcons.playerStop),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
