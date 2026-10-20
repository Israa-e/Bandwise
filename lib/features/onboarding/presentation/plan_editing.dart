import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/skill.dart';
import '../../../core/utils/dates.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_controller.dart';

/// Changes to the study plan made on an onboarding step screen. During
/// onboarding they are saved as they happen; when editing the plan from
/// the Profile, they go to a draft that is saved only on Save.
abstract interface class PlanEditor {
  Future<void> setTargetBand(TargetBand band);
  Future<void> setExamDate(DateTime date);
  Future<void> setExamNotBooked(bool notBooked);
  Future<void> setDailyMinutes(int minutes);
  Future<void> setReminderEnabled(bool enabled);
  Future<void> setReminderTime(ReminderTime time);
  Future<void> toggleSkill(Skill skill);
}

/// The plan being edited from the Profile. Starts from the saved answers
/// and is discarded when the edit screen closes without saving.
final planDraftProvider =
    NotifierProvider.autoDispose<PlanDraftController, OnboardingState>(
      PlanDraftController.new,
    );

class PlanDraftController extends Notifier<OnboardingState>
    implements PlanEditor {
  @override
  OnboardingState build() =>
      ref.read(onboardingControllerProvider).requireValue;

  void _update(OnboardingState Function(OnboardingState) change) =>
      state = change(state);

  @override
  Future<void> setTargetBand(TargetBand band) async =>
      _update((s) => s.copyWith(targetBand: () => band));

  @override
  Future<void> setExamDate(DateTime date) async =>
      _update((s) => s.copyWith(examDate: () => dateOnly(date)));

  @override
  Future<void> setExamNotBooked(bool notBooked) async =>
      _update((s) => s.copyWith(examNotBooked: notBooked));

  @override
  Future<void> setDailyMinutes(int minutes) async =>
      _update((s) => s.copyWith(dailyMinutes: () => minutes));

  @override
  Future<void> setReminderEnabled(bool enabled) async => _update(
    (s) => s.copyWith(
      reminderEnabled: enabled,
      reminderTime: () =>
          s.reminderTime ??
          (enabled ? OnboardingState.defaultReminderTime : null),
    ),
  );

  @override
  Future<void> setReminderTime(ReminderTime time) async =>
      _update((s) => s.copyWith(reminderTime: () => time));

  @override
  Future<void> toggleSkill(Skill skill) async => _update((s) {
    final skills = {...s.skills};
    if (!skills.remove(skill)) skills.add(skill);
    return s.copyWith(skills: skills);
  });
}

/// The plan a step screen shows: the saved answers, or the draft when
/// [editing].
OnboardingState watchPlan(WidgetRef ref, {required bool editing}) => editing
    ? ref.watch(planDraftProvider)
    : ref.watch(onboardingControllerProvider).requireValue;

/// Where a step screen's changes go.
PlanEditor planEditor(WidgetRef ref, {required bool editing}) => editing
    ? ref.read(planDraftProvider.notifier)
    : ref.read(onboardingControllerProvider.notifier);

/// Saves the draft plan and closes the edit screen.
Future<void> savePlanEdit(BuildContext context, WidgetRef ref) async {
  await ref
      .read(onboardingControllerProvider.notifier)
      .savePlan(ref.read(planDraftProvider));
  if (context.mounted) context.pop();
}
