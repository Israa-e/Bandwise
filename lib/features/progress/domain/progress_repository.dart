import 'progress_state.dart';

/// Where the learner's progress is stored.
abstract interface class ProgressRepository {
  Future<ProgressState> load();
  Future<void> save(ProgressState state);
  Future<void> clear();
}
