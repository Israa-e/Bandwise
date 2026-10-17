import '../domain/writing.dart';
import '../domain/writing_feedback.dart';
import '../domain/writing_repository.dart';
import '../domain/writing_submission.dart';
import 'writing_content.dart';

/// Stand-in for the AI review until the backend exists.
///
/// It can only "review" a task's sample essay, for which it returns the
/// prepared [sampleFeedback]. Any other essay gets a [DemoResult]: the mock
/// never pretends to have analysed text it hasn't seen.
class MockWritingFeedbackService implements WritingFeedbackService {
  const MockWritingFeedbackService({
    this.delay = const Duration(milliseconds: 2500),
    this.simulateError = false,
    required this.now,
  });

  final Duration delay;

  /// Debug: fail every request, to show the error state.
  final bool simulateError;
  final DateTime Function() now;

  @override
  Future<WritingResult> evaluate({
    required WritingTask task,
    required String essay,
  }) async {
    await Future<void>.delayed(delay);
    if (simulateError) {
      throw const WritingFeedbackException('Simulated error');
    }
    final prepared = sampleFeedback[task.id];
    if (prepared == null ||
        normalizeEssay(essay) != normalizeEssay(task.sampleEssay)) {
      return const DemoResult();
    }
    final validation = validateFeedback(
      buildSampleFeedback(task, prepared, essay, now()),
      essay,
    );
    final feedback = validation.feedback;
    if (feedback == null) {
      throw WritingFeedbackException(validation.errors.join('; '));
    }
    return AnalysedResult(feedback, sample: true);
  }
}

/// [prepared] as [WritingFeedback] on [essay], with each note's offsets
/// found in the essay as submitted.
WritingFeedback buildSampleFeedback(
  WritingTask task,
  SampleFeedback prepared,
  String essay,
  DateTime createdAt,
) => WritingFeedback(
  taskType: task.type,
  overall: prepared.overall,
  criteria: prepared.criteria,
  topImprovements: prepared.topImprovements,
  annotations: [
    for (final n in prepared.notes)
      if (essay.indexOf(n.original) case final start when start >= 0)
        Annotation(
          id: n.id,
          type: n.type,
          criterionId: n.criterion.id,
          start: start,
          end: start + n.original.length,
          original: n.original,
          suggestion: n.suggestion,
          why: n.why,
        ),
  ],
  paragraphNotes: prepared.paragraphNotes,
  createdAt: createdAt,
);
