import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/presentation/learn_providers.dart';
import '../../progress/presentation/progress_controller.dart';
import '../../reading/presentation/reading_providers.dart';
import '../domain/review_planner.dart';

/// Makes the seed that shuffles answer options for one review session.
/// Overridden in tests for a predictable order.
final reviewShuffleSeedProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().microsecondsSinceEpoch,
);

/// Review items from the course, reading passages and the learner's progress. Rebuilt
/// whenever progress changes.
final reviewPlannerProvider = FutureProvider<ReviewPlanner>((ref) async {
  final course = await ref.watch(courseProvider.future);
  final progress = await ref.watch(progressControllerProvider.future);
  final passages = await ref.watch(readingPassagesProvider.future);
  return ReviewPlanner(course: course, progress: progress, passages: passages);
});
