library;

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/services/palco/palco_discovery.dart';

/// Dialog de conexão Palco F3.4: lista receivers descobertos na sub-rede
/// (scan :7080/status) + campo de IP manual como alternativa avançada.
///
/// Retorna o IP escolhido (String) ou null se cancelado.
class PalcoConnectDialog extends StatefulWidget {
  const PalcoConnectDialog({super.key});

  @override
  State<PalcoConnectDialog> createState() => _PalcoConnectDialogState();
}

class _PalcoConnectDialogState extends State<PalcoConnectDialog> {
  final TextEditingController _ctrl = TextEditingController();
  List<String>? _found;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    final found = await PalcoDiscovery.scan();
    if (mounted) setState(() { _found = found; _scanning = false; });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Palco LouvorJA'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Procurando Palcos na rede…'),
                ],
              ),
            )
          else if (_found!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  'Nenhum Palco encontrado. Abra o app Palco na TV (ou um '
                  'browser em http://<ip-do-celular>:7080) e tente de novo, '
                  'ou use o IP manual abaixo.'),
            )
          else
            ..._found!.map((ip) => ListTile(
                  dense: true,
                  leading: const Icon(TablerIcons.deviceTv),
                  title: Text('Palco em $ip'),
                  onTap: () => Navigator.of(context).pop(ip),
                )),
          const Divider(height: 1),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                hintText: 'IP manual (ex: 192.168.1.12)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
            child: const Text('Conectar')),
      ],
    );
  }
}
