import 'package:intl/intl.dart';

/// Strips the time from [date], keeping the local calendar day.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// [date] moved by [days] calendar days (DST-safe), date-only.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// "2026-10-15".
String formatIsoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Parses [formatIsoDay] output as a local, date-only day.
DateTime parseIsoDay(String s) => dateOnly(DateTime.parse(s));

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

/// "Oct 14".
String formatShortDate(DateTime date) => DateFormat.MMMd().format(date);

/// "today" / "yesterday" / "3 days ago" / "Oct 4" for a past [date].
String timeAgoLabel(DateTime today, DateTime date) {
  final days = daysBetween(date, today);
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  return formatShortDate(date);
}
