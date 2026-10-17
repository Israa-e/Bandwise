import '../../../core/models/skill.dart';
import '../../../core/utils/dates.dart';
import '../../learn/domain/course.dart';
import '../../learn/domain/learning_path.dart';
import '../../progress/domain/progress_state.dart';
import '../../reading/domain/reading.dart';
import '../../review/domain/review_planner.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Home data from the learner's saved progress.
class LiveHomeRepository implements HomeRepository {
  const LiveHomeRepository({
    required this.path,
    required this.passages,
    required this.today,
  });

  /// The course with progress applied.
  final Future<LearningPath> path;

  /// Reading passages, for reading mistakes due for review.
  final Future<List<ReadingPassage>> passages;
  final DateTime today;

  @override
  Future<HomeSummary> fetchSummary() async {
    final path = await this.path;
    final progress = path.progress;
    final next = path.nextLesson;
    final due = ReviewPlanner(
      course: path.course,
      progress: progress,
      passages: await passages,
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
      mistakesDue: due.where((i) => i.isMistake).length,
      wordsDue: due.whereType<WordReviewItem>().length,
      // Only Reading has practice so far.
      skills: {
        if (progress.readingAttempts.isNotEmpty)
          Skill.reading: readingActivity(progress.readingAttempts, today),
      },
      minutesByDay: progress.minutesByDay,
    );
  }

  /// Reading practice as Home shows it: accuracy over every attempt.
  static SkillActivity readingActivity(
    List<ReadingAttempt> attempts,
    DateTime today,
  ) {
    final day = dateOnly(today);
    final monday = addDays(day, -(day.weekday - DateTime.monday));
    return SkillActivity(
      attempts: attempts.length,
      correctAnswers: attempts.fold(0, (sum, a) => sum + a.correct),
      totalAnswers: attempts.fold(0, (sum, a) => sum + a.total),
      thisWeek: attempts.where((a) => !a.date.isBefore(monday)).length,
      lastPracticed: attempts
          .map((a) => a.date)
          .reduce((a, b) => a.isAfter(b) ? a : b),
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
