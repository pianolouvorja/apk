library;

import 'dart:async' show unawaited, StreamSubscription;
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

import 'dart:ui' as ui;

import 'ssdp_discovery.dart';
import 'cast_controller.dart';
import 'stage_slide_painter.dart';
import 'stage_settings_repository.dart';
import '../palco/palco_controller.dart';
import '../palco/palco_models.dart' show PalcoMessage;
import '../palco/pptx_slide_extractor.dart';
import '../palco/palco_foreground.dart';

/// Palco global: sessão de cast PERSISTENTE entre telas.
///
/// Quando ligado, a TV mostra o background/personalização definida e
/// AGUARDA conteúdo — qualquer módulo (liturgia, bíblia, player) projeta
/// nele via [project]. Desligar = desconecta da TV.
///
/// Transportes:
/// - DLNA (rasteriza PNG/JPEG + SOAP) — TVs genéricas.
/// - Palco WS (protocolo v2) — receiver LouvorJA (webOS): texto nativo,
///   áudio, vídeo, timer e controle por setas do remote.
class StageSession extends ChangeNotifier {
  StageSession._();
  static final StageSession instance = StageSession._();

  final CastController _cast = CastController();
  final StageSettingsRepository _settingsRepo = StageSettingsRepository();

  /// Transporte Palco WS (nulo = usando DLNA).
  PalcoController? _palco;
  bool get isPalcoMode => _palco != null;

  StageSettings settings = const StageSettings();
  DlnaRenderer? renderer;
  bool _busy = false;
  ui.Image? _backgroundImage;

  bool get isOn => _cast.isConnected || isPalcoMode;
  String? get rendererName => isPalcoMode ? _palco!.target?.name : _cast.rendererName;
  String? get castLastError => _cast.lastError;

  /// Liga o palco no modo Palco WS (receiver LouvorJA na TV).
  /// A TV conecta no sender do celular ao abrir o app dela.
  Future<bool> turnOnPalco(PalcoTarget tv) async {
    final p = PalcoController();
    final ok = await p.connect(tv);
    if (!ok) return false;
    _palco = p;
    renderer = null;
    // F3.3: foreground service — sobrevive a background (One UI mata rede).
    unawaited(PalcoForeground.start());
    // F3.3i: setas do controle da TV navegam a sequência de slides.
    _remoteKeySub?.cancel();
    _remoteKeySub = p.events.listen((m) {
      if (m.type == 'remote-key' && m.fields['key'] is String) {
        navigateSlides(m.fields['key'] as String);
      }
    });
    notifyListeners();
    return true;
  }

  StreamSubscription<PalcoMessage>? _remoteKeySub;

  /// Acesso ao transporte Palco (áudio, vídeo, timer, eventos).
  /// Nulo quando ligado via DLNA.
  PalcoController? get palco => _palco;

  // ===== Roteamento de áudio (F3.2) =====
  // local: só celular | tv: só TV (celular = controle) | mirror: ambos.
  PalcoAudioRoute _audioRoute = PalcoAudioRoute.local;
  PalcoAudioRoute get audioRoute => _audioRoute;

  /// Troca o modo e notifica ouvintes (UI re-roteia a faixa corrente).
  set audioRoute(PalcoAudioRoute v) {
    if (_audioRoute == v) return;
    _audioRoute = v;
    notifyListeners();
  }

  /// Faixa corrente roteada (para re-enviar ao trocar o modo em runtime).
  String? _currentAudioUrl;
  String? _currentAudioTitle;
  String? _currentAudioSubtitle;
  String? _currentAudioCover;

  bool get _routesToTv =>
      isPalcoMode && audioRoute != PalcoAudioRoute.local;

  /// Toca faixa no destino configurado. Retorna o modo efetivo
  /// (local quando palco desligado, independente da config).
  ///
  /// Fonte LOCAL (hino baixado, path /data/...) não é alcançável pela TV:
  /// os bytes são servidos via /media do sender e a URL substituída.
  PalcoAudioRoute playHymnAudio(String url,
      {String? title, String? subtitle, String? cover, Duration? position}) {
    _currentAudioUrl = url;
    _currentAudioTitle = title;
    _currentAudioSubtitle = subtitle;
    _currentAudioCover = cover;
    if (!_routesToTv) return PalcoAudioRoute.local;
    var playable = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (file.existsSync()) {
        final name = 'hymn_${file.uri.pathSegments.last}'
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        playable = _palco!.serveMedia(name, file.readAsBytesSync()) ?? url;
        debugPrint('[PALCO] midia local servida: $playable');
      } else {
        debugPrint('[PALCO] ERRO: fonte local inexistente roteada: $url');
      }
    }
    _palco!.playAudio(playable, title: title, subtitle: subtitle, cover: cover,
        position: position);
    return audioRoute;
  }

  /// Re-envia a faixa corrente com o modo novo (chamado ao trocar modo).
  void rerouteCurrentAudio() {
    if (_currentAudioUrl == null) return;
    if (!_routesToTv) {
      // voltou pra local: para na TV (player local segue por conta da UI)
      _palco?.stopAudio();
      return;
    }
    var url = _currentAudioUrl!;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (file.existsSync()) {
        final name = 'hymn_${file.uri.pathSegments.last}'
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        url = _palco!.serveMedia(name, file.readAsBytesSync()) ?? url;
        debugPrint('[PALCO] reroute: local served as $url');
      } else {
        debugPrint('[PALCO] reroute ERROR: local not found: $url');
      }
    }
    _palco!.playAudio(url,
        title: _currentAudioTitle,
        subtitle: _currentAudioSubtitle,
        cover: _currentAudioCover);
  }

  void pauseHymnAudio() {
    if (_routesToTv) _palco!.pauseAudio();
  }

  void stopHymnAudio() {
    if (_routesToTv) _palco!.stopAudio();
  }

  /// Seek espelhado (modo tv: a TV é o relógio; local/mirror: no-op
  /// porque o player local já é a fonte).
  void seekHymnAudio(Duration position) {
    if (audioRoute == PalcoAudioRoute.tv && isPalcoMode) {
      _palco!.seekAudio(position.inMilliseconds / 1000.0);
    }
  }

  /// Liga o palco: conecta na TV e projeta o IDLE (background definido).
  // ===== Apresentação de slides (PPTX/images) no Palco — F3.3i =====
  // Extraí as imagens do .pptx (ZIP ppt/media/*), serve via /media e
  // projeta como sequência. Setas do controle da TV navegam.
  List<String> _slideUrls = [];
  int _slideIndex = -1;

  /// Projeta o slide [index] da sequência carregada.
  void _projectSlide(int index) {
    if (index < 0 || index >= _slideUrls.length) return;
    _slideIndex = index;
    _palco?.project(
        text: '', footer: '', background: _slideUrls[index]);
  }

  /// Carrega e projeta a 1a imagem de slides extraídos de um .pptx.
  /// Retorna a quantidade de slides projetados (0 = nada extraído).
  int projectPptxSlides(String pptxPath) {
    final slides = PptxSlideExtractor.extract(pptxPath);
    if (slides.isEmpty || _palco == null) return 0;
    _slideUrls = slides
        .map((s) => _palco!.serveMedia(
            'slide_${s.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}',
            s.bytes))
        .whereType<String>()
        .toList();
    _projectSlide(0);
    return _slideUrls.length;
  }

  /// Navegação next/prev da sequência de slides (setas do controle).
  bool navigateSlides(String direction) {
    if (_slideUrls.isEmpty) return false;
    if (direction == 'next' && _slideIndex < _slideUrls.length - 1) {
      _projectSlide(_slideIndex + 1);
      return true;
    }
    if (direction == 'prev' && _slideIndex > 0) {
      _projectSlide(_slideIndex - 1);
      return true;
    }
    return false;
  }

  /// Encerra a apresentação de slides (volta ao idle).
  void stopSlides() {
    _slideUrls = [];
    _slideIndex = -1;
    _palco?.projectIdle();
  }

  /// Liga o palco: conecta na TV e projeta o IDLE (background definida).
  Future<bool> turnOn(DlnaRenderer tv) async {
    settings = await _settingsRepo.load();
    final ok = await _cast.connect(tv);
    if (!ok) return false;
    renderer = tv;
    settings = settings.copyWith(capability: tv.screenCapability);
    try {
      await _loadBackground();
      await _projectIdle();
    } catch (e, st) {
      debugPrint('[DLNA] turnOn(): falha em loadBackground/projectIdle: '
          '$e\n$st');
    }
    notifyListeners();
    return true;
  }

  Future<void> turnOff() async {
    if (_palco != null) {
      unawaited(PalcoForeground.stop());
      await _palco!.disconnect();
      _palco = null;
    } else {
      await _cast.disconnect();
    }
    renderer = null;
    _backgroundImage?.dispose();
    _backgroundImage = null;
    notifyListeners();
  }

  /// Carrega a imagem de fundo personalizada (persistida) em memória.
  Future<void> _loadBackground() async {
    final bytes = await _settingsRepo.loadBackgroundImage();
    if (bytes == null) {
      _backgroundImage = null;
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _backgroundImage?.dispose();
      _backgroundImage = frame.image;
    } catch (_) {
      _backgroundImage = null;
    }
  }

  /// Define nova imagem de fundo (path escolhido pelo usuário),
  /// persiste e re-projeta se ligado.
  Future<void> setBackgroundFromFile(String path) async {
    final saved = await _settingsRepo.saveBackgroundImage(path);
    if (saved == null) return;
    await _loadBackground();
    await refresh();
  }

  Future<void> updateSettings(StageSettings s) async {
    settings = s;
    await _settingsRepo.save(s);
    await refresh();
  }

  /// Re-projeta o que estiver em cena (ou idle).
  Future<void> refresh() async {
    if (!isOn) return;
    final current = _lastContent;
    if (current != null) {
      await _project(current);
    } else {
      await _projectIdle();
    }
  }

  // Conteúdo atual em cena (para refresh pós-mudança de visual).
  _StageContent? _lastContent;

  /// Projeta conteúdo no palco. Sobrescreve o anterior.
  Future<bool> project({
    required String title,
    String? body,
    String? footer,
    String? background,
  }) async {
    if (!isOn) return false;
    final content = _StageContent(title: title, body: body, footer: footer);
    _lastContent = content;
    if (isPalcoMode) {
      // Palco WS: texto nativo (body com \n vira <br> no receiver).
      final text = [title, body].whereType<String>().where((s) => s.isNotEmpty).join('<br><br>');
      _palco!.project(text: text, footer: footer ?? '', background: background);
      return true;
    }
    return _project(content);
  }

  /// Volta ao idle (background aguardando mídia).
  Future<void> clearContent() async {
    _lastContent = null;
    if (!isOn) return;
    if (isPalcoMode) {
      _palco!.projectIdle();
      return;
    }
    await _projectIdle();
  }

  Future<bool> _project(_StageContent c) async {
    if (_busy) return true; // projeção em andamento: mantém a última
    _busy = true;
    try {
      var bytes = await StageSlidePainter.renderGeneric(
        title: c.title,
        body: c.body,
        footer: c.footer,
        settings: settings,
        backgroundImage: _backgroundImage,
      );
      // Compatibilidade máxima: sinks sem PNG recebem JPEG (universal).
      if (_cast.imageFormat == StageImageFormat.jpeg) {
        bytes = _encodeJpeg(bytes);
      }
      return await _cast.projectSlide(bytes, title: c.title);
    } finally {
      _busy = false;
    }
  }

  /// PNG (RGBA do rasterizador) → JPEG (qualidade 90) via pacote image.
  static Uint8List _encodeJpeg(Uint8List pngBytes) {
    final img = image.decodePng(pngBytes);
    if (img == null) return pngBytes; // improvável: segue PNG
    return Uint8List.fromList(image.encodeJpg(img, quality: 90));
  }

  Future<void> _projectIdle() async {
    var bytes = await StageSlidePainter.renderGeneric(
      title: '',
      body: '',
      footer: 'stage.waiting'.tr(),
      settings: settings,
      backgroundImage: _backgroundImage,
    );
    if (_cast.imageFormat == StageImageFormat.jpeg) {
      bytes = _encodeJpeg(bytes);
    }
    await _cast.projectSlide(bytes, title: 'Palco');
  }
}

class _StageContent {
  final String title;
  final String? body;
  final String? footer;
  const _StageContent({required this.title, this.body, this.footer});
}
