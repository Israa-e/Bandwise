import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/domain/placement.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../domain/home_summary.dart';
import '../domain/weekly_activity.dart';
import 'home_providers.dart';
import 'widgets/continue_card.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/review_card.dart';
import 'widgets/skill_shortcuts.dart';
import 'widgets/stats_row.dart';
import 'widgets/weekly_activity_card.dart';

const _listPadding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xl,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding =
        ref.watch(onboardingControllerProvider).value ??
        const OnboardingState();
    final summary = ref.watch(homeSummaryProvider);
    final start = ref.watch(startingPointProvider);

    final data = summary.value;
    final ready =
        data != null &&
        !summary.hasError &&
        (data.hasCompletedLessons || start.hasValue);
    final failed = summary.hasError || (start.hasError && !start.hasValue);

    final Widget body;
    if (ready) {
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(homeSummaryProvider.future),
        child: _HomeContent(
          summary: data,
          onboarding: onboarding,
          start: start.value,
        ),
      );
    } else if (failed && !summary.isLoading) {
      body = _HomeError(
        onRetry: () {
          ref.invalidate(homeSummaryProvider);
          if (start.hasError) ref.invalidate(startingPointProvider);
        },
      );
    } else {
      body = const HomeSkeleton(padding: _listPadding);
    }

    return Scaffold(
      appBar: HomeTopBar(
        displayName: onboarding.isGuest ? null : data?.displayName,
        onNotifications: () => context.push(AppRoutes.notifications),
      ),
      body: body,
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.summary,
    required this.onboarding,
    required this.start,
  });

  final HomeSummary summary;
  final OnboardingState onboarding;
  final StartingPoint? start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final dailyGoal =
        onboarding.dailyMinutes ?? OnboardingState.defaultDailyMinutes;
    final week = WeeklyActivity.build(
      today: today,
      minutesToday: summary.minutesToday,
      minutesByDay: summary.minutesByDay,
      dailyGoal: dailyGoal,
    );
    final lesson = summary.nextLesson;
    void openLesson(String id) => context.push(AppRoutes.lessonPath(id));

    return ListView(
      padding: _listPadding,
      children: [
        _Greeting(
          name: onboarding.isGuest ? null : summary.displayName,
          target: onboarding.targetBand,
          line: _greetingLine(summary, dailyGoal),
        ),
        const SizedBox(height: AppSpacing.lg),
        StatsRow(
          streakDays: summary.streakDays,
          totalXp: summary.totalXp,
          xpToday: summary.xpToday,
          minutesToday: summary.minutesToday,
          dailyGoal: dailyGoal,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!summary.hasCompletedLessons)
          ContinueCard.start(start: start!, lesson: lesson, onOpen: openLesson)
        else if (lesson != null)
          ContinueCard.next(lesson: lesson, onOpen: openLesson),
        if (summary.reviewsDue > 0) ...[
          const SizedBox(height: AppSpacing.smd),
          ReviewCard(
            mistakesDue: summary.mistakesDue,
            wordsDue: summary.wordsDue,
            onOpen: () => context.push(AppRoutes.review),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SkillShortcuts(
          summary: summary,
          focusSkills: onboarding.skills,
          today: today,
          onOpen: (skill) => context.go(AppRoutes.practiceFor(skill)),
          onViewAll: () => context.go(AppRoutes.practice),
        ),
        const SizedBox(height: AppSpacing.lg),
        WeeklyActivityCard(week: week),
      ],
    );
  }

  static String _greetingLine(HomeSummary summary, int dailyGoal) {
    if (summary.totalXp == 0 && summary.minutesToday == 0) {
      return "Let's take your first step today.";
    }
    final left = dailyGoal - summary.minutesToday;
    if (left <= 0) return 'Daily goal done. Nice work!';
    if (summary.minutesToday == 0) {
      return 'Ready for your $dailyGoal-minute session?';
    }
    return '$left min left to reach today\'s goal.';
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.target,
    required this.line,
  });

  /// Null for a guest.
  final String? name;
  final TargetBand? target;
  final String line;

  @override
  Widget build(BuildContext context) {
    final firstName = name?.trim().split(RegExp(r'\s+')).first;
    final goal = target?.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  firstName == null || firstName.isEmpty
                      ? 'Hi there'
                      : 'Hi, $firstName',
                  style: AppTextStyles.headlineLg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                line,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (goal != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: GoalChip(value: goal),
          ),
        ],
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _listPadding,
      children: [
        InfoBanner(
          type: InfoBannerType.error,
          title: "Couldn't load your dashboard",
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      ],
    );
  }
}
