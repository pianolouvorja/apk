// coverage:ignore-file
/// Interface do player de audio.
library;

import 'player_stub.dart'
    if (dart.library.html) 'player_web.dart'
    if (dart.library.io) 'player_native.dart';

abstract class HymnAudioPlayer {
  static final HymnAudioPlayer instance = createPlayer();

  String? get currentUrl;
  bool get isPlaying;

  Stream<bool> get playingStream;

  Future<void> toggleUrl(String url);
  Future<void> playUrl(String url);
  Future<void> pause();
  Future<void> stop();
  void dispose();
}

HymnAudioPlayer createPlayer() => createPlayerImpl();
