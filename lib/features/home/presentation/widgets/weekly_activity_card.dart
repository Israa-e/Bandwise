import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/weekly_activity.dart';

const _chartHeight = 132.0;

/// Space above the tallest bar for today's minutes label.
const _valueLabelSpace = 20.0;

/// Weekly study minutes as a Monday-first bar chart. Past days and today
/// come from history; the rest of the week is planned at the daily goal.
///
/// With [showGoal], a line marks the daily goal and the days it was met
/// are always counted, even when there are none yet.
class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({
    super.key,
    required this.week,
    this.title = 'Weekly activity',
    this.showGoal = false,
  });

  final WeeklyActivity week;
  final String title;
  final bool showGoal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: AppTextStyles.headlineSm),
                    ),
                    Text(
                      'Minutes studied, Monday to Sunday',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!week.isEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  label:
                      '${formatStudyTime(week.totalMinutes)} studied this week',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatStudyTime(week.totalMinutes),
                        key: const ValueKey('weeklyTotal'),
                        style: AppTextStyles.tabular(
                          AppTextStyles.headlineSm,
                        ).copyWith(color: AppColors.primary),
                      ),
                      Text(
                        'this week',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (week.isEmpty)
            const _EmptyWeek()
          else ...[
            _Chart(week: week, showGoal: showGoal),
            if (showGoal) ...[
              const SizedBox(height: AppSpacing.sm),
              _GoalLegend(minutes: week.dailyGoal),
            ],
            if (showGoal || week.goalDays > 0) ...[
              const SizedBox(height: AppSpacing.smd),
              _GoalDaysNote(days: week.goalDays, short: showGoal),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your week starts today',
                  style: AppTextStyles.labelLg,
                ),
                const SizedBox(height: 2),
                Text(
                  'Finish your first lesson to see it here.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains the goal line.
class _GoalLegend extends StatelessWidget {
  const _GoalLegend({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: _goalLineWidth,
          child: ColoredBox(color: AppColors.success),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Daily goal: $minutes min',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _GoalDaysNote extends StatelessWidget {
  const _GoalDaysNote({required this.days, this.short = false});

  final int days;

  /// "Goal met on N days" rather than "Daily goal met on N days".
  final bool short;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.smd,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${short ? 'Goal' : 'Daily goal'} met on $days '
              '${days == 1 ? 'day' : 'days'}',
              key: const ValueKey('goalDays'),
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.week, required this.showGoal});

  final WeeklyActivity week;
  final bool showGoal;

  @override
  Widget build(BuildContext context) {
    final scale = math.max(
      week.dailyGoal,
      week.bars.map((b) => b.minutes).fold(0, math.max),
    );
    final dayLetter = DateFormat.EEEEE();
    final dayName = DateFormat.EEEE();

    return SizedBox(
      height: _chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < week.bars.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _BarColumn(
                key: ValueKey('dayBar$i'),
                bar: week.bars[i],
                scale: scale,
                letter: dayLetter.format(week.bars[i].date),
                dayName: dayName.format(week.bars[i].date),
                goal: showGoal ? week.dailyGoal : null,
                // Reaches into the gaps so the goal line is unbroken.
                goalLineStart: i == 0 ? 0 : AppSpacing.sm / 2,
                goalLineEnd: i == week.bars.length - 1 ? 0 : AppSpacing.sm / 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    super.key,
    required this.bar,
    required this.scale,
    required this.letter,
    required this.dayName,
    this.goal,
    this.goalLineStart = 0,
    this.goalLineEnd = 0,
  });

  final DayBar bar;
  final int scale;
  final String letter;
  final String dayName;

  /// Minutes to draw the goal line at, if shown.
  final int? goal;
  final double goalLineStart;
  final double goalLineEnd;

  @override
  Widget build(BuildContext context) {
    final isToday = bar.kind == DayKind.today;
    final semantics = switch (bar.kind) {
      DayKind.past => '$dayName, ${bar.minutes} minutes',
      DayKind.today => 'Today, $dayName, ${bar.minutes} minutes',
      DayKind.planned => '$dayName, planned ${bar.minutes} minutes',
    };

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBar = constraints.maxHeight - _valueLabelSpace;
                final height = scale == 0
                    ? 0.0
                    : (maxBar * bar.minutes / scale).clamp(4.0, maxBar);
                final goal = this.goal;
                final bars = Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isToday && bar.minutes > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${bar.minutes}m',
                          style: AppTextStyles.tabular(
                            AppTextStyles.labelSm,
                          ).copyWith(color: AppColors.primary),
                        ),
                      ),
                    if (isToday && bar.minutes > 0)
                      const SizedBox(height: AppSpacing.xxs),
                    SizedBox(
                      height: height,
                      child: _Bar(bar: bar),
                    ),
                  ],
                );
                if (goal == null || scale == 0) return bars;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: bars),
                    PositionedDirectional(
                      start: -goalLineStart,
                      end: -goalLineEnd,
                      bottom: maxBar * goal / scale - _goalLineWidth / 2,
                      height: _goalLineWidth,
                      child: const IgnorePointer(
                        child: ColoredBox(color: AppColors.success),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            letter,
            style: AppTextStyles.labelMd.copyWith(
              color: isToday ? AppColors.primary : AppColors.textMuted,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

const _goalLineWidth = 2.0;

const _barRadius = BorderRadius.vertical(top: Radius.circular(AppRadii.bar));

class _Bar extends StatelessWidget {
  const _Bar({required this.bar});

  final DayBar bar;

  @override
  Widget build(BuildContext context) {
    if (bar.isPlanned) {
      return const CustomPaint(painter: _DashedBarPainter());
    }
    final color = switch (bar.kind) {
      DayKind.today => AppColors.primary,
      _ when bar.minutes == 0 => AppColors.track,
      _ => AppColors.chartBar,
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: _barRadius),
    );
  }
}

/// Dashed outline for a planned (future) day.
class _DashedBarPainter extends CustomPainter {
  const _DashedBarPainter();

  static const _dash = 4.0;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textDisabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = (Offset.zero & size).deflate(paint.strokeWidth / 2);
    final path = Path()..addRRect(_barRadius.toRRect(rect));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + _dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBarPainter old) => false;
}
