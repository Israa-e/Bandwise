/// Plays one set's recording. Implemented with just_audio in the app and
/// faked in tests.
abstract interface class ListeningAudio {
  /// Loads the bundled audio [asset]. Throws if it can't be loaded.
  Future<void> load(String asset);

  /// Completes when playback has started, not when it ends.
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  Duration get position;
  bool get playing;

  /// The current position, every few hundred milliseconds while playing
  /// and after each seek.
  Stream<Duration> get positionStream;

  /// Whether audio is playing, on every change.
  Stream<bool> get playingStream;

  /// Fires when the recording has played to the end.
  Stream<void> get completed;

  Future<void> dispose();
}
