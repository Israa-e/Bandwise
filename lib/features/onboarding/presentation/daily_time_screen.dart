import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_navigation.dart';
import 'plan_editing.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 4: daily study time and an optional reminder.
///
/// Only stores the reminder time; notification permission is requested
/// later, when reminders are actually scheduled.
class DailyTimeScreen extends ConsumerWidget {
  const DailyTimeScreen({super.key, this.editing = false});

  /// Editing the plan from the Profile (see [OnboardingScaffold.editing]).
  final bool editing;

  static const _step = OnboardingStep.dailyTime;

  static const _subtitles = {
    10: 'Casual sprint',
    15: 'Steady habit',
    20: 'A good balance for most learners',
    30: 'Intensive prep',
    45: 'Fast-track focus',
  };

  Future<void> _pickTime(
    BuildContext context,
    PlanEditor controller,
    ReminderTime current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Daily reminder time',
    );
    if (picked != null) {
      await controller.setReminderTime(
        ReminderTime(picked.hour, picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = watchPlan(ref, editing: editing);
    final controller = planEditor(ref, editing: editing);
    // Defaults to 20 minutes, so the step is valid from the start. It is only
    // null after a Skip; coming back shows the default again.
    final minutes = state.dailyMinutes ?? OnboardingState.defaultDailyMinutes;
    final reminderTime =
        state.reminderTime ?? OnboardingState.defaultReminderTime;

    return OnboardingScaffold(
      step: _step,
      editing: editing,
      title: 'How much daily practice works for you?',
      subtitle: 'Small, regular sessions are easier to keep up.',
      onContinue: () async {
        if (state.dailyMinutes == null) {
          await controller.setDailyMinutes(minutes);
        }
        if (!context.mounted) return;
        if (editing) {
          await savePlanEdit(context, ref);
        } else {
          await goToOnboardingStep(context, ref, _step.next!);
        }
      },
      children: [
        for (final option in OnboardingState.dailyMinuteOptions) ...[
          SelectionCard(
            title: '$option min / day',
            subtitle: _subtitles[option],
            badge: option == OnboardingState.defaultDailyMinutes
                ? const AppPill(
                    label: 'Recommended',
                    size: AppPillSize.small,
                    background: AppColors.accent,
                    foreground: AppColors.onAccent,
                  )
                : null,
            state: option == minutes
                ? SelectionCardState.selected
                : SelectionCardState.idle,
            onTap: () => controller.setDailyMinutes(option),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        const SizedBox(height: AppSpacing.xs),
        SwitchCard(
          title: 'Daily study reminder',
          subtitle: 'A nudge at the same time each day',
          value: state.reminderEnabled,
          onChanged: controller.setReminderEnabled,
          child: state.reminderEnabled
              ? _ReminderTimeRow(
                  time: reminderTime,
                  onChange: () => _pickTime(context, controller, reminderTime),
                )
              : null,
        ),
      ],
    );
  }
}

class _ReminderTimeRow extends StatelessWidget {
  const _ReminderTimeRow({required this.time, required this.onChange});

  final ReminderTime time;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.smd,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadii.nestedRadius,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                semanticsLabel: 'Reminder at $label',
                style: AppTextStyles.tabular(AppTextStyles.headlineSm),
              ),
            ),
            AppButton.ghost(
              label: 'Change time',
              compact: true,
              onPressed: onChange,
            ),
          ],
        ),
      ),
    );
  }
}
