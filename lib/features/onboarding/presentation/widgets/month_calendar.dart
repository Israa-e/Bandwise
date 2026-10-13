import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';

/// Single-month date picker that starts on [today]'s month.
///
/// Past days are disabled, today is outlined, the selected day is filled.
/// Users can page forward to later months but not back before this month.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
    this.maxMonthsAhead = 24,
  });

  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final int maxMonthsAhead;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month;

  DateTime get _firstMonth => DateTime(widget.today.year, widget.today.month);

  @override
  void initState() {
    super.initState();
    // Open on the selected date's month if there is one.
    final initial = widget.selected ?? widget.today;
    _month = DateTime(initial.year, initial.month);
    if (_month.isBefore(_firstMonth)) _month = _firstMonth;
  }

  bool get _canGoBack => _month.isAfter(_firstMonth);

  bool get _canGoForward {
    final last = DateTime(
      _firstMonth.year,
      _firstMonth.month + widget.maxMonthsAhead,
    );
    return _month.isBefore(last);
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = _month == _firstMonth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      formatMonthYear(_month),
                      style: AppTextStyles.headlineSm,
                    ),
                  ),
                  if (isCurrentMonth)
                    Text(
                      'Current month',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Previous month',
              onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: _canGoForward ? () => _shiftMonth(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _WeekdayRow(),
        const SizedBox(height: AppSpacing.xs),
        _DayGrid(
          month: _month,
          today: widget.today,
          selected: widget.selected,
          onSelected: widget.onSelected,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  // Monday-first, matching the design.
  static final _labels = [
    for (var d = 0; d < 7; d++)
      DateFormat.E().format(DateTime(2024, 1, 1 + d)), // 2024-01-01 is Monday
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
    required this.selected,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month).weekday - 1; // Mon = 0
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

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
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 44);
    final date = DateTime(month.year, month.month, day);
    return _DayCell(
      date: date,
      isPast: date.isBefore(today),
      isToday: date == today,
      isSelected: date == selected,
      onTap: () => onSelected(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isPast,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isPast;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? AppColors.onPrimary
        : isPast
        ? AppColors.textDisabled
        : AppColors.text;

    return Semantics(
      button: !isPast,
      enabled: !isPast,
      selected: isSelected,
      label:
          '${formatLongDate(date)}${isToday ? ', today' : ''}'
          '${isPast ? ', unavailable' : ''}',
      excludeSemantics: true,
      child: SizedBox(
        height: 44,
        child: Center(
          child: InkResponse(
            onTap: isPast ? null : onTap,
            radius: 22,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : null,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: AppTextStyles.tabular(AppTextStyles.labelLg).copyWith(
                  color: textColor,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
