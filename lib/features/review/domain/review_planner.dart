import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';
import '../../learn/domain/course.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/domain/review_schedule.dart';
import '../../reading/domain/reading.dart';

/// Something to review: a saved mistake or a word from a finished lesson.
@immutable
sealed class ReviewItem {
  const ReviewItem({
    required this.key,
    required this.dueOn,
    required this.schedule,
  });

  /// See [ProgressState.reviews].
  final String key;
  final DateTime dueOn;

  /// Null until the item has been reviewed once.
  final ReviewSchedule? schedule;

  /// A saved mistake rather than a word.
  bool get isMistake => this is! WordReviewItem;
}

/// A lesson question answered wrongly, asked again.
class MistakeReviewItem extends ReviewItem {
  const MistakeReviewItem({
    required super.key,
    required super.dueOn,
    required super.schedule,
    required this.lesson,
    required this.mistake,
    required this.exercise,
  });

  final Lesson lesson;
  final SavedMistake mistake;
  final QuestionExercise exercise;
}

/// A reading question answered wrongly, asked again with its paragraph.
class ReadingMistakeReviewItem extends ReviewItem {
  const ReadingMistakeReviewItem({
    required super.key,
    required super.dueOn,
    required super.schedule,
    required this.passage,
    required this.mistake,
    required this.question,
  });

  final ReadingPassage passage;
  final SavedMistake mistake;
  final ReadingQuestion question;
}

/// A flashcard word from a finished lesson.
class WordReviewItem extends ReviewItem {
  const WordReviewItem({
    required super.key,
    required super.dueOn,
    required super.schedule,
    required this.lesson,
    required this.card,
  });

  final Lesson lesson;
  final FlashcardExercise card;
}

/// Builds the review queue from the course, reading passages and the
/// learner's progress.
///
/// - Mistakes are due on the day they were made, until first reviewed.
/// - Words from a finished lesson are first due the day after it.
/// - After that, [ProgressState.reviews] decides (see [ReviewSchedule]).
///
/// Items are found by stable id, so rewording an exercise keeps its
/// schedule; items whose exercise or question was removed are skipped.
class ReviewPlanner {
  ReviewPlanner({
    required this.course,
    required this.progress,
    this.passages = const [],
  });

  final Course course;
  final ProgressState progress;
  final List<ReadingPassage> passages;

  /// Every reviewable item in path order: per lesson, mistakes then words;
  /// then reading mistakes per passage.
  late final List<ReviewItem> items = _build();

  List<ReviewItem> _build() {
    final items = <ReviewItem>[];
    for (final lesson in course.lessons) {
      final result = progress.results[lesson.id];
      if (result == null) continue;
      final mistakes = {
        for (final m in progress.mistakesFor(lesson.id)) m.itemId: m,
      };
      for (final exercise in lesson.exercises.whereType<QuestionExercise>()) {
        final mistake = mistakes[exercise.id];
        if (mistake == null) continue;
        final schedule = progress.reviews[mistake.reviewKey];
        items.add(
          MistakeReviewItem(
            key: mistake.reviewKey,
            lesson: lesson,
            dueOn: schedule?.dueOn ?? mistake.savedOn ?? result.completedOn,
            schedule: schedule,
            mistake: mistake,
            exercise: exercise,
          ),
        );
      }
      for (final card in lesson.exercises.whereType<FlashcardExercise>()) {
        final key = wordReviewKey(card.id);
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

    final readingMistakes = {
      for (final m in progress.mistakes)
        if (m.source == MistakeSource.reading) m.itemId: m,
    };
    for (final passage in passages) {
      for (final question in passage.questions) {
        final mistake = readingMistakes[question.id];
        final savedOn = mistake?.savedOn;
        if (mistake == null || savedOn == null) continue;
        final schedule = progress.reviews[mistake.reviewKey];
        items.add(
          ReadingMistakeReviewItem(
            key: mistake.reviewKey,
            dueOn: schedule?.dueOn ?? savedOn,
            schedule: schedule,
            passage: passage,
            mistake: mistake,
            question: question,
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

  static int _kindOrder(ReviewItem item) => item.isMistake ? 0 : 1;

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
