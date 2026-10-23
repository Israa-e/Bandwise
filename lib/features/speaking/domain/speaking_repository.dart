import 'speaking.dart';
import 'speaking_attempt.dart';

/// Source of speaking content.
abstract interface class SpeakingContentRepository {
  Future<SpeakingContent> fetchContent();
}

/// Finished attempts with their recordings, kept on this device only.
abstract interface class SpeakingAttemptRepository {
  /// Oldest first.
  Future<List<SpeakingAttempt>> loadAttempts();

  /// Adds [attempt], or replaces the one with its id.
  Future<void> saveAttempt(SpeakingAttempt attempt);

  /// Deletes every attempt.
  Future<void> clear();
}
