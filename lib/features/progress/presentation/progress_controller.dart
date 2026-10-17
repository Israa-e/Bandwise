import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs_progress_repository.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_state.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => PrefsProgressRepository(),
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

  /// Debug helper: forget all progress.
  Future<void> reset() async {
    await _repository.clear();
    state = const AsyncData(ProgressState());
  }
}
