import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/skill.dart';
import '../../../core/utils/dates.dart';
import '../data/mock_placement_repository.dart';
import '../data/prefs_onboarding_repository.dart';
import '../domain/onboarding_repository.dart';
import '../domain/onboarding_state.dart';
import '../domain/placement.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => PrefsOnboardingRepository(),
);

final placementRepositoryProvider = Provider<PlacementRepository>(
  (ref) => const MockPlacementRepository(),
);

final placementQuestionsProvider = FutureProvider<List<PlacementQuestion>>(
  (ref) => ref.watch(placementRepositoryProvider).fetchQuestions(),
);

/// Today's date (local, no time). Overridable in tests.
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

/// Holds onboarding answers and persists every change.
///
/// Loaded once at startup (the splash screen waits for it); after that,
/// screens can read `requireValue`.
class OnboardingController extends AsyncNotifier<OnboardingState> {
  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);

  @override
  Future<OnboardingState> build() async {
    final saved = await _repository.load();
    // A saved exam date may have passed since the user last opened the app.
    final today = ref.read(todayProvider);
    final examDate = saved.examDate;
    if (examDate != null && examDate.isBefore(today)) {
      return saved.copyWith(examDate: () => null);
    }
    return saved;
  }

  OnboardingState get _current => state.requireValue;

  Future<void> _update(OnboardingState Function(OnboardingState) change) async {
    final next = change(_current);
    state = AsyncData(next);
    await _repository.save(next);
  }

  Future<void> goTo(OnboardingStep step) =>
      _update((s) => s.copyWith(step: step));

  Future<void> start({required bool asGuest}) => _update(
    (s) => s.copyWith(isGuest: asGuest, step: OnboardingStep.targetBand),
  );

  Future<void> setTargetBand(TargetBand band) =>
      _update((s) => s.copyWith(targetBand: () => band));

  Future<void> setExamDate(DateTime date) =>
      _update((s) => s.copyWith(examDate: () => dateOnly(date)));

  Future<void> setExamNotBooked(bool notBooked) =>
      _update((s) => s.copyWith(examNotBooked: notBooked));

  Future<void> setLevel(EnglishLevel level) =>
      _update((s) => s.copyWith(level: () => level));

  Future<void> setDailyMinutes(int minutes) =>
      _update((s) => s.copyWith(dailyMinutes: () => minutes));

  Future<void> setReminderEnabled(bool enabled) => _update(
    (s) => s.copyWith(
      reminderEnabled: enabled,
      reminderTime: () =>
          s.reminderTime ??
          (enabled ? OnboardingState.defaultReminderTime : null),
    ),
  );

  Future<void> setReminderTime(ReminderTime time) =>
      _update((s) => s.copyWith(reminderTime: () => time));

  Future<void> toggleSkill(Skill skill) => _update((s) {
    final skills = {...s.skills};
    if (!skills.remove(skill)) skills.add(skill);
    return s.copyWith(skills: skills);
  });

  /// Clears the answer for [step] and moves to the next step.
  Future<void> skip(OnboardingStep step) => _update((s) {
    final cleared = switch (step) {
      OnboardingStep.examDate => s.copyWith(
        examDate: () => null,
        examNotBooked: false,
      ),
      OnboardingStep.currentLevel => s.copyWith(level: () => null),
      OnboardingStep.dailyTime => s.copyWith(
        dailyMinutes: () => null,
        reminderEnabled: false,
        reminderTime: () => null,
      ),
      OnboardingStep.skills => s.copyWith(skills: const {}),
      OnboardingStep.placement => s.copyWith(
        placementSkipped: true,
        placementAnswers: const {},
        placementIndex: 0,
      ),
      // Target band has "Not sure yet" instead of Skip.
      OnboardingStep.welcome ||
      OnboardingStep.targetBand ||
      OnboardingStep.plan => s,
    };
    return cleared.copyWith(step: step.next ?? step);
  });

  Future<void> answerPlacement(int questionIndex, int optionIndex) => _update(
    (s) => s.copyWith(
      placementSkipped: false,
      placementAnswers: {...s.placementAnswers, questionIndex: optionIndex},
    ),
  );

  Future<void> showPlacementQuestion(int index) =>
      _update((s) => s.copyWith(placementIndex: index));

  /// Ends onboarding; the app opens on Home from now on.
  Future<void> complete() =>
      _update((s) => s.copyWith(completed: true, step: OnboardingStep.plan));

  /// Debug helper: forget all answers.
  Future<void> reset() async {
    await _repository.clear();
    state = const AsyncData(OnboardingState());
  }
}

/// Number of correct placement answers, or null if placement was skipped or
/// not finished.
int? placementScore(OnboardingState state, List<PlacementQuestion> questions) {
  if (state.placementSkipped || questions.isEmpty) return null;
  if (state.placementAnswers.length < questions.length) return null;
  var correct = 0;
  for (var i = 0; i < questions.length; i++) {
    if (state.placementAnswers[i] == questions[i].correctIndex) correct++;
  }
  return correct;
}
