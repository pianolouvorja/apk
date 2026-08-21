library;

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import 'palco_controller.dart';
import 'palco_sender.dart';
import '../dlna/stage_settings_repository.dart';
import '../dlna/stage_slide_painter.dart' show StageSettings;

/// Um slot de palco = 1 TV conectada via PalcoController.
///
/// Cada slot tem portas WS/HTTP próprias (incrementais), settings
/// independentes e estado de conexão próprio.
class PalcoSlot extends ChangeNotifier {
  PalcoSlot({required this.id, required this.label, required int slotIndex})
    : _slotIndex = slotIndex {
    controller = PalcoController(
      sender: PalcoSender(
        httpPortFixed: _baseHttpPort,
        wsPortFixed: _baseWsPort,
      ),
    );
    _settingsRepo = StageSettingsRepository(scope: id);
  }

  final String id;
  String label;
  final int _slotIndex;
  late final PalcoController controller;
  late final StageSettingsRepository _settingsRepo;

  /// Portas HTTP/WS calculadas a partir do índice do slot.
  /// Slot 0: 7080/7081, Slot 1: 7082/7083, etc.
  int get _baseHttpPort => 7080 + (_slotIndex * 2);
  int get _baseWsPort => 7081 + (_slotIndex * 2);
  int get httpPort => _baseHttpPort;
  int get wsPort => _baseWsPort;

  bool get isConnected => controller.isConnected;
  String? get receiverIp => controller.receiverIp;

  StageSettings settings = const StageSettings();

  /// Último conteúdo projetado neste slot (para refresh).
  _SlotContent? _lastContent;

  Future<bool> connect(PalcoTarget tv) async {
    settings = await _settingsRepo.load();
    final ok = await controller.connect(tv);
    if (ok) notifyListeners();
    return ok;
  }

  Future<void> disconnect() async {
    await controller.disconnect();
    _lastContent = null;
    notifyListeners();
  }

  Future<void> updateSettings(StageSettings s) async {
    settings = s;
    await _settingsRepo.save(s);
    notifyListeners();
  }

  void setLastContent(_SlotContent c) => _lastContent = c;
  _SlotContent? get lastContent => _lastContent;

  @override
  String toString() => 'PalcoSlot($id, $label, ports $httpPort/$wsPort)';
}

/// Conteúdo projetado num slot.
class _SlotContent {
  final String title;
  final String? body;
  final String? footer;
  final String module;
  final bool isBible;
  const _SlotContent({
    required this.title,
    this.body,
    this.footer,
    this.module = 'hymns',
    this.isBible = false,
  });
}
