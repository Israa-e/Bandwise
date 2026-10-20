import 'writing.dart';
import 'writing_feedback.dart';
import 'writing_submission.dart';

/// Writing prompts.
abstract interface class WritingTaskRepository {
  Future<List<WritingTask>> fetchTasks();
}

/// Drafts and submitted essays.
abstract interface class WritingRepository {
  Future<Map<String, WritingDraft>> loadDrafts();
  Future<void> saveDraft(WritingDraft draft);
  Future<void> deleteDraft(String id);

  /// Oldest first.
  Future<List<WritingSubmission>> loadSubmissions();

  /// Adds [submission], or replaces the one with its id.
  Future<void> saveSubmission(WritingSubmission submission);

  /// Deletes every draft and submitted essay.
  Future<void> clear();
}

/// Thrown when feedback can't be produced; the essay stays saved.
class WritingFeedbackException implements Exception {
  const WritingFeedbackException(this.message);

  final String message;

  @override
  String toString() => 'WritingFeedbackException: $message';
}

/// Reviews essays. The real implementation will call a server function;
/// the app never calls an AI API directly.
abstract interface class WritingFeedbackService {
  /// Feedback on [essay], validated against it. Throws
  /// [WritingFeedbackException] when no feedback is available.
  Future<WritingResult> evaluate({
    required WritingTask task,
    required String essay,
  });
}

/// Advice that applies to any essay for [type].
GeneralWritingFeedback generalFeedbackFor(WritingTaskType type) =>
    switch (type) {
      WritingTaskType.task1 => const GeneralWritingFeedback(
        taskType: WritingTaskType.task1,
        criteriaTips: {
          WritingCriterion.taskAchievement:
              'Check that your overview names the main trends and that every '
              'figure you give matches the chart.',
          WritingCriterion.coherenceCohesion:
              'Group related information in each body paragraph, and use '
              'linking words only where they show a real connection.',
          WritingCriterion.lexicalResource:
              'Vary how you describe change (rose, climbed, fell, levelled '
              'off) and use precise words such as "proportion".',
          WritingCriterion.grammaticalRange:
              'Use past tenses for past data, and mix simple sentences with '
              'comparisons and relative clauses.',
        },
        checklist: [
          TopImprovement(
            title: 'Write a clear overview',
            detail:
                'Two sentences that sum up the main trends, without exact '
                'figures.',
          ),
          TopImprovement(
            title: 'Support with data',
            detail:
                'Pick the key figures and compare them; don\'t list every '
                'value.',
          ),
          TopImprovement(
            title: 'Proofread verb forms',
            detail: 'Check tense and subject–verb agreement in every sentence.',
          ),
        ],
      ),
      WritingTaskType.task2 => const GeneralWritingFeedback(
        taskType: WritingTaskType.task2,
        criteriaTips: {
          WritingCriterion.taskResponse:
              'Answer every part of the question, and state your opinion '
              'clearly in the introduction and the conclusion.',
          WritingCriterion.coherenceCohesion:
              'Give each body paragraph one main idea, with a topic sentence '
              'and support that follows from it.',
          WritingCriterion.lexicalResource:
              'Use topic words accurately and avoid repeating the words of '
              'the question.',
          WritingCriterion.grammaticalRange:
              'Use a mix of complex sentences, and check agreement and '
              'articles carefully.',
        },
        checklist: [
          TopImprovement(
            title: 'Discuss both views',
            detail:
                'Give each view its own paragraph with a reason and an '
                'example.',
          ),
          TopImprovement(
            title: 'Make your opinion clear',
            detail: 'Say what you think early on and keep to it.',
          ),
          TopImprovement(
            title: 'Develop your examples',
            detail: 'Explain how each example supports your point.',
          ),
        ],
      ),
    };
