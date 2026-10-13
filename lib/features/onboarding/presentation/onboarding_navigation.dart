import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_controller.dart';

/// URL path for each onboarding screen.
String onboardingPath(OnboardingStep step) => switch (step) {
  OnboardingStep.welcome => AppRoutes.welcome,
  OnboardingStep.targetBand => '${AppRoutes.onboarding}/target-band',
  OnboardingStep.examDate => '${AppRoutes.onboarding}/exam-date',
  OnboardingStep.currentLevel => '${AppRoutes.onboarding}/level',
  OnboardingStep.dailyTime => '${AppRoutes.onboarding}/daily-time',
  OnboardingStep.skills => '${AppRoutes.onboarding}/skills',
  OnboardingStep.placement => '${AppRoutes.onboarding}/placement',
  OnboardingStep.plan => '${AppRoutes.onboarding}/plan',
};

/// Saves [step] as the resume point, then shows it.
///
/// Uses `go` rather than `push`, so back navigation is explicit (the previous
/// step) and works the same after a restart.
Future<void> goToOnboardingStep(
  BuildContext context,
  WidgetRef ref,
  OnboardingStep step,
) async {
  await ref.read(onboardingControllerProvider.notifier).goTo(step);
  if (context.mounted) context.go(onboardingPath(step));
}
