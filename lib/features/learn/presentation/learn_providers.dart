import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/presentation/progress_controller.dart';
import '../data/mock_course_repository.dart';
import '../domain/course.dart';
import '../domain/course_repository.dart';
import '../domain/learning_path.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => const MockCourseRepository(),
);

final courseProvider = FutureProvider<Course>(
  (ref) => ref.watch(courseRepositoryProvider).fetchCourse(),
);

/// The course with the learner's progress and unlocking rules applied.
final learningPathProvider = FutureProvider<LearningPath>((ref) async {
  final course = await ref.watch(courseProvider.future);
  final progress = await ref.watch(progressControllerProvider.future);
  final start = await ref.watch(startingPointProvider.future);
  return LearningPath(
    course: course,
    progress: progress,
    startUnit: start.unit,
  );
});

/// The unit shown on the Learn tab; null means the recommended unit.
final selectedUnitProvider = NotifierProvider<SelectedUnitController, int?>(
  SelectedUnitController.new,
);

class SelectedUnitController extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int unit) => state = unit;
}
