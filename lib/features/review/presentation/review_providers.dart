import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/presentation/learn_providers.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/review_planner.dart';

/// Review items from the course and the learner's progress. Rebuilt
/// whenever progress changes.
final reviewPlannerProvider = FutureProvider<ReviewPlanner>((ref) async {
  final course = await ref.watch(courseProvider.future);
  final progress = await ref.watch(progressControllerProvider.future);
  return ReviewPlanner(course: course, progress: progress);
});
