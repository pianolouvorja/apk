// coverage:ignore-file -- Usa dart:html, só executa em browser.
/// Player Web usando dart:html AudioElement.
library;
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';

import 'hymn_audio_player.dart';

HymnAudioPlayer createPlayerImpl() => _WebAudioPlayer();

class _WebAudioPlayer implements HymnAudioPlayer {
  AudioElement? _audio;
  String? _currentUrl;
  bool _isPlaying = false;

  final _controller = StreamController<bool>.broadcast();

  @override
  String? get currentUrl => _currentUrl;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playingStream => _controller.stream;

  void _ensure() {
    _audio ??= AudioElement()
      ..onPlay.listen((_) {
        _isPlaying = true;
        _controller.add(true);
      })
      ..onPause.listen((_) {
        _isPlaying = false;
        _controller.add(false);
      })
      ..onEnded.listen((_) {
        _isPlaying = false;
        _controller.add(false);
      })
      ..onError.listen((_) {
        _isPlaying = false;
        _controller.add(false);
      });
  }

  @override
  Future<void> toggleUrl(String url) async {
    _ensure();
    if (_currentUrl == url && _isPlaying) {
      _audio!.pause();
      return;
    }
    await playUrl(url);
  }

  @override
  Future<void> playUrl(String url) async {
    _ensure();
    _currentUrl = url;
    _audio!.src = url;
    try {
      _audio!.play();
    } catch (_) {
      // Browser pode bloquear autoplay; erro tratado silenciosamente.
    }
  }

  @override
  Future<void> pause() async {
    _ensure();
    _audio!.pause();
  }

  @override
  Future<void> stop() async {
    _ensure();
    _audio!.pause();
    _currentUrl = null;
  }

  @override
  void dispose() {
    _audio?.pause();
    _audio = null;
    _controller.close();
  }
}
