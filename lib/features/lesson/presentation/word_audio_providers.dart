import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/just_audio_word_audio.dart';
import '../domain/word_audio.dart';

/// The word recordings bundled with the app, as asset paths. Words without
/// a recording get no pronunciation button.
final wordAudioAssetsProvider = FutureProvider<Set<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return {
    for (final asset in manifest.listAssets())
      if (asset.startsWith(wordAudioFolder) && asset.endsWith('.mp3')) asset,
  };
});

/// Created the first time a word is played.
final wordAudioPlayerProvider = Provider<WordAudioPlayer>((ref) {
  final player = JustAudioWordAudio();
  ref.onDispose(player.dispose);
  return player;
});
