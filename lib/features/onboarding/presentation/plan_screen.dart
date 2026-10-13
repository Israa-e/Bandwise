import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/skill.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import '../domain/placement.dart';
import 'onboarding_controller.dart';
import 'onboarding_navigation.dart';

/// Summary of the onboarding answers and a recommended starting point.
///
/// Shows the target as its descriptor only: the study plan never shows a
/// band number.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static const _activeDays = 7;

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
  ) async {
    if (state.isGuest) {
      await ref.read(onboardingControllerProvider.notifier).complete();
      if (context.mounted) context.go(AppRoutes.home);
    } else {
      // Onboarding completes once the account exists (see CreateAccount).
      context.push(AppRoutes.createAccount);
    }
  }

  void _back(BuildContext context, WidgetRef ref) =>
      goToOnboardingStep(context, ref, OnboardingStep.placement);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider).requireValue;
    final today = ref.watch(todayProvider);
    final questions = ref.watch(placementQuestionsProvider);
    final minutes = state.dailyMinutes ?? OnboardingState.defaultDailyMinutes;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context, ref);
      },
      child: Scaffold(
        appBar: AuthTopBar(onBack: () => _back(context, ref)),
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.xs,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppPill(
                label: 'Plan ready',
                icon: Icons.check_circle_rounded,
                background: AppColors.accent,
                foreground: AppColors.onAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.smd),
            Semantics(
              header: true,
              child: const Text(
                'Your study plan is ready',
                style: AppTextStyles.headlineLg,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Built from your goal, schedule and exam date.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            _StartingPointCard(state: state, questions: questions),
            const SizedBox(height: AppSpacing.md),
            _OverviewCard(state: state, today: today),
            const SizedBox(height: AppSpacing.md),
            _WeeklyRoutineCard(minutes: minutes, activeDays: _activeDays),
          ],
        ),
        bottomNavigationBar: StickyActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton.primary(
                label: 'Start learning',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => _start(context, ref, state),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: AppButton.ghost(
                  label: 'Adjust plan',
                  onPressed: () => goToOnboardingStep(
                    context,
                    ref,
                    OnboardingStep.targetBand,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartingPointCard extends StatelessWidget {
  const _StartingPointCard({required this.state, required this.questions});

  final OnboardingState state;
  final AsyncValue<List<PlacementQuestion>> questions;

  @override
  Widget build(BuildContext context) {
    final answeredPlacement =
        !state.placementSkipped && state.placementAnswers.isNotEmpty;
    // After a restart the questions reload; wait for them before scoring.
    final loading = answeredPlacement && !questions.hasValue;
    final list = questions.value ?? const <PlacementQuestion>[];
    final point = StartingPoint.recommend(
      correctAnswers: placementScore(state, list),
      totalQuestions: list.length,
      selfAssessed: state.level,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'RECOMMENDED STARTING POINT',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading)
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else ...[
            Text(point.title, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              point.reason,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.state, required this.today});

  final OnboardingState state;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final examDate = state.examDate;
    final weeksLeft = examDate == null ? null : timeUntilLabel(today, examDate);

    final target = state.targetBand;
    final goal = _Metric(
      label: 'Target goal',
      icon: Icons.emoji_events_outlined,
      value: target == null || target == TargetBand.notSure
          ? 'Not sure yet'
          : target.descriptor,
      detail: target == null || target == TargetBand.notSure
          ? "We'll help you set one"
          : 'Your goal, not a prediction',
    );

    final exam = _Metric(
      label: 'Exam date',
      icon: Icons.calendar_today_rounded,
      value: examDate != null
          ? formatMediumDate(examDate)
          : (state.examNotBooked ? 'Not booked yet' : 'Not set'),
      detail: weeksLeft != null ? '$weeksLeft left' : 'Add a date anytime',
    );

    final reminder = state.reminderEnabled && state.reminderTime != null
        ? MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(
              hour: state.reminderTime!.hour,
              minute: state.reminderTime!.minute,
            ),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          )
        : null;
    final commitment = _Metric(
      label: 'Commitment',
      icon: Icons.schedule_rounded,
      value: state.dailyMinutes != null
          ? '${state.dailyMinutes} min / day'
          : 'Not set',
      detail: state.dailyMinutes == null
          ? '${OnboardingState.defaultDailyMinutes} min suggested'
          : (reminder != null ? '$reminder reminder' : 'No reminder'),
    );

    final skills = state.skills.isEmpty
        ? null
        : Skill.values.where(state.skills.contains).toList();
    final focus = _Metric(
      label: 'Priority focus',
      icon: Icons.track_changes_rounded,
      value: skills == null
          ? 'All skills'
          : skills.map((s) => s.label).join(', '),
      detail: skills == null ? 'Balanced practice' : null,
    );

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

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Plan overview', style: AppTextStyles.headlineSm),
              ),
              if (weeksLeft != null)
                AppPill(
                  label: '$weeksLeft to go',
                  size: AppPillSize.small,
                  background: AppColors.primaryTint,
                  foreground: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smd),
          pair(goal, exam),
          const SizedBox(height: AppSpacing.sm),
          pair(commitment, focus),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.icon,
    required this.value,
    this.detail,
  });

  final String label;
  final IconData icon;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadii.nestedRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: AppTextStyles.labelLg),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(
                detail!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklyRoutineCard extends StatelessWidget {
  const _WeeklyRoutineCard({required this.minutes, required this.activeDays});

  final int minutes;
  final int activeDays;

  // Monday-first. 2024-01-01 was a Monday.
  static final _days = [
    for (var d = 0; d < 7; d++) DateFormat.E().format(DateTime(2024, 1, 1 + d)),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Weekly routine', style: AppTextStyles.headlineSm),
              ),
              AppPill(
                label: '$activeDays days / week',
                size: AppPillSize.small,
                background: AppColors.accent,
                foreground: AppColors.onAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Short sessions every day, with reviews built in.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.smd),
          Semantics(
            label: '$minutes minutes on each of $activeDays days',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var d = 0; d < _days.length; d++) ...[
                  if (d > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _DayChip(
                      day: _days[d],
                      minutes: d < activeDays ? minutes : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.minutes});

  final String day;

  /// Null on a rest day.
  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final active = minutes != null;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: active ? AppColors.selectedSurface : AppColors.background,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Column(
        children: [
          Text(day, style: AppTextStyles.labelSm.copyWith(letterSpacing: 0)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.track,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            active ? '${minutes}m' : '—',
            style: AppTextStyles.tabular(
              AppTextStyles.labelSm,
            ).copyWith(color: AppColors.textMuted, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
