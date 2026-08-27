library;

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../core/services/now_playing.dart';
import '../../core/services/dlna/stage_session.dart';
import '../shared/widgets/stage_cast_button.dart';
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

  // Palco: sessão GLOBAL (StageSession) — o player projeta no mesmo
  // palco que Liturgia/Bíblia. Sem controller local (bug 2026-08-16:
  // cast do player era órfão e os slides nunca chegavam à TV).

  @override
  void initState() {
    super.initState();
    _slides = LyricSlides.fromApi(
      musicName: widget.detail.title ?? '',
      coverUrl: widget.detail.imageUrl,
      raw: widget.detail.lyricRaw ?? const [],
    );
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
    // Palco global NÃO é desconectado aqui: sessão persiste entre telas.
    super.dispose();
  }

  // ===== Palco: usar o botão compartilhado na AppBar (StageSession) =====

  /// Projeta o slide ATUAL do hino no palco global (se ligado).
  /// Mesma sessão da Liturgia/Bíblia — um palco só.
  Future<void> _projectCurrentSlide() async {
    final stage = StageSession.instance;
    if (!stage.isOn) return;
    final slide = _slides.slides.isEmpty ? null : _slides.slides[_index];
    if (slide == null) return;
    final ok = await stage.project(
      title: slide.text,
      footer: widget.detail.title,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('stage.disconnected'.tr())));
    }
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
                    const StageCastButton(),
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
