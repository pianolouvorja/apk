library;

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/dlna/stage_session.dart';

/// F3.3w: botão "parar vídeo" — aparece no AppBar somente enquanto um vídeo
/// (item de vídeo da liturgia) está rodando no Palco. Um toque interrompe
/// e devolve a TV ao idle do palco.
class StageStopVideoButton extends StatelessWidget {
  const StageStopVideoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StageSession.instance,
      builder: (context, _) {
        if (!StageSession.instance.isVideoOnStage) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return IconButton(
          tooltip: 'Parar vídeo no Palco',
          icon: Icon(TablerIcons.playerStop,
              color: theme.colorScheme.error),
          onPressed: () {
            StageSession.instance.stopVideoOnStage();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Vídeo interrompido — Palco em idle'),
                  duration: Duration(seconds: 2)),
            );
          },
        );
      },
    );
  }
}
