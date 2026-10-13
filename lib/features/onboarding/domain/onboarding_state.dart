import 'package:flutter/foundation.dart';

import '../../../core/models/skill.dart';

/// Screens of the onboarding flow, in order. Persisted so a restart resumes
/// on the same screen.
enum OnboardingStep {
  welcome,
  targetBand,
  examDate,
  currentLevel,
  dailyTime,
  skills,
  placement,
  plan;

  /// 1-based number shown in "Step X of 6", or null for screens outside the
  /// numbered steps.
  int? get number => switch (this) {
    targetBand => 1,
    examDate => 2,
    currentLevel => 3,
    dailyTime => 4,
    skills => 5,
    placement => 6,
    welcome || plan => null,
  };

  static const totalNumbered = 6;

  OnboardingStep? get previous =>
      index == 0 ? null : OnboardingStep.values[index - 1];

  OnboardingStep? get next => index == OnboardingStep.values.length - 1
      ? null
      : OnboardingStep.values[index + 1];
}

/// The user's goal. A target, not a prediction.
enum TargetBand {
  band6('6.0', 'Competent user'),
  band65('6.5', 'Competent to good'),
  band7('7.0', 'Good user'),
  band75('7.5', 'Good to very good'),
  band8plus('8.0+', 'Very good user'),
  notSure(null, 'Not sure yet');

  const TargetBand(this.value, this.descriptor);

  /// Display value such as "7.0"; null for [notSure].
  final String? value;
  final String descriptor;
}

/// Self-assessed English level. Not a CEFR result.
enum EnglishLevel {
  beginner('Beginner', 'I can understand basic greetings and isolated words'),
  elementary(
    'Elementary',
    'I can understand simple everyday sentences and questions',
  ),
  intermediate(
    'Intermediate',
    'I can follow short everyday conversations and express familiar ideas',
  ),
  upperIntermediate(
    'Upper-intermediate',
    'I can read standard articles and communicate comfortably in discussions',
  ),
  advanced(
    'Advanced',
    'I can express complex arguments fluently and understand nuanced texts',
  );

  const EnglishLevel(this.label, this.description);

  final String label;
  final String description;
}

/// A time of day, stored without a date.
@immutable
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  Map<String, dynamic> toJson() => {'h': hour, 'm': minute};

  static ReminderTime fromJson(Map<String, dynamic> json) =>
      ReminderTime(json['h'] as int, json['m'] as int);

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Everything collected during onboarding.
///
/// A null answer means the step was skipped or not answered yet.
@immutable
class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.isGuest = false,
    this.completed = false,
    this.targetBand,
    this.examDate,
    this.examNotBooked = false,
    this.level,
    this.dailyMinutes = defaultDailyMinutes,
    this.reminderEnabled = false,
    this.reminderTime,
    this.skills = const {},
    this.placementAnswers = const {},
    this.placementIndex = 0,
    this.placementSkipped = false,
  });

  static const defaultDailyMinutes = 20;
  static const defaultReminderTime = ReminderTime(19, 30);
  static const dailyMinuteOptions = [10, 15, 20, 30, 45];

  final OnboardingStep step;
  final bool isGuest;
  final bool completed;
  final TargetBand? targetBand;

  /// Date-only (local midnight).
  final DateTime? examDate;
  final bool examNotBooked;
  final EnglishLevel? level;
  final int? dailyMinutes;
  final bool reminderEnabled;
  final ReminderTime? reminderTime;
  final Set<Skill> skills;

  /// Question index -> chosen option index.
  final Map<int, int> placementAnswers;

  /// The placement question currently shown.
  final int placementIndex;
  final bool placementSkipped;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isGuest,
    bool? completed,
    ValueGetter<TargetBand?>? targetBand,
    ValueGetter<DateTime?>? examDate,
    bool? examNotBooked,
    ValueGetter<EnglishLevel?>? level,
    ValueGetter<int?>? dailyMinutes,
    bool? reminderEnabled,
    ValueGetter<ReminderTime?>? reminderTime,
    Set<Skill>? skills,
    Map<int, int>? placementAnswers,
    int? placementIndex,
    bool? placementSkipped,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      isGuest: isGuest ?? this.isGuest,
      completed: completed ?? this.completed,
      targetBand: targetBand != null ? targetBand() : this.targetBand,
      examDate: examDate != null ? examDate() : this.examDate,
      examNotBooked: examNotBooked ?? this.examNotBooked,
      level: level != null ? level() : this.level,
      dailyMinutes: dailyMinutes != null ? dailyMinutes() : this.dailyMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime != null ? reminderTime() : this.reminderTime,
      skills: skills ?? this.skills,
      placementAnswers: placementAnswers ?? this.placementAnswers,
      placementIndex: placementIndex ?? this.placementIndex,
      placementSkipped: placementSkipped ?? this.placementSkipped,
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step.name,
    'isGuest': isGuest,
    'completed': completed,
    'targetBand': targetBand?.name,
    'examDate': examDate?.toIso8601String(),
    'examNotBooked': examNotBooked,
    'level': level?.name,
    'dailyMinutes': dailyMinutes,
    'reminderEnabled': reminderEnabled,
    'reminderTime': reminderTime?.toJson(),
    'skills': [for (final s in skills) s.name],
    'placementAnswers': {
      for (final e in placementAnswers.entries) '${e.key}': e.value,
    },
    'placementIndex': placementIndex,
    'placementSkipped': placementSkipped,
  };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    T? byName<T extends Enum>(List<T> values, Object? name) =>
        values.where((v) => v.name == name).firstOrNull;

    final reminder = json['reminderTime'];
    final answers = json['placementAnswers'] as Map<String, dynamic>? ?? {};
    return OnboardingState(
      step:
          byName(OnboardingStep.values, json['step']) ?? OnboardingStep.welcome,
      isGuest: json['isGuest'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      targetBand: byName(TargetBand.values, json['targetBand']),
      examDate: DateTime.tryParse(json['examDate'] as String? ?? ''),
      examNotBooked: json['examNotBooked'] as bool? ?? false,
      level: byName(EnglishLevel.values, json['level']),
      dailyMinutes: json['dailyMinutes'] as int?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderTime: reminder is Map<String, dynamic>
          ? ReminderTime.fromJson(reminder)
          : null,
      skills: {
        for (final name in json['skills'] as List? ?? const [])
          ?byName(Skill.values, name),
      },
      placementAnswers: {
        for (final e in answers.entries) int.parse(e.key): e.value as int,
      },
      placementIndex: json['placementIndex'] as int? ?? 0,
      placementSkipped: json['placementSkipped'] as bool? ?? false,
    );
  }
}
