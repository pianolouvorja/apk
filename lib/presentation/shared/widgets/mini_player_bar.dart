library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../../core/services/now_playing.dart';

/// Miniplayer fixo (issue #90): barra acima da nav com a faixa ativa.
///
/// Referencia visual: Player.vue location='footer' do Electron
/// (footer-player-bar): info a esquerda, controles play/pause + stop,
/// tap na barra retorna para a origem (tab Hinos).
///
/// Aparece apenas com faixa ativa; some ao parar.
class MiniPlayerBar extends StatefulWidget {
  final NowPlayingNotifier notifier;
  final HymnPlayerLike player;
  final VoidCallback? onOpenPlayer;

  const MiniPlayerBar({
    super.key,
    required this.notifier,
    required this.player,
    this.onOpenPlayer,
  });

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onChanged);
    widget.player.playingListenable.addListener(_onPlayerChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onChanged);
    widget.player.playingListenable.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onPlayerChanged() {
    // Espelha o player real (faixa terminou/pausou externamente).
    widget.notifier.setPlaying(widget.player.isPlaying);
  }

  Future<void> _toggle() async {
    if (widget.notifier.isPlaying) {
      await widget.player.pause();
      widget.notifier.pause();
    } else {
      await widget.player.resume();
      widget.notifier.setPlaying(true);
    }
  }

  Future<void> _stop() async {
    await widget.player.stop();
    widget.notifier.stop();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.notifier.track;
    if (track == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final playing = widget.notifier.isPlaying;

    return Material(
      elevation: 4,
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        key: const Key('miniplayer-tap-area'),
        onTap: widget.onOpenPlayer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(TablerIcons.music, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      track.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('miniplayer-toggle'),
                icon: Icon(
                  playing ? TablerIcons.playerPause : TablerIcons.playerPlay,
                ),
                color: theme.colorScheme.primary,
                onPressed: _toggle,
                tooltip: playing ? 'common.pause'.tr() : 'common.play'.tr(),
              ),
              IconButton(
                key: const Key('miniplayer-stop'),
                icon: const Icon(TablerIcons.playerStop),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: _stop,
                tooltip: 'common.stop'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
