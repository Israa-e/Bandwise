/// Where a flashcard word's pronunciation is bundled. The file may not
/// exist: see [WordAudioPlayer] users, which hide the button then.
String wordAudioAsset(String word) =>
    'assets/audio/words/${word.trim().toLowerCase()}.mp3';

/// The folder the word recordings live in.
const wordAudioFolder = 'assets/audio/words/';

/// Plays a bundled word recording. Implemented with just_audio; faked in
/// tests.
abstract interface class WordAudioPlayer {
  /// Plays the asset from the start. Completes once playback has started.
  Future<void> play(String asset);

  Future<void> dispose();
}
