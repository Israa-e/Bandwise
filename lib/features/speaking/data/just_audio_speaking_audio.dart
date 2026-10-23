import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/speaking_devices.dart';

class JustAudioSpeakingAudio implements SpeakingAudio {
  final _player = AudioPlayer();

  @override
  Future<void> loadAsset(String asset) => _player.setAsset(asset);

  @override
  Future<void> loadRecording(String path) =>
      kIsWeb ? _player.setUrl(path) : _player.setFilePath(path);

  /// just_audio's play() completes when playback stops, so it isn't awaited.
  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

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
