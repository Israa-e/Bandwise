import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../domain/listening_audio.dart';

class JustAudioListeningAudio implements ListeningAudio {
  final _player = AudioPlayer();

  @override
  Future<void> load(String asset) => _player.setAsset(asset);

  /// just_audio's play() completes when playback stops, so it isn't awaited.
  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Duration get position => _player.position;

  @override
  bool get playing =>
      _player.playing && _player.processingState != ProcessingState.completed;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<bool> get playingStream => _player.playerStateStream
      .map((s) => s.playing && s.processingState != ProcessingState.completed)
      .distinct();

  @override
  Stream<void> get completed => _player.processingStateStream.where(
    (s) => s == ProcessingState.completed,
  );

  @override
  Future<void> dispose() => _player.dispose();
}
