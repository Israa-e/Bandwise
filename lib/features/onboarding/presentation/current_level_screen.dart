import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_controller.dart';
import 'onboarding_navigation.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 3: self-assessed English level.
class CurrentLevelScreen extends ConsumerWidget {
  const CurrentLevelScreen({super.key});

  static const _step = OnboardingStep.currentLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.requireValue.level),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingScaffold(
      step: _step,
      title: 'What feels closest to your current English level?',
      note: 'A self-assessment, not an official CEFR level.',
      onContinue: selected == null
          ? null
          : () => goToOnboardingStep(context, ref, _step.next!),
      children: [
        for (final level in EnglishLevel.values) ...[
          SelectionCard(
            title: level.label,
            subtitle: level.description,
            state: level == selected
                ? SelectionCardState.selected
                : SelectionCardState.idle,
            onTap: () => controller.setLevel(level),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
      ],
    );
  }
}
