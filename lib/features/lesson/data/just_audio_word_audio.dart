import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../domain/word_audio.dart';

class JustAudioWordAudio implements WordAudioPlayer {
  final _player = AudioPlayer();
  String? _loaded;

  /// just_audio's play() completes when playback stops, so it isn't awaited.
  @override
  Future<void> play(String asset) async {
    if (_loaded != asset) {
      await _player.setAsset(asset);
      _loaded = asset;
    } else {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  @override
  Future<void> dispose() => _player.dispose();
}
