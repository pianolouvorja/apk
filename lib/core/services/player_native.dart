// coverage:ignore-file -- Platform channel, não testável em ambiente de teste.
/// Player nativo (Android/iOS) usando audioplayers.
library;

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import 'hymn_audio_player.dart';

HymnAudioPlayer createPlayerImpl() => _NativeAudioPlayer();

class _NativeAudioPlayer implements HymnAudioPlayer {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;
  bool _isPlaying = false;

  final _controller = StreamController<bool>.broadcast();

  _NativeAudioPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _controller.add(_isPlaying);
    });
  }

  @override
  String? get currentUrl => _currentUrl;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get playingStream => _controller.stream;

  @override
  Future<void> toggleUrl(String url) async {
    if (_currentUrl == url && _isPlaying) {
      await _player.pause();
      return;
    }
    await playUrl(url);
  }

  @override
  Future<void> playUrl(String url) async {
    _currentUrl = url;
    await _player.play(UrlSource(url));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.close();
  }
}
