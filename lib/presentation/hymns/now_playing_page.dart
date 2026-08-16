library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../core/services/now_playing.dart';
import '../../core/services/dlna/cast_controller.dart';
import '../../core/services/dlna/ssdp_discovery.dart';
import '../../core/services/dlna/stage_slide_painter.dart';
import '../../core/services/dlna/stage_settings_repository.dart';
import 'stage_customization_sheet.dart';
import '../../domain/entities/hymn.dart';
import '../../domain/entities/lyric_slides.dart';
import '../shared/widgets/player_timeline.dart';

/// Tela "Now Playing" — o player modo vídeo do pianolouvorja/app.
///
/// Como no Electron (FullscreenPlayer.vue + Media.js):
/// - fundo = url_image do slide atual (carry-over incluído)
/// - texto da estrofe centralizado
/// - slides trocam SOZINHOS no tempo do áudio (times[] do modo)
/// - toque/seta = goToSlide → seek do áudio (bidirecional)
/// - modos: cantado / instrumental (se houver) / sem áudio
class NowPlayingPage extends StatefulWidget {
  final Hymn detail;
  final bool instrumental;
  final HymnPlayerLike player;
  final String filesUrl;
  final VoidCallback? onClose;

  const NowPlayingPage({
    super.key,
    required this.detail,
    required this.instrumental,
    required this.player,
    required this.filesUrl,
    this.onClose,
  });

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  late LyricSlides _slides;
  int _index = 0;
  bool _noAudio = false;
  StreamSubscription<Duration>? _posSub;

  // Palco (cast DLNA)
  final CastController _cast = CastController();
  List<DlnaRenderer> _tvs = [];
  bool _scanning = false;
  bool _casting = false;
  StageSettings _stageSettings = const StageSettings();
  final StageSettingsRepository _stageRepo = StageSettingsRepository();

  @override
  void initState() {
    super.initState();
    _slides = LyricSlides.fromApi(
      musicName: widget.detail.title ?? '',
      coverUrl: widget.detail.imageUrl,
      raw: widget.detail.lyricRaw ?? const [],
    );
    _stageRepo.load().then((s) {
      if (mounted) setState(() => _stageSettings = s);
    });
    _posSub = widget.player.positionStream.listen((pos) {
      if (!mounted || _noAudio) return;
      final idx = _slides.indexAt(pos, instrumental: widget.instrumental);
      if (idx != _index) {
        setState(() => _index = idx);
        _projectCurrentSlide();
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _cast.disconnect();
    super.dispose();
  }

  // ===== Palco (cast DLNA) =====

  Future<void> _scanTvs() async {
    setState(() => _scanning = true);
    final tvs = await CastController.discoverTvs();
    if (mounted) setState(() { _tvs = tvs; _scanning = false; });
  }

  Future<void> _openTvPicker() async {
    await _scanTvs();
    if (!mounted) return;
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
                      child: Text('Transmitir para TV',
                          style: theme.textTheme.titleMedium),
                    ),
                    IconButton(
                      tooltip: 'Personalizar Palco',
                      icon: const Icon(TablerIcons.adjustments),
                      onPressed: () => _openStageCustomization(ctx),
                    ),
                  ],
                ),
              ),
              if (_scanning)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_tvs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Nenhuma TV encontrada. Verifique se a TV está na mesma rede e com DLNA ativo (Configurações → Rede).'),
                )
              else
                for (final tv in _tvs)
                  ListTile(
                    leading: const Icon(TablerIcons.deviceTv),
                    title: Text(tv.friendlyName ?? tv.ip),
                    subtitle: Text(
                        '${tv.ip} • ${tv.screenCapability.width}x${tv.screenCapability.height}'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _connectCast(tv);
                    },
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStageCustomization(BuildContext ctx) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => StageCustomizationSheet(
        initial: _stageSettings,
        onApply: (s) {
          setState(() => _stageSettings = s);
          _projectCurrentSlide(); // re-projeta com novo visual imediatamente
        },
      ),
    );
  }

  Future<void> _connectCast(DlnaRenderer tv) async {
    final ok = await _cast.connect(tv);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível conectar à TV.')));
      return;
    }
    setState(() {
      _casting = true;
      _stageSettings = _stageSettings.copyWith(capability: tv.screenCapability);
    });
    await _projectCurrentSlide();
  }

  /// Renderiza o SLIDE DE PALCO (1920x1080 dedicado, tipografia TV)
  /// e projeta. Não é captura de tela do celular — fix do texto pequeno.
  Future<void> _projectCurrentSlide() async {
    if (!_casting) return;
    final slide = _slides.slides.isEmpty ? null : _slides.slides[_index];
    if (slide == null) return;
    try {
      final bytes = await StageSlidePainter.render(
        slide: slide,
        settings: _stageSettings,
        backgroundUrl: slide.imageUrl,
      );
      final ok = await _cast.projectSlide(
        bytes,
        title: widget.detail.title ?? 'Slide',
      );
      if (!ok && mounted) {
        setState(() => _casting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('TV desconectou — projeção interrompida.')));
      }
    } catch (_) {/* falha de render: próxima troca tenta de novo */}
  }

  Future<void> _disconnectCast() async {
    await _cast.disconnect();
    if (mounted) setState(() => _casting = false);
  }

  void _goToSlide(int index) {
    if (index < 0 || index >= _slides.slides.length) return;
    setState(() => _index = index);
    _projectCurrentSlide();
    if (!_noAudio) {
      final t = widget.instrumental
          ? _slides.slides[index].instrumentalTime
          : _slides.slides[index].time;
      if (t != null) widget.player.seek(t);
    }
  }

  String? get _bgUrl {
    final img = _slides.slides.isEmpty ? null : _slides.slides[_index].imageUrl;
    if (img == null || img.isEmpty) return null;
    return '${widget.filesUrl}/$img'.replaceAll('//images', '/images');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slide = _slides.slides.isEmpty ? null : _slides.slides[_index];
    final playing = widget.player.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo do slide
          if (_bgUrl != null)
            CachedNetworkImage(
              imageUrl: _bgUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(color: Colors.black54),

          // Conteúdo
          SafeArea(
            child: Column(
              children: [
                // Top bar: título + modos + fechar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(TablerIcons.x, color: Colors.white),
                      onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.detail.title ?? '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.detail.hasInstrumental)
                      IconButton(
                        tooltip: widget.instrumental ? 'Cantado' : 'Instrumental',
                        icon: Icon(
                          widget.instrumental ? TablerIcons.microphone : TablerIcons.piano,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() {
                          // Alterna modo local na exibição; reabrir troca fonte.
                        }),
                      ),
                    IconButton(
                      tooltip: _casting ? 'Parar transmissão' : 'Transmitir para TV',
                      icon: Icon(
                        _casting ? TablerIcons.castOff : TablerIcons.cast,
                        color: _casting ? theme.colorScheme.primary : Colors.white,
                      ),
                      onPressed: _casting ? _disconnectCast : _openTvPicker,
                    ),
                    IconButton(
                      tooltip: _noAudio ? 'Com áudio' : 'Sem áudio',
                      icon: Icon(
                        _noAudio ? TablerIcons.volume : TablerIcons.volumeOff,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _noAudio = !_noAudio),
                    ),
                  ],
                ),

                // Estrofe (área central): swipe troca slide
                Expanded(
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (d) {
                      if (d.primaryVelocity == null) return;
                      if (d.primaryVelocity! < 0) _goToSlide(_index + 1);
                      if (d.primaryVelocity! > 0) _goToSlide(_index - 1);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          slide?.text ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Indicador de slides (pontos)
                if (_slides.slides.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_index + 1} / ${_slides.slides.length}',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
                  ),

                // Player: timeline + play/pause + prev/next slide
                if (!_noAudio)
                  PlayerTimeline(
                    positionStream: widget.player.positionStream,
                    durationStream: widget.player.durationStream,
                    onSeek: widget.player.seek,
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(TablerIcons.chevronLeft, color: Colors.white),
                      onPressed: () => _goToSlide(_index - 1),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      iconSize: 56,
                      icon: Icon(
                        playing ? TablerIcons.playerPause : TablerIcons.playerPlay,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        if (widget.player.isPlaying) {
                          await widget.player.pause();
                        } else {
                          await widget.player.resume();
                        }
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(TablerIcons.chevronRight, color: Colors.white),
                      onPressed: () => _goToSlide(_index + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
