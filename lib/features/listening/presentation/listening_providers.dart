import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_listening_repository.dart';
import '../data/just_audio_listening_audio.dart';
import '../domain/listening.dart';
import '../domain/listening_audio.dart';
import '../domain/listening_repository.dart';

final listeningRepositoryProvider = Provider<ListeningRepository>(
  (ref) => const AssetListeningRepository(),
);

final listeningSetsProvider = FutureProvider<List<ListeningSet>>(
  (ref) => ref.watch(listeningRepositoryProvider).fetchSets(),
);

/// Makes an audio player. Each screen that plays audio owns and disposes
/// its own. Overridden in tests.
final listeningAudioFactoryProvider = Provider<ListeningAudio Function()>(
  (ref) => JustAudioListeningAudio.new,
);
