import 'package:flutter/foundation.dart';

import '../../../core/models/skill.dart';

/// Everything Home shows that comes from the learner's history.
///
/// Onboarding answers (daily minutes, target, focus skills, starting unit)
/// are read separately from the onboarding controller.
@immutable
class HomeSummary {
  const HomeSummary({
    required this.displayName,
    required this.streakDays,
    required this.totalXp,
    required this.xpToday,
    required this.minutesToday,
    required this.hasCompletedLessons,
    required this.nextLesson,
    required this.mistakesDue,
    required this.wordsDue,
    required this.skills,
    required this.minutesByDay,
  });

  /// Null when the account has no name.
  final String? displayName;
  final int streakDays;
  final int totalXp;
  final int xpToday;
  final int minutesToday;

  /// False on day 1: Home recommends the starting unit instead of
  /// [nextLesson].
  final bool hasCompletedLessons;

  /// The next lesson on the path, or null when nothing is left to open.
  final NextLesson? nextLesson;

  /// Saved mistakes and vocabulary due for review today.
  final int mistakesDue;
  final int wordsDue;

  int get reviewsDue => mistakesDue + wordsDue;
  final Map<Skill, SkillActivity> skills;

  /// Study minutes per local day (date-only keys), for days before today.
  /// Today's minutes are [minutesToday].
  final Map<DateTime, int> minutesByDay;

  SkillActivity activityFor(Skill skill) =>
      skills[skill] ?? const SkillActivity();
}

/// The next lesson on the learner's path.
@immutable
class NextLesson {
  const NextLesson({
    required this.id,
    required this.unit,
    required this.unitTitle,
    required this.label,
    required this.title,
    required this.unitProgress,
    required this.estimatedMinutes,
  });

  final String id;

  /// 1-based unit number.
  final int unit;
  final String unitTitle;

  /// "Lesson 2" or "Checkpoint".
  final String label;
  final String title;

  /// Share of the unit completed, 0.0 to 1.0.
  final double unitProgress;
  final int estimatedMinutes;
}

/// Practice history for one skill.
@immutable
class SkillActivity {
  const SkillActivity({
    this.attempts = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.thisWeek = 0,
    this.lastPracticed,
  });

  /// Completed practice sets, essays or speaking sessions, all time.
  final int attempts;

  /// For Listening and Reading: questions answered correctly / answered.
  final int correctAnswers;
  final int totalAnswers;

  /// Attempts in the current week.
  final int thisWeek;
  final DateTime? lastPracticed;

  bool get hasAttempts => attempts > 0;

  /// Rounded percent, or null when nothing was answered.
  int? get accuracyPercent =>
      totalAnswers == 0 ? null : (correctAnswers * 100 / totalAnswers).round();
}
