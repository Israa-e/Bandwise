import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../data/mock_writing_feedback_service.dart';
import '../data/prefs_writing_repository.dart';
import '../domain/writing.dart';
import '../domain/writing_repository.dart';
import '../domain/writing_submission.dart';

final writingTaskRepositoryProvider = Provider<WritingTaskRepository>(
  (ref) => const MockWritingTaskRepository(),
);

final writingTasksProvider = FutureProvider<List<WritingTask>>(
  (ref) => ref.watch(writingTaskRepositoryProvider).fetchTasks(),
);

final writingRepositoryProvider = Provider<WritingRepository>(
  (ref) => const PrefsWritingRepository(),
);

/// Debug switches for the mock feedback.
final writingDebugProvider = NotifierProvider<WritingDebugController, bool>(
  WritingDebugController.new,
);

/// Whether the mock feedback service fails every request.
class WritingDebugController extends Notifier<bool> {
  @override
  bool build() => false;

  void setSimulateError(bool value) => state = value;
}

final writingFeedbackServiceProvider = Provider<WritingFeedbackService>(
  (ref) => MockWritingFeedbackService(
    simulateError: ref.watch(writingDebugProvider),
    now: ref.watch(clockProvider),
  ),
);

final writingDraftsProvider =
    AsyncNotifierProvider<WritingDraftsController, Map<String, WritingDraft>>(
      WritingDraftsController.new,
    );

/// Saved drafts by [WritingDraft.id].
class WritingDraftsController extends AsyncNotifier<Map<String, WritingDraft>> {
  WritingRepository get _repository => ref.read(writingRepositoryProvider);

  @override
  Future<Map<String, WritingDraft>> build() => _repository.loadDrafts();

  Future<void> save(WritingDraft draft) async {
    // A save scheduled as the app closes may arrive after disposal.
    if (!ref.mounted) return;
    final current = state.value ?? await future;
    state = AsyncData({...current, draft.id: draft});
    await _repository.saveDraft(draft);
  }

  Future<void> delete(String id) async {
    if (!ref.mounted) return;
    final current = state.value ?? await future;
    state = AsyncData({...current}..remove(id));
    await _repository.deleteDraft(id);
  }
}

final writingSubmissionsProvider =
    AsyncNotifierProvider<
      WritingSubmissionsController,
      List<WritingSubmission>
    >(WritingSubmissionsController.new);

/// Submitted essays, oldest first.
class WritingSubmissionsController
    extends AsyncNotifier<List<WritingSubmission>> {
  WritingRepository get _repository => ref.read(writingRepositoryProvider);

  @override
  Future<List<WritingSubmission>> build() => _repository.loadSubmissions();

  Future<void> save(WritingSubmission submission) async {
    final current = state.value ?? await future;
    final i = current.indexWhere((s) => s.id == submission.id);
    state = AsyncData(
      i < 0
          ? [...current, submission]
          : [...current.take(i), submission, ...current.skip(i + 1)],
    );
    await _repository.saveSubmission(submission);
  }
}

/// Feedback for a submission: the saved result, or a new review that is
/// saved as soon as it arrives. Invalidate to retry after an error.
final writingResultProvider = FutureProvider.autoDispose
    .family<WritingResult, String>((ref, submissionId) async {
      final submissions = await ref.read(writingSubmissionsProvider.future);
      final submission = submissions.firstWhere((s) => s.id == submissionId);
      final saved = submission.result;
      if (saved != null) return saved;
      final tasks = await ref.read(writingTasksProvider.future);
      final task = tasks.firstWhere((t) => t.id == submission.taskId);
      final result = await ref
          .read(writingFeedbackServiceProvider)
          .evaluate(task: task, essay: submission.text);
      await ref
          .read(writingSubmissionsProvider.notifier)
          .save(submission.withResult(result));
      return result;
    });
