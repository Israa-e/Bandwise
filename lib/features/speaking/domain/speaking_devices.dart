/// Where microphone access stands.
enum MicPermission {
  granted,

  /// Not asked yet (or can be asked again): the system prompt will show.
  canAsk,

  /// Refused for good: only the phone's settings can allow it now.
  permanentlyDenied,
}

/// Records answers. Implemented with the record package (AAC in .m4a) and
/// permission_handler; faked in tests.
abstract interface class SpeakingRecorder {
  /// The current permission, without asking.
  Future<MicPermission> permission();

  /// Shows the system prompt (when it still can) and returns the outcome.
  Future<MicPermission> requestPermission();

  /// Opens this app's page in the phone's settings.
  Future<void> openSettings();

  /// Starts recording to [path] (see [RecordingStore.newPath]).
  Future<void> start(String path);

  /// Stops and returns where the recording is: [path], or on the web a
  /// blob URL. Null if nothing was recorded.
  Future<String?> stop();

  /// Stops and throws the recording away.
  Future<void> cancel();

  /// Loudness in dBFS (about -160 to 0), a few times a second while
  /// recording.
  Stream<double> get amplitude;

  Future<void> dispose();
}

/// Plays the examiner's questions (bundled assets) and the learner's
/// recordings. Implemented with just_audio; faked in tests.
abstract interface class SpeakingAudio {
  Future<void> loadAsset(String asset);

  /// A recording's path, or a blob URL on the web.
  Future<void> loadRecording(String path);

  /// Completes when playback has started, not when it ends.
  Future<void> play();
  Future<void> pause();

  Stream<bool> get playingStream;

  /// Fires when what was loaded has played to the end.
  Stream<void> get completed;

  Future<void> dispose();
}

/// Where recordings are kept: on this device only.
abstract interface class RecordingStore {
  /// A new place to record the answer to [questionId] in [attemptId].
  Future<String> newPath(String attemptId, String questionId);

  Future<void> delete(String path);

  /// Deletes every recording.
  Future<void> deleteAll();
}

/// The optional automatic transcript: the phone's speech recognition,
/// listening while the answer is recorded. Faked in tests.
abstract interface class SpeechTranscriber {
  /// Starts listening. False when recognition isn't available.
  Future<bool> start();

  /// Stops and returns what was recognised, if anything.
  Future<String?> stop();
}
