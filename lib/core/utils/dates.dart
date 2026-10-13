import 'package:intl/intl.dart';

/// Strips the time from [date], keeping the local calendar day.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whole days from [from] to [to], ignoring time of day and DST shifts.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// "8 weeks" / "1 week" / "5 days" / "1 day" / "today" until [date].
String timeUntilLabel(DateTime today, DateTime date) {
  final days = daysBetween(today, date);
  if (days <= 0) return 'today';
  if (days < 7) return days == 1 ? '1 day' : '$days days';
  final weeks = days ~/ 7;
  return weeks == 1 ? '1 week' : '$weeks weeks';
}

/// "July 14, 2026".
String formatLongDate(DateTime date) => DateFormat.yMMMMd().format(date);

/// "Jul 14, 2026".
String formatMediumDate(DateTime date) => DateFormat.yMMMd().format(date);

/// "May 2026".
String formatMonthYear(DateTime date) => DateFormat.yMMMM().format(date);
