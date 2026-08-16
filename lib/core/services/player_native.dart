// coverage:ignore-file
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
  final _positions = StreamController<Duration>.broadcast();
  final _durations = StreamController<Duration>.broadcast();

  _NativeAudioPlayer() {
    _player.onPositionChanged.listen((pos) => _positions.add(pos));
    _player.onDurationChanged.listen((dur) => _durations.add(dur));
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
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Stream<Duration> get durationStream => _durations.stream;

  @override
  Future<void> seek(Duration position) => _player.seek(position);

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
    // Offline-first: caminho local (arquivo baixado) usa DeviceFileSource;
    // URL http(s) mantem streaming.
    if (url.startsWith('http://') || url.startsWith('https://')) {
      await _player.play(UrlSource(url));
    } else {
      await _player.play(DeviceFileSource(url));
    }
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
