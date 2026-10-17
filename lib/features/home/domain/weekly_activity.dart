import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';

enum DayKind { past, today, planned }

/// One bar in the weekly chart.
@immutable
class DayBar {
  const DayBar({required this.date, required this.minutes, required this.kind});

  final DateTime date;

  /// Minutes studied; for [DayKind.planned], the planned daily goal.
  final int minutes;
  final DayKind kind;

  bool get isPlanned => kind == DayKind.planned;
}

/// The current Monday-to-Sunday week.
@immutable
class WeeklyActivity {
  const WeeklyActivity._(this.bars, this.dailyGoal);

  /// Builds the week containing [today]. Past days and today come from
  /// history; later days are planned at [dailyGoal] minutes.
  factory WeeklyActivity.build({
    required DateTime today,
    required int minutesToday,
    required Map<DateTime, int> minutesByDay,
    required int dailyGoal,
  }) {
    final day = dateOnly(today);
    final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    final bars = [
      for (var i = 0; i < 7; i++)
        _bar(
          // Calendar arithmetic, so DST shifts don't skip or repeat a day.
          DateTime(monday.year, monday.month, monday.day + i),
          day,
          minutesToday,
          minutesByDay,
          dailyGoal,
        ),
    ];
    return WeeklyActivity._(bars, dailyGoal);
  }

  static DayBar _bar(
    DateTime date,
    DateTime today,
    int minutesToday,
    Map<DateTime, int> minutesByDay,
    int dailyGoal,
  ) {
    final offset = daysBetween(today, date);
    if (offset == 0) {
      return DayBar(date: date, minutes: minutesToday, kind: DayKind.today);
    }
    if (offset > 0) {
      return DayBar(date: date, minutes: dailyGoal, kind: DayKind.planned);
    }
    return DayBar(
      date: date,
      minutes: minutesByDay[date] ?? 0,
      kind: DayKind.past,
    );
  }

  /// Seven bars, Monday first.
  final List<DayBar> bars;
  final int dailyGoal;

  /// Minutes studied this week: the sum of the past and today bars.
  /// Planned bars don't count.
  int get totalMinutes =>
      bars.where((b) => !b.isPlanned).fold(0, (sum, b) => sum + b.minutes);

  /// Days this week (so far) where the daily goal was met.
  int get goalDays =>
      bars.where((b) => !b.isPlanned && b.minutes >= dailyGoal).length;

  bool get isEmpty => totalMinutes == 0;
}

/// "45 min", "1h", "4h 6m".
String formatStudyTime(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
