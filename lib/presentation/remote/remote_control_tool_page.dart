// coverage:ignore-file
// UI de controle remoto (ferramenta) — widget tree + sessão WS, sem teste unit
library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import 'package:louvorja_piano_mobile/app/theme/app_spacing.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_protocol.dart';
import 'package:louvorja_piano_mobile/core/services/remote/remote_session.dart';

/// Ferramenta "Controle Remoto": visível quando há sessão conectada.
/// Layout de controle remoto — liturgia espelhada + controles de mídia.
class RemoteControlToolPage extends StatefulWidget {
  const RemoteControlToolPage({super.key});

  @override
  State<RemoteControlToolPage> createState() => _RemoteControlToolPageState();
}

class _RemoteControlToolPageState extends State<RemoteControlToolPage> {
  StreamSubscription? _sub;
  RemotePlayerState? _state;

  @override
  void initState() {
    super.initState();
    _sub = RemoteSession.instance.states.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _send(RemoteAction action, {int? index}) async {
    await RemoteSession.instance.send(
      RemoteCommand(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        action: action,
        index: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final st = _state;
    final connected = RemoteSession.instance.mode == RemoteMode.desktop;

    return Scaffold(
      appBar: AppBar(
        title: Text('remote.title'.tr()),
        actions: [
          IconButton(
            tooltip: 'remote.disconnect'.tr(),
            icon: const Icon(TablerIcons.power),
            onPressed: () async {
              await RemoteSession.instance.disconnect();
              if (mounted) setState(() => _state = null);
            },
          ),
        ],
      ),
      body: !connected
          ? Center(child: Text('remote.connectFirst'.tr()))
          : st == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Liturgia espelhada — tap executa no desktop
                Expanded(
                  child: st.liturgyItems.isEmpty
                      ? Center(child: Text('remote.noLiturgy'.tr()))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                            vertical: AppSpacing.s2,
                          ),
                          itemCount: st.liturgyItems.length,
                          itemBuilder: (context, i) {
                            final item = st.liturgyItems[i];
                            final isSel = item.index == st.liturgySelectedIndex;
                            final isCat = item.type == 'category';
                            return ListTile(
                              key: Key('remote-liturgy-${item.index}'),
                              dense: !isCat,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: isCat
                                  ? const Icon(TablerIcons.folder, size: 20)
                                  : Icon(
                                      item.done
                                          ? TablerIcons.circleCheck
                                          : TablerIcons.circle,
                                      size: 18,
                                      color: isSel
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                              title: Text(
                                item.title ?? item.type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    (isCat
                                            ? theme.textTheme.titleSmall
                                            : theme.textTheme.bodyMedium)
                                        ?.copyWith(
                                          fontWeight: isSel || isCat
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                              ),
                              tileColor: isSel
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onTap: isCat
                                  ? null
                                  : () => _send(
                                      RemoteAction.liturgySelect,
                                      index: item.index,
                                    ),
                              onLongPress: () => _send(
                                RemoteAction.liturgyToggleDone,
                                index: item.index,
                              ),
                            );
                          },
                        ),
                ),
                // Controles de mídia — visual de controle remoto
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        if (st.title != null)
                          Text(
                            st.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                        const SizedBox(height: AppSpacing.s2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              tooltip: 'remote.previous'.tr(),
                              onPressed: st.canPrevious
                                  ? () => _send(RemoteAction.previous)
                                  : null,
                              icon: const Icon(TablerIcons.playerSkipBack),
                            ),
                            IconButton.filled(
                              iconSize: 36,
                              tooltip: st.playing
                                  ? 'remote.pause'.tr()
                                  : 'remote.play'.tr(),
                              onPressed: () => _send(
                                st.playing
                                    ? RemoteAction.pause
                                    : RemoteAction.play,
                              ),
                              icon: Icon(
                                st.playing
                                    ? TablerIcons.playerPause
                                    : TablerIcons.playerPlay,
                              ),
                            ),
                            IconButton(
                              tooltip: 'remote.next'.tr(),
                              onPressed: st.canNext
                                  ? () => _send(RemoteAction.next)
                                  : null,
                              icon: const Icon(TablerIcons.playerSkipForward),
                            ),
                            IconButton(
                              tooltip: 'remote.stop'.tr(),
                              onPressed: () => _send(RemoteAction.stop),
                              icon: const Icon(TablerIcons.playerStop),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Row(
                          children: [
                            const Icon(TablerIcons.volume, size: 18),
                            Expanded(
                              child: Slider(
                                value: (st.volume).clamp(0, 100).toDouble(),
                                max: 100,
                                onChanged: (v) => _send(
                                  RemoteAction.setVolume,
                                  // volume vai no value do command
                                ),
                                onChangeEnd: (v) =>
                                    _send(RemoteAction.setVolume),
                              ),
                            ),
                            const Icon(TablerIcons.volume2, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
