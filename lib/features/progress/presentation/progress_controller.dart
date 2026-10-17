import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/presentation/learn_providers.dart';
import '../data/prefs_progress_repository.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_state.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => PrefsProgressRepository(
    loadCourse: () => ref.read(courseProvider.future),
  ),
);

final progressControllerProvider =
    AsyncNotifierProvider<ProgressController, ProgressState>(
      ProgressController.new,
    );

/// The learner's saved progress. Every change is persisted.
class ProgressController extends AsyncNotifier<ProgressState> {
  ProgressRepository get _repository => ref.read(progressRepositoryProvider);

  @override
  Future<ProgressState> build() => _repository.load();

  Future<void> completeLesson(LessonCompletion completion) async {
    final current = state.value ?? await future;
    final next = current.withCompletedLesson(completion);
    state = AsyncData(next);
    await _repository.save(next);
  }

  Future<void> completeReading(ReadingCompletion completion) async {
    final current = state.value ?? await future;
    final next = current.withReadingAttempt(completion);
    state = AsyncData(next);
    await _repository.save(next);
  }

  /// Records one reviewed item as soon as it is rated, so leaving a review
  /// early keeps what was done. Returns the XP earned.
  Future<int> review(ReviewCompletion review) async {
    final current = state.value ?? await future;
    final xp = current.reviewXpFor(review.rating, review.date);
    final next = current.withReview(review);
    state = AsyncData(next);
    await _repository.save(next);
    return xp;
  }

  /// Debug helper: forget all progress.
  Future<void> reset() async {
    await _repository.clear();
    state = const AsyncData(ProgressState());
  }
}
