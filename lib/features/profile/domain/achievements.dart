import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';
import '../../progress/domain/progress_state.dart';
import '../../writing/domain/writing_submission.dart';

/// The badges. Earned from progress only; they give no XP.
enum AchievementKind {
  firstLesson('First lesson', 'Finish any lesson.'),
  streak3('3-day streak', 'Study three days in a row.'),
  streak7('7-day streak', 'Study seven days in a row.'),
  reviews50('50 reviews', 'Rate 50 items in your reviews.'),
  firstReading('First reading passage', 'Finish a reading practice.'),
  perfectPassage(
    '10/10 on a passage',
    'Answer every question on a full passage correctly.',
  ),
  firstEssay('First essay', 'Submit an essay for feedback.'),
  firstRevision('First revision', 'Revise an essay and resubmit it.');

  const AchievementKind(this.title, this.howToEarn);

  final String title;
  final String howToEarn;
}

/// A badge and the day it was earned (null while locked).
@immutable
class Achievement {
  const Achievement(this.kind, this.earnedOn);

  final AchievementKind kind;
  final DateTime? earnedOn;

  bool get unlocked => earnedOn != null;
}

/// Reviews needed for [AchievementKind.reviews50].
const _reviewsGoal = 50;

/// Every badge, in [AchievementKind] order, worked out from [progress] and
/// the submitted [essays].
List<Achievement> achievementsFor(
  ProgressState progress,
  List<WritingSubmission> essays,
) {
  DateTime? earliest(Iterable<DateTime> dates) => dates.isEmpty
      ? null
      : dates.map(dateOnly).reduce((a, b) => a.isBefore(b) ? a : b);

  return [
    for (final kind in AchievementKind.values)
      Achievement(kind, switch (kind) {
        AchievementKind.firstLesson => progress.firstLessonOn,
        AchievementKind.streak3 => streakReachedOn(progress.activeDays, 3),
        AchievementKind.streak7 => streakReachedOn(progress.activeDays, 7),
        AchievementKind.reviews50 => _reviewsReachedOn(progress, _reviewsGoal),
        AchievementKind.firstReading => earliest(
          progress.readingAttempts.map((a) => a.date),
        ),
        AchievementKind.perfectPassage => earliest([
          for (final a in progress.readingAttempts)
            if (a.questionType == null && a.total > 0 && a.correct == a.total)
              a.date,
        ]),
        AchievementKind.firstEssay => earliest([
          for (final e in essays)
            if (e.revisionOf == null) e.submittedAt,
        ]),
        AchievementKind.firstRevision => earliest([
          for (final e in essays)
            if (e.revisionOf != null) e.submittedAt,
        ]),
      }),
  ];
}

/// The first day on which [activeDays] held a run of [length] consecutive
/// days, or null if it never did.
DateTime? streakReachedOn(Set<DateTime> activeDays, int length) {
  final days = activeDays.toList()..sort();
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    run = previous != null && addDays(previous, 1) == day ? run + 1 : 1;
    if (run >= length) return day;
    previous = day;
  }
  return null;
}

DateTime? _reviewsReachedOn(ProgressState progress, int goal) {
  final days = progress.reviewsByDay.keys.toList()..sort();
  var total = 0;
  for (final day in days) {
    total += progress.reviewsByDay[day]!;
    if (total >= goal) return day;
  }
  return null;
}
