import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_controller.dart';
import 'onboarding_navigation.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 5: skills to focus on (one or more).
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  static const _step = OnboardingStep.skills;

  static const _descriptions = {
    Skill.listening: 'Sections 1–4, note-taking',
    Skill.reading: 'Skimming, True/False/Not Given',
    Skill.writing: 'Task 1 charts & Task 2 essays',
    Skill.speaking: 'Fluency, vocabulary & pronunciation',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.requireValue.skills),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    Widget tile(Skill skill) => SelectionCard(
      mode: SelectionMode.multi,
      layout: SelectionCardLayout.tile,
      title: skill.label,
      subtitle: _descriptions[skill],
      leading: SelectionLeadingBox(
        icon: skill.icon,
        color: skill.color,
        background: skill.tint,
        circle: true,
      ),
      state: selected.contains(skill)
          ? SelectionCardState.selected
          : SelectionCardState.idle,
      onTap: () => controller.toggleSkill(skill),
    );

    return OnboardingScaffold(
      step: _step,
      title: 'Which skills need the most focus?',
      subtitle: 'Pick one or more.',
      onContinue: selected.isEmpty
          ? null
          : () => goToOnboardingStep(context, ref, _step.next!),
      children: [
        for (var row = 0; row < Skill.values.length; row += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(Skill.values[row])),
                const SizedBox(width: AppSpacing.smd),
                Expanded(child: tile(Skill.values[row + 1])),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        const SizedBox(height: AppSpacing.xs),
        const InfoBanner(
          icon: Icons.tune_rounded,
          message: 'You can change these anytime in your study plan.',
        ),
      ],
    );
  }
}
