import 'package:flutter/foundation.dart';

import '../../progress/domain/progress_state.dart';
import 'course.dart';

enum LessonStatus {
  /// Done, with no saved mistakes.
  completed,

  /// Done, with mistakes saved for review.
  reviewNeeded,

  /// The next lesson to take (one per course).
  current,

  /// Open but not the suggested next step.
  available,
  locked,
}

/// A lesson as it appears on the path.
@immutable
class LessonNode {
  const LessonNode({
    required this.lesson,
    required this.status,
    this.result,
    this.mistakeCount = 0,
    this.lockedReason,
  });

  final Lesson lesson;
  final LessonStatus status;
  final LessonResult? result;
  final int mistakeCount;

  /// e.g. "Unlocks after Lesson 2". Only for [LessonStatus.locked].
  final String? lockedReason;

  bool get isLocked => status == LessonStatus.locked;
}

/// Completion and accuracy for one unit. Never a band.
@immutable
class UnitStats {
  const UnitStats({
    required this.completed,
    required this.total,
    required this.correct,
    required this.answered,
  });

  final int completed;
  final int total;
  final int correct;
  final int answered;

  double get fraction => total == 0 ? 0 : completed / total;
  int get percentComplete => (fraction * 100).round();

  /// Null until a question has been answered.
  int? get accuracyPercent =>
      answered == 0 ? null : (correct * 100 / answered).round();
}

/// Applies the unlocking rules to the course and the learner's progress.
///
/// - Lessons unlock in order within a unit; the checkpoint comes last.
/// - The recommended [startUnit] is open from its Lesson 1.
/// - Earlier units stay fully open, so learners can go back.
/// - A later unit opens once the previous unit's checkpoint is done.
class LearningPath {
  const LearningPath({
    required this.course,
    required this.progress,
    required this.startUnit,
  });

  final Course course;
  final ProgressState progress;
  final int startUnit;

  bool isUnlocked(Lesson lesson) => _lockedReason(lesson) == null;

  String? _lockedReason(Lesson lesson) {
    if (lesson.unit < startUnit) return null;
    final unit = course.unit(lesson.unit);
    final index = unit.lessons.indexOf(lesson);
    if (index > 0) {
      final previous = unit.lessons[index - 1];
      return progress.isCompleted(previous.id)
          ? null
          : 'Unlocks after ${previous.label}';
    }
    if (lesson.unit == startUnit) return null;
    final previousUnit = course.unit(lesson.unit - 1);
    return progress.isCompleted(previousUnit.lessons.last.id)
        ? null
        : 'Unlocks after the Unit ${previousUnit.number} checkpoint';
  }

  /// The first open, unfinished lesson from the starting unit onwards.
  Lesson? get nextLesson {
    for (final lesson in course.lessons) {
      if (lesson.unit < startUnit) continue;
      if (!progress.isCompleted(lesson.id) && isUnlocked(lesson)) {
        return lesson;
      }
    }
    return null;
  }

  LessonNode nodeFor(Lesson lesson) {
    final mistakes = progress.mistakesFor(lesson.id).length;
    final result = progress.results[lesson.id];
    final reason = _lockedReason(lesson);
    final status = result != null
        ? (mistakes > 0 ? LessonStatus.reviewNeeded : LessonStatus.completed)
        : reason != null
        ? LessonStatus.locked
        : lesson.id == nextLesson?.id
        ? LessonStatus.current
        : LessonStatus.available;
    return LessonNode(
      lesson: lesson,
      status: status,
      result: result,
      mistakeCount: mistakes,
      lockedReason: reason,
    );
  }

  List<LessonNode> nodesFor(Unit unit) => [
    for (final lesson in unit.lessons) nodeFor(lesson),
  ];

  UnitStats statsFor(Unit unit) {
    var completed = 0, correct = 0, answered = 0;
    for (final lesson in unit.lessons) {
      final result = progress.results[lesson.id];
      if (result == null) continue;
      completed++;
      correct += result.correct;
      answered += result.total;
    }
    return UnitStats(
      completed: completed,
      total: unit.lessons.length,
      correct: correct,
      answered: answered,
    );
  }
}
