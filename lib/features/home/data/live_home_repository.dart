import '../../learn/domain/course.dart';
import '../../learn/domain/learning_path.dart';
import '../../review/domain/review_planner.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Home data from the learner's saved progress.
class LiveHomeRepository implements HomeRepository {
  const LiveHomeRepository({required this.path, required this.today});

  /// The course with progress applied.
  final Future<LearningPath> path;
  final DateTime today;

  @override
  Future<HomeSummary> fetchSummary() async {
    final path = await this.path;
    final progress = path.progress;
    final next = path.nextLesson;
    final due = ReviewPlanner(
      course: path.course,
      progress: progress,
    ).dueOn(today);
    return HomeSummary(
      // No accounts yet, so there is no name to greet.
      displayName: null,
      streakDays: progress.streak(today),
      totalXp: progress.totalXp,
      xpToday: progress.xpOn(today),
      minutesToday: progress.minutesOn(today),
      hasCompletedLessons: progress.results.isNotEmpty,
      nextLesson: next == null ? null : _nextLesson(path, next),
      mistakesDue: due.whereType<MistakeReviewItem>().length,
      wordsDue: due.whereType<WordReviewItem>().length,
      // Lessons don't practise the four skills yet.
      skills: const {},
      minutesByDay: progress.minutesByDay,
    );
  }

  static NextLesson _nextLesson(LearningPath path, Lesson lesson) {
    final unit = path.course.unit(lesson.unit);
    return NextLesson(
      id: lesson.id,
      unit: unit.number,
      unitTitle: unit.title,
      label: lesson.label,
      title: lesson.title,
      unitProgress: path.statsFor(unit).fraction,
      estimatedMinutes: lesson.estimatedMinutes,
    );
  }
}
