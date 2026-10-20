import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/domain/learning_path.dart';
import '../../learn/presentation/learn_providers.dart';
import '../../reading/domain/reading.dart';
import '../../reading/presentation/reading_providers.dart';
import '../../review/domain/review_planner.dart';
import '../../review/presentation/review_providers.dart';
import '../../writing/domain/writing.dart';
import '../../writing/domain/writing_submission.dart';
import '../../writing/presentation/writing_providers.dart';
import '../domain/progress_state.dart';
import '../domain/skill_insights.dart';

/// Everything the Progress tab and its notebooks read, from the
/// repositories.
@immutable
class ProgressPageData {
  ProgressPageData({
    required this.path,
    required this.planner,
    required this.passages,
    required this.essays,
    required this.tasks,
  });

  /// The course with progress applied.
  final LearningPath path;

  /// Every review item, with its next review date.
  final ReviewPlanner planner;
  final List<ReadingPassage> passages;
  final List<WritingSubmission> essays;
  final List<WritingTask> tasks;

  ProgressState get progress => path.progress;

  late final reading = ReadingInsights.from(progress.readingAttempts);
  late final writing = WritingInsights.from(essays, tasks);

  /// Nothing done yet: no lessons, practice, reviews or essays.
  bool get isNew =>
      progress.activeDays.isEmpty &&
      progress.results.isEmpty &&
      progress.readingAttempts.isEmpty &&
      essays.isEmpty;
}

final progressPageProvider = FutureProvider<ProgressPageData>((ref) async {
  final path = await ref.watch(learningPathProvider.future);
  final planner = await ref.watch(reviewPlannerProvider.future);
  final passages = await ref.watch(readingPassagesProvider.future);
  final essays = await ref.watch(writingSubmissionsProvider.future);
  final tasks = await ref.watch(writingTasksProvider.future);
  return ProgressPageData(
    path: path,
    planner: planner,
    passages: passages,
    essays: essays,
    tasks: tasks,
  );
});
