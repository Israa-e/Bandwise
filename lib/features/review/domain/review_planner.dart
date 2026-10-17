import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';
import '../../learn/domain/course.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/domain/review_schedule.dart';

/// Something to review: a saved mistake or a word from a finished lesson.
@immutable
sealed class ReviewItem {
  const ReviewItem({
    required this.key,
    required this.lesson,
    required this.dueOn,
    required this.schedule,
  });

  /// See [ProgressState.reviews].
  final String key;
  final Lesson lesson;
  final DateTime dueOn;

  /// Null until the item has been reviewed once.
  final ReviewSchedule? schedule;
}

/// A question answered wrongly in a lesson, asked again.
class MistakeReviewItem extends ReviewItem {
  const MistakeReviewItem({
    required super.key,
    required super.lesson,
    required super.dueOn,
    required super.schedule,
    required this.mistake,
    required this.exercise,
  });

  final SavedMistake mistake;
  final QuestionExercise exercise;
}

/// A flashcard word from a finished lesson.
class WordReviewItem extends ReviewItem {
  const WordReviewItem({
    required super.key,
    required super.lesson,
    required super.dueOn,
    required super.schedule,
    required this.card,
  });

  final FlashcardExercise card;
}

/// Builds the review queue from the course and the learner's progress.
///
/// - Mistakes are due on the day they were made, until first reviewed.
/// - Words from a finished lesson are first due the day after it.
/// - After that, [ProgressState.reviews] decides (see [ReviewSchedule]).
class ReviewPlanner {
  ReviewPlanner({required this.course, required this.progress});

  final Course course;
  final ProgressState progress;

  /// Every reviewable item, in path order: mistakes, then words, per lesson.
  late final List<ReviewItem> items = _build();

  List<ReviewItem> _build() {
    final items = <ReviewItem>[];
    for (final lesson in course.lessons) {
      final result = progress.results[lesson.id];
      if (result == null) continue;
      final mistakes = {
        for (final m in progress.mistakesFor(lesson.id)) m.prompt: m,
      };
      // In exercise order. Mistakes whose question has since changed or
      // been removed are skipped.
      for (final exercise in lesson.exercises.whereType<QuestionExercise>()) {
        final mistake = mistakes[exercise.savedPrompt];
        if (mistake == null) continue;
        final schedule = progress.reviews[mistake.reviewKey];
        items.add(
          MistakeReviewItem(
            key: mistake.reviewKey,
            lesson: lesson,
            dueOn: schedule?.dueOn ?? result.completedOn,
            schedule: schedule,
            mistake: mistake,
            exercise: exercise,
          ),
        );
      }
      for (final card in lesson.exercises.whereType<FlashcardExercise>()) {
        final key = wordReviewKey(lesson.id, card.word);
        final schedule = progress.reviews[key];
        items.add(
          WordReviewItem(
            key: key,
            lesson: lesson,
            dueOn: schedule?.dueOn ?? addDays(result.completedOn, 1),
            schedule: schedule,
            card: card,
          ),
        );
      }
    }
    return items;
  }

  /// Items due on or before [today]: the most overdue first, then mistakes
  /// before words, then path order.
  List<ReviewItem> dueOn(DateTime today) {
    final day = dateOnly(today);
    final due = [
      for (final (i, item) in items.indexed)
        if (!item.dueOn.isAfter(day)) (i, item),
    ];
    due.sort((a, b) {
      final byDate = a.$2.dueOn.compareTo(b.$2.dueOn);
      if (byDate != 0) return byDate;
      final byKind = _kindOrder(a.$2) - _kindOrder(b.$2);
      if (byKind != 0) return byKind;
      return a.$1 - b.$1;
    });
    return [for (final (_, item) in due) item];
  }

  static int _kindOrder(ReviewItem item) => switch (item) {
    MistakeReviewItem() => 0,
    WordReviewItem() => 1,
  };

  /// The first day after [today] with something due, if any.
  DateTime? nextReviewAfter(DateTime today) {
    final day = dateOnly(today);
    DateTime? next;
    for (final item in items) {
      if (!item.dueOn.isAfter(day)) continue;
      if (next == null || item.dueOn.isBefore(next)) next = item.dueOn;
    }
    return next;
  }
}
