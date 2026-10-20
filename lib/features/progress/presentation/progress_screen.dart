import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/skill.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/domain/weekly_activity.dart';
import '../../home/presentation/widgets/weekly_activity_card.dart';
import '../../learn/presentation/learn_providers.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../review/domain/review_planner.dart';
import '../../writing/domain/writing.dart';
import '../../writing/presentation/widgets/feedback_widgets.dart';
import '../../writing/presentation/widgets/line_chart_view.dart';
import '../domain/skill_insights.dart';
import 'progress_providers.dart';
import 'widgets/streak_calendar.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// The streak rule, as the app applies it.
const streakRuleText =
    'A day counts toward your streak when you complete at least one '
    'activity: a lesson, a review, reading practice or an essay. Your '
    'daily goal is tracked separately and does not affect your streak.';

/// The Progress tab: streaks, study time, skills and the notebooks. Every
/// number comes from the saved progress; no bands.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(progressPageProvider);
    final goal = ref
        .watch(onboardingControllerProvider)
        .value
        ?.targetBand
        ?.value;

    final Widget body;
    if (page.hasValue && !page.hasError) {
      final data = page.requireValue;
      body = data.isNew ? const _NewUser() : _ProgressContent(data: data);
    } else if (page.hasError && !page.isLoading) {
      body = ListView(
        padding: _padding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load your progress",
            message: 'Your progress is saved. Try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(progressPageProvider),
          ),
        ],
      );
    } else {
      body = const _ProgressSkeleton();
    }

    return Scaffold(
      appBar: TabTopBar(
        title: 'Progress',
        trailing: goal == null ? null : GoalChip(value: goal),
      ),
      body: body,
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget pair() => const Row(
      children: [
        Expanded(child: SkeletonCard(height: 96)),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: SkeletonCard(height: 96)),
      ],
    );
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: _padding,
          children: [
            pair(),
            const SizedBox(height: AppSpacing.sm),
            pair(),
            const SizedBox(height: AppSpacing.lg),
            const SkeletonCard(height: 220),
          ],
        ),
      ),
    );
  }
}

/// Day one: one friendly card instead of a page of zeros.
class _NewUser extends StatelessWidget {
  const _NewUser();

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      key: const ValueKey('progressEmpty'),
      icon: Icons.insights_rounded,
      title: 'Your progress starts here',
      message:
          'Finish your first lesson to see your progress. Your streak, '
          'study time, skills and notebooks will build up as you study.',
      action: AppButton.primary(
        label: 'Start learning',
        expand: false,
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: () => context.go(AppRoutes.learn),
      ),
    );
  }
}

class _ProgressContent extends ConsumerWidget {
  const _ProgressContent({required this.data});

  final ProgressPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final dailyGoal =
        ref.watch(onboardingControllerProvider).value?.dailyMinutes ??
        OnboardingState.defaultDailyMinutes;
    final progress = data.progress;
    final week = WeeklyActivity.build(
      today: today,
      minutesToday: progress.minutesOn(today),
      minutesByDay: progress.minutesByDay,
      dailyGoal: dailyGoal,
    );

    return ListView(
      padding: _padding,
      children: [
        _Summary(data: data, today: today),
        const SizedBox(height: AppSpacing.lg),
        WeeklyActivityCard(
          key: const ValueKey('thisWeek'),
          week: week,
          title: 'This week',
          showGoal: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          key: const ValueKey('streakCalendar'),
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'Streak calendar',
                  style: AppTextStyles.headlineSm,
                ),
              ),
              const SizedBox(height: AppSpacing.smd),
              StreakCalendar(today: today, activeDays: progress.activeDays),
              const SizedBox(height: AppSpacing.smd),
              Text(
                streakRuleText,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Skills'),
        _ReadingCard(insights: data.reading),
        const SizedBox(height: AppSpacing.smd),
        _WritingCard(insights: data.writing),
        const SizedBox(height: AppSpacing.smd),
        _LessonsCard(data: data),
        const SizedBox(height: AppSpacing.smd),
        GroupCard(
          children: [
            for (final skill in [Skill.listening, Skill.speaking])
              AppListRow(
                key: ValueKey('skill-${skill.name}'),
                icon: skill.icon,
                iconColor: skill.color,
                iconBackground: skill.tint,
                title: skill.label,
                subtitle: 'Not started — coming soon',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Notebooks'),
        _Notebooks(planner: data.planner, today: today),
      ],
    );
  }
}

/// Streaks, XP, study time and lessons completed.
class _Summary extends StatelessWidget {
  const _Summary({required this.data, required this.today});

  final ProgressPageData data;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final progress = data.progress;
    final streak = progress.streak(today);
    final longest = progress.longestStreak;
    final lessons = data.path.course.lessons.length;
    String days(int n) => n == 1 ? 'day' : 'days';

    Widget pair(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: b),
        ],
      ),
    );

    return Column(
      children: [
        pair(
          StatTile(
            key: const ValueKey('summary-streak'),
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.warning,
            label: 'Current streak',
            value: '$streak',
            unit: days(streak),
            footer: 'Longest: $longest ${days(longest)}',
          ),
          StatTile(
            key: const ValueKey('summary-xp'),
            icon: Icons.bolt_rounded,
            iconColor: AppColors.primary,
            label: 'Total XP',
            value: NumberFormat.decimalPattern().format(progress.totalXp),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        pair(
          StatTile(
            key: const ValueKey('summary-time'),
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            label: 'Study time',
            value: formatStudyTime(progress.totalMinutes),
          ),
          StatTile(
            key: const ValueKey('summary-lessons'),
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            label: 'Lessons completed',
            value: '${progress.results.length}',
            footer: 'of $lessons',
          ),
        ),
      ],
    );
  }
}

/// A skill card's header: the skill's icon, its name and a count.
class _SkillHeader extends StatelessWidget {
  const _SkillHeader({required this.skill, this.trailing});

  final Skill skill;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: skill.tint,
            borderRadius: AppRadii.nestedRadius,
          ),
          child: Icon(skill.icon, size: 20, color: skill.color),
        ),
        const SizedBox(width: AppSpacing.smd),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(skill.label, style: AppTextStyles.headlineSm),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTextStyles.tabular(
              AppTextStyles.labelMd,
            ).copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

/// Muted text with an optional link, for a section with nothing yet.
class _NothingYet extends StatelessWidget {
  const _NothingYet({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
        ),
        if (action != null)
          TextButton.icon(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(action!),
          ),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.insights});

  final ReadingInsights insights;

  @override
  Widget build(BuildContext context) {
    final attempts = insights.attempts;
    return AppCard(
      key: const ValueKey('readingCard'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkillHeader(
            skill: Skill.reading,
            trailing: insights.isEmpty
                ? null
                : attempts == 1
                ? '1 attempt'
                : '$attempts attempts',
          ),
          const SizedBox(height: AppSpacing.smd),
          if (insights.isEmpty)
            _NothingYet(
              message: 'No reading practice yet.',
              action: 'Try a passage',
              onAction: () => context.go(AppRoutes.readingHub),
            )
          else ...[
            _RecentAccuracy(points: insights.recent),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Accuracy by question type',
              style: AppTextStyles.labelLg,
            ),
            for (final e in insights.byType.entries)
              _TypeRow(
                type: e.key.label,
                correct: e.value.correct,
                total: e.value.total,
              ),
            if (insights.weakestType case final weakest?) ...[
              const SizedBox(height: AppSpacing.md),
              _Recommendation(
                text: '${weakest.label} is your weakest question type lately.',
                action: 'Practise ${weakest.label}',
                onAction: () =>
                    context.go(AppRoutes.readingHubFor(weakest.name)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Accuracy of the last few attempts as a small line chart.
class _RecentAccuracy extends StatelessWidget {
  const _RecentAccuracy({required this.points});

  final List<AccuracyPoint> points;

  @override
  Widget build(BuildContext context) {
    final count = points.length;
    final title = count == 1
        ? 'Accuracy, last attempt'
        : 'Accuracy, last $count attempts';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.labelLg),
        const SizedBox(height: AppSpacing.sm),
        if (count < 2)
          Text(
            count == 1
                ? '${points.single.percent}% on your only attempt so far. '
                      'Practise again to see a trend.'
                : 'No answers yet.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          )
        else
          LineChartGraphic(
            key: const ValueKey('readingAccuracyChart'),
            aspectRatio: 2.2,
            semanticLabel:
                '$title: ${points.map((p) => '${p.percent}%').join(', ')}',
            data: LineChartData(
              title: title,
              xLabels: [for (final p in points) formatShortDate(p.date)],
              series: [
                ChartSeries('Accuracy', [for (final p in points) p.percent]),
              ],
              yMax: 100,
              yStep: 50,
              unit: '%',
            ),
          ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.correct,
    required this.total,
  });

  final String type;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = percentOf(correct, total) ?? 0;
    return Semantics(
      label: '$type: $correct of $total correct, $percent%',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.smd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(type, style: AppTextStyles.bodyMd)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$correct/$total · $percent%',
                  style: AppTextStyles.tabular(AppTextStyles.labelMd),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            AppLinearProgress(
              value: total == 0 ? 0 : correct / total,
              height: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// A rule-based suggestion, labelled as such.
class _Recommendation extends StatelessWidget {
  const _Recommendation({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('recommendation'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Based on your recent answers',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.smd),
          AppButton.secondary(label: action, onPressed: onAction),
        ],
      ),
    );
  }
}

class _WritingCard extends StatelessWidget {
  const _WritingCard({required this.insights});

  final WritingInsights insights;

  @override
  Widget build(BuildContext context) {
    final essays = insights.essays;
    final top = insights.topNoteType;
    return AppCard(
      key: const ValueKey('writingCard'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkillHeader(
            skill: Skill.writing,
            trailing: insights.isEmpty
                ? null
                : essays == 1
                ? '1 essay'
                : '$essays essays',
          ),
          const SizedBox(height: AppSpacing.smd),
          if (insights.isEmpty)
            _NothingYet(
              message: 'No essays yet.',
              action: 'Write an essay',
              onAction: () => context.go(AppRoutes.writingHub),
            )
          else ...[
            for (final (i, type) in WritingTaskType.values.indexed) ...[
              if (i > 0)
                const Divider(
                  height: AppSpacing.xl,
                  color: AppColors.borderSubtle,
                ),
              _WritingTaskRow(type: type, insights: insights.byType[type]!),
            ],
            if (top != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(top.icon, size: 18, color: top.color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      noteTypeSentence(top),
                      key: const ValueKey('topNoteType'),
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WritingTaskRow extends StatelessWidget {
  const _WritingTaskRow({required this.type, required this.insights});

  final WritingTaskType type;
  final WritingTaskInsights insights;

  @override
  Widget build(BuildContext context) {
    final counts = [
      insights.essays == 1 ? '1 essay' : '${insights.essays} essays',
      if (insights.revisions > 0)
        insights.revisions == 1
            ? '1 revision'
            : '${insights.revisions} revisions',
    ].join(' · ');
    final estimate = insights.latestEstimate;
    final muted = AppTextStyles.bodySm.copyWith(color: AppColors.textMuted);
    return Column(
      key: ValueKey('writing-${type.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${type.label} · ${type.kind}',
                style: AppTextStyles.labelLg,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(counts, style: AppTextStyles.tabular(muted)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (estimate != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Latest practice estimate, '
                  '${formatShortDate(insights.latestEstimateOn!)}',
                  style: muted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              EstimateRangeText(range: estimate),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const EstimateLabel(),
        ] else if (insights.essays + insights.revisions == 0)
          Text('No ${type.label} essays yet.', style: muted)
        else ...[
          Text(
            'No estimate yet',
            key: ValueKey('noEstimate-${type.name}'),
            style: AppTextStyles.bodyMd,
          ),
          Text("Demo feedback doesn't include an estimate.", style: muted),
        ],
      ],
    );
  }
}

class _LessonsCard extends ConsumerWidget {
  const _LessonsCard({required this.data});

  final ProgressPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = data.path;
    return AppCard(
      key: const ValueKey('lessonsCard'),
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: AppRadii.nestedRadius,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.smd),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'Lessons',
                      style: AppTextStyles.headlineSm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final unit in path.course.units)
            Builder(
              builder: (context) {
                final stats = path.statsFor(unit);
                return Semantics(
                  button: true,
                  label:
                      '${unit.fullTitle}, ${stats.percentComplete}% complete. '
                      'Open in Learn',
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('unit-${unit.number}'),
                    onTap: () {
                      ref
                          .read(selectedUnitProvider.notifier)
                          .select(unit.number);
                      context.go(AppRoutes.learn);
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  unit.fullTitle,
                                  style: AppTextStyles.bodyMd,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${stats.percentComplete}% complete',
                                style: AppTextStyles.tabular(
                                  AppTextStyles.labelMd,
                                ).copyWith(color: AppColors.textMuted),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppLinearProgress(value: stats.fraction, height: 6),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Entry rows for the two notebooks.
class _Notebooks extends StatelessWidget {
  const _Notebooks({required this.planner, required this.today});

  final ReviewPlanner planner;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final mistakes = planner.progress.mistakes.length;
    final words = planner.items.whereType<WordReviewItem>().length;
    final due = planner.dueOn(today);
    final mistakesDue = due.where((i) => i.isMistake).length;
    final wordsDue = due.whereType<WordReviewItem>().length;
    String withDue(String count, int due) =>
        due == 0 ? count : '$count · $due due today';

    return GroupCard(
      children: [
        AppListRow(
          key: const ValueKey('mistakeNotebookEntry'),
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.errorText,
          iconBackground: AppColors.errorTint,
          title: 'Mistake notebook',
          subtitle: mistakes == 0
              ? 'No mistakes saved yet'
              : withDue(
                  mistakes == 1
                      ? '1 saved mistake'
                      : '$mistakes saved mistakes',
                  mistakesDue,
                ),
          onTap: () => context.push(AppRoutes.mistakeNotebook),
        ),
        AppListRow(
          key: const ValueKey('vocabularyNotebookEntry'),
          icon: Icons.translate_rounded,
          title: 'Vocabulary notebook',
          subtitle: words == 0
              ? 'Words from finished lessons appear here'
              : withDue(words == 1 ? '1 word' : '$words words', wordsDue),
          onTap: () => context.push(AppRoutes.vocabularyNotebook),
        ),
      ],
    );
  }
}
