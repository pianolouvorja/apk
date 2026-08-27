library;

import 'package:flutter/foundation.dart';

/// Interface minima do player para o miniplayer (facilita testes).
///
/// Timeline (paridade Player.vue): posição, duração e seek têm default
/// inofensivo — implementações que suportam sobrescrevem.
abstract class HymnPlayerLike {
  bool get isPlaying;
  ValueListenable<bool> get playingListenable;

  Stream<Duration> get positionStream => const Stream.empty();
  Stream<Duration> get durationStream => const Stream.empty();
  Future<void> seek(Duration position) async {}

  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

/// Faixa em execucao exibida pelo miniplayer.
@immutable
class NowPlayingTrack {
  final int hymnId;
  final String title;
  final String album;
  final int? albumId;

  const NowPlayingTrack({
    required this.hymnId,
    required this.title,
    required this.album,
    this.albumId,
  });
}

/// Estado global do que esta tocando agora.
///
/// AlbumDetailPage chama [start] ao dar play; MiniPlayerBar escuta.
/// [stop] limpa (barra some). [setPlaying] espelha o estado do player.
class NowPlayingNotifier extends ChangeNotifier {
  NowPlayingTrack? _track;
  bool _playing = false;

  NowPlayingTrack? get track => _track;
  bool get hasTrack => _track != null;
  bool get isPlaying => _playing;

  void start({
    required int hymnId,
    required String title,
    required String album,
    int? albumId,
  }) {
    _track = NowPlayingTrack(
      hymnId: hymnId,
      title: title,
      album: album,
      albumId: albumId,
    );
    _playing = true;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    if (_playing == playing) return;
    _playing = playing;
    notifyListeners();
  }

  void pause() => setPlaying(false);

  void stop() {
    _track = null;
    _playing = false;
    notifyListeners();
  }
}

/// Singleton global — o miniplayer na shell consome.
final nowPlaying = NowPlayingNotifier();
