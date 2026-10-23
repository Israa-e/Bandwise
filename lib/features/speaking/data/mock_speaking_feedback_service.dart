import '../domain/speaking_attempt.dart';
import '../domain/speaking_feedback.dart';

/// Stand-in until AI review is connected through the backend. It never
/// pretends to have listened: every attempt gets [DemoSpeakingResult], with
/// no estimate.
class MockSpeakingFeedbackService implements SpeakingFeedbackService {
  const MockSpeakingFeedbackService();

  @override
  Future<SpeakingResult> evaluate(SpeakingAttempt attempt) async =>
      const DemoSpeakingResult();
}
