import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';

/// A month of study days: active days filled, today outlined. Pages back to
/// the first month with activity and forward to the current month.
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({
    super.key,
    required this.today,
    required this.activeDays,
  });

  final DateTime today;
  final Set<DateTime> activeDays;

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _month = _lastMonth;

  DateTime get _lastMonth => DateTime(widget.today.year, widget.today.month);

  DateTime get _firstMonth {
    if (widget.activeDays.isEmpty) return _lastMonth;
    final first = widget.activeDays.reduce((a, b) => a.isBefore(b) ? a : b);
    final month = DateTime(first.year, first.month);
    return month.isBefore(_lastMonth) ? month : _lastMonth;
  }

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final canGoBack = _month.isAfter(_firstMonth);
    final canGoForward = _month.isBefore(_lastMonth);
    final activeThisMonth = widget.activeDays
        .where((d) => d.year == _month.year && d.month == _month.month)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      formatMonthYear(_month),
                      key: const ValueKey('calendarMonth'),
                      style: AppTextStyles.headlineSm,
                    ),
                  ),
                  Text(
                    activeThisMonth == 1
                        ? '1 active day'
                        : '$activeThisMonth active days',
                    key: const ValueKey('calendarActiveCount'),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: canGoBack ? () => _shift(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: canGoForward ? () => _shift(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _WeekdayRow(),
        const SizedBox(height: AppSpacing.xs),
        _DayGrid(
          month: _month,
          today: dateOnly(widget.today),
          activeDays: widget.activeDays,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  // Monday first; 2024-01-01 was a Monday.
  static final _labels = [
    for (var d = 0; d < 7; d++) DateFormat.E().format(DateTime(2024, 1, 1 + d)),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final label in _labels)
            Expanded(
              child: Center(
                child: Text(
                  label.characters.first,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.today,
    required this.activeDays,
  });

  final DateTime month;
  final DateTime today;
  final Set<DateTime> activeDays;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month).weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(r * 7 + c - leading + 1, daysInMonth)),
            ],
          ),
      ],
    );
  }

  Widget _cell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 40);
    final date = DateTime(month.year, month.month, day);
    return _DayCell(
      date: date,
      active: activeDays.contains(date),
      isToday: date == today,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.active,
    required this.isToday,
  });

  final DateTime date;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: [
        formatLongDate(date),
        if (isToday) 'today',
        active ? 'active' : 'no activity',
      ].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        key: ValueKey('day-${formatIsoDay(date)}'),
        height: 40,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : null,
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(
                      color: active ? AppColors.text : AppColors.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: AppTextStyles.tabular(AppTextStyles.labelMd).copyWith(
                color: active ? AppColors.onPrimary : AppColors.text,
                fontWeight: isToday || active
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
