import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import 'speaking_providers.dart';

/// Saves a finished session: the attempt (recordings, notes, transcripts)
/// on this device, and its summary (times and automatic checks only) in
/// progress, with XP, minutes and a streak day. Returns the XP earned.
Future<int> saveSpeakingSession(WidgetRef ref, SpeakingAttempt attempt) async {
  await ref.read(speakingAttemptRepositoryProvider).saveAttempt(attempt);
  ref.invalidate(speakingAttemptsProvider);

  final today = ref.read(todayProvider);
  final progress = await ref.read(progressControllerProvider.future);
  final mode = switch (attempt.mode) {
    SpeakingMode.practice => 'practice',
    SpeakingMode.confidence => SpeakingSession.confidenceMode,
    SpeakingMode.timed => SpeakingSession.timedMode,
  };
  final xp = progress.speakingXpFor(
    mode: mode,
    date: today,
    questionIds: [for (final a in attempt.answers) a.questionId],
  );
  final elapsed = attempt.finishedAt.difference(attempt.startedAt);
  await ref
      .read(progressControllerProvider.notifier)
      .completeSpeaking(
        SpeakingSession(
          id: attempt.id,
          mode: mode,
          date: today,
          // Rounded up, at least 1, at most an hour.
          minutes: (elapsed.inSeconds / 60).ceil().clamp(1, 60),
          xp: xp,
          answers: [
            for (final a in attempt.answers)
              SpeakingAnswerSummary(
                questionId: a.questionId,
                part: a.part.index + 1,
                duration: a.duration,
                isLongTurn: a.isLongTurn,
                longSilences: a.silences.length,
                cutShort: a.cutShort != null,
              ),
          ],
        ),
      );
  return xp;
}
