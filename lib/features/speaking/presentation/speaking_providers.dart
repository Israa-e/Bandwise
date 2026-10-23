import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_speaking_content_repository.dart';
import '../data/file_recording_store.dart';
import '../data/just_audio_speaking_audio.dart';
import '../data/mock_speaking_feedback_service.dart';
import '../data/prefs_speaking_attempt_repository.dart';
import '../data/record_speaking_recorder.dart';
import '../data/speech_to_text_transcriber.dart';
import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import '../domain/speaking_devices.dart';
import '../domain/speaking_feedback.dart';
import '../domain/speaking_repository.dart';

final speakingContentRepositoryProvider = Provider<SpeakingContentRepository>(
  (ref) => const AssetSpeakingContentRepository(),
);

final speakingContentProvider = FutureProvider<SpeakingContent>(
  (ref) => ref.watch(speakingContentRepositoryProvider).fetchContent(),
);

final speakingAttemptRepositoryProvider = Provider<SpeakingAttemptRepository>(
  (ref) => const PrefsSpeakingAttemptRepository(),
);

/// Attempts kept on this device, oldest first.
final speakingAttemptsProvider = FutureProvider<List<SpeakingAttempt>>(
  (ref) => ref.watch(speakingAttemptRepositoryProvider).loadAttempts(),
);

final recordingStoreProvider = Provider<RecordingStore>(
  (ref) => const FileRecordingStore(),
);

/// Each screen that records or plays makes and disposes its own.
/// Overridden in tests.
final speakingRecorderFactoryProvider = Provider<SpeakingRecorder Function()>(
  (ref) => RecordSpeakingRecorder.new,
);

final speakingAudioFactoryProvider = Provider<SpeakingAudio Function()>(
  (ref) => JustAudioSpeakingAudio.new,
);

final speechTranscriberFactoryProvider = Provider<SpeechTranscriber Function()>(
  (ref) => SpeechToTextTranscriber.new,
);

/// Demo only until AI review is connected; not used by any screen yet.
final speakingFeedbackServiceProvider = Provider<SpeakingFeedbackService>(
  (ref) => const MockSpeakingFeedbackService(),
);
