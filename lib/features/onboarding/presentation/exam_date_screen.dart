import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_controller.dart';
import 'onboarding_navigation.dart';
import 'plan_editing.dart';
import 'widgets/month_calendar.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 2: exam date, or "not booked yet".
class ExamDateScreen extends ConsumerWidget {
  const ExamDateScreen({super.key, this.editing = false});

  /// Editing the plan from the Profile (see [OnboardingScaffold.editing]).
  final bool editing;

  static const _step = OnboardingStep.examDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = watchPlan(ref, editing: editing);
    final controller = planEditor(ref, editing: editing);
    final today = ref.watch(todayProvider);
    final date = state.examDate;
    final notBooked = state.examNotBooked;
    final valid = date != null || notBooked;

    return OnboardingScaffold(
      step: _step,
      editing: editing,
      title: 'When is your IELTS exam?',
      subtitle: "We'll pace your weekly plan around your test day.",
      onContinue: !valid
          ? null
          : editing
          ? () => savePlanEdit(context, ref)
          : () => goToOnboardingStep(context, ref, _step.next!),
      children: [
        Opacity(
          opacity: notBooked ? 0.4 : 1,
          child: IgnorePointer(
            ignoring: notBooked,
            child: ExcludeSemantics(
              excluding: notBooked,
              child: AppCard(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: MonthCalendar(
                  today: today,
                  selected: date,
                  onSelected: controller.setExamDate,
                ),
              ),
            ),
          ),
        ),
        if (date != null && !notBooked) ...[
          const SizedBox(height: AppSpacing.smd),
          Semantics(
            liveRegion: true,
            child: InfoBanner(
              type: InfoBannerType.success,
              icon: Icons.event_available_rounded,
              title: '${_capitalize(timeUntilLabel(today, date))} to prepare',
              message: 'Exam on ${formatLongDate(date)}.',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.smd),
        SwitchCard(
          title: "I haven't booked my exam yet",
          subtitle: notBooked ? 'You can add a date later in your plan.' : null,
          value: notBooked,
          onChanged: controller.setExamNotBooked,
        ),
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
