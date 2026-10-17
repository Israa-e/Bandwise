import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';

/// XP rules.
abstract final class XpRules {
  static const perLesson = 10;
  static const perFirstTryCorrect = 2;

  static int forLesson(int correctFirstTry) =>
      perLesson + perFirstTryCorrect * correctFirstTry;
}

/// The learner's saved history. Dates are local, date-only.
@immutable
class ProgressState {
  const ProgressState({
    this.results = const {},
    this.xpLog = const [],
    this.minutesByDay = const {},
    this.activeDays = const {},
    this.mistakes = const [],
  });

  /// Latest result per completed lesson id.
  final Map<String, LessonResult> results;
  final List<XpEntry> xpLog;
  final Map<DateTime, int> minutesByDay;

  /// Days with at least one completed activity (streak days).
  final Set<DateTime> activeDays;

  /// Wrong answers saved for review.
  final List<SavedMistake> mistakes;

  bool isCompleted(String lessonId) => results.containsKey(lessonId);

  int get totalXp => xpLog.fold(0, (sum, e) => sum + e.amount);

  int xpOn(DateTime day) => xpLog
      .where((e) => e.date == dateOnly(day))
      .fold(0, (sum, e) => sum + e.amount);

  int minutesOn(DateTime day) => minutesByDay[dateOnly(day)] ?? 0;

  List<SavedMistake> mistakesFor(String lessonId) =>
      mistakes.where((m) => m.lessonId == lessonId).toList();

  /// Consecutive active days ending today, or yesterday if today has no
  /// activity yet (the streak is still alive until today ends).
  int streak(DateTime today) {
    final day = dateOnly(today);
    var cursor = activeDays.contains(day)
        ? day
        : DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (activeDays.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// Records a finished lesson. Replaying a lesson replaces its result and
  /// its saved mistakes, and earns XP again.
  ProgressState withCompletedLesson(LessonCompletion c) {
    final day = dateOnly(c.date);
    return ProgressState(
      results: {
        ...results,
        c.lessonId: LessonResult(
          correct: c.correctFirstTry,
          total: c.questionCount,
          xp: c.xp,
          completedOn: day,
        ),
      },
      xpLog: [
        ...xpLog,
        XpEntry(date: day, amount: c.xp, lessonId: c.lessonId),
      ],
      minutesByDay: {...minutesByDay, day: minutesOn(day) + c.minutes},
      activeDays: {...activeDays, day},
      mistakes: [
        ...mistakes.where((m) => m.lessonId != c.lessonId),
        ...c.mistakes,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'results': {for (final e in results.entries) e.key: e.value.toJson()},
    'xpLog': [for (final e in xpLog) e.toJson()],
    'minutesByDay': {
      for (final e in minutesByDay.entries) _day(e.key): e.value,
    },
    'activeDays': [for (final d in activeDays) _day(d)],
    'mistakes': [for (final m in mistakes) m.toJson()],
  };

  static ProgressState fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>? ?? {};
    final minutes = json['minutesByDay'] as Map<String, dynamic>? ?? {};
    return ProgressState(
      results: {
        for (final e in results.entries)
          e.key: LessonResult.fromJson(e.value as Map<String, dynamic>),
      },
      xpLog: [
        for (final e in json['xpLog'] as List? ?? const [])
          XpEntry.fromJson(e as Map<String, dynamic>),
      ],
      minutesByDay: {
        for (final e in minutes.entries) _parseDay(e.key): e.value as int,
      },
      activeDays: {
        for (final d in json['activeDays'] as List? ?? const [])
          _parseDay(d as String),
      },
      mistakes: [
        for (final m in json['mistakes'] as List? ?? const [])
          SavedMistake.fromJson(m as Map<String, dynamic>),
      ],
    );
  }
}

/// "2026-10-15".
String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _parseDay(String s) => dateOnly(DateTime.parse(s));

@immutable
class LessonResult {
  const LessonResult({
    required this.correct,
    required this.total,
    required this.xp,
    required this.completedOn,
  });

  /// Questions answered correctly on the first try.
  final int correct;
  final int total;
  final int xp;
  final DateTime completedOn;

  Map<String, dynamic> toJson() => {
    'correct': correct,
    'total': total,
    'xp': xp,
    'completedOn': _day(completedOn),
  };

  static LessonResult fromJson(Map<String, dynamic> json) => LessonResult(
    correct: json['correct'] as int,
    total: json['total'] as int,
    xp: json['xp'] as int,
    completedOn: _parseDay(json['completedOn'] as String),
  );
}

@immutable
class XpEntry {
  const XpEntry({
    required this.date,
    required this.amount,
    required this.lessonId,
  });

  final DateTime date;
  final int amount;
  final String lessonId;

  Map<String, dynamic> toJson() => {
    'date': _day(date),
    'amount': amount,
    'lessonId': lessonId,
  };

  static XpEntry fromJson(Map<String, dynamic> json) => XpEntry(
    date: _parseDay(json['date'] as String),
    amount: json['amount'] as int,
    lessonId: json['lessonId'] as String,
  );
}

/// A wrong answer kept for later review.
@immutable
class SavedMistake {
  const SavedMistake({
    required this.lessonId,
    required this.prompt,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.explanation,
  });

  final String lessonId;

  /// The question, with its sentence or passage if it has one.
  final String prompt;
  final String yourAnswer;
  final String correctAnswer;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'prompt': prompt,
    'yourAnswer': yourAnswer,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
  };

  static SavedMistake fromJson(Map<String, dynamic> json) => SavedMistake(
    lessonId: json['lessonId'] as String,
    prompt: json['prompt'] as String,
    yourAnswer: json['yourAnswer'] as String,
    correctAnswer: json['correctAnswer'] as String,
    explanation: json['explanation'] as String,
  );
}

/// Everything recorded when a lesson is finished.
@immutable
class LessonCompletion {
  const LessonCompletion({
    required this.lessonId,
    required this.date,
    required this.correctFirstTry,
    required this.questionCount,
    required this.minutes,
    required this.mistakes,
  });

  final String lessonId;
  final DateTime date;
  final int correctFirstTry;
  final int questionCount;
  final int minutes;
  final List<SavedMistake> mistakes;

  int get xp => XpRules.forLesson(correctFirstTry);

  /// Whole minutes for [elapsed], rounded up (at least 1) and capped at
  /// twice the lesson's estimate.
  static int minutesFor(Duration elapsed, int estimatedMinutes) {
    final minutes = (elapsed.inSeconds / 60).ceil();
    return minutes.clamp(1, estimatedMinutes * 2);
  }
}
