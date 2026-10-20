import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_navigation.dart';
import 'plan_editing.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 1: the user's target band. No Skip: "Not sure yet" covers it.
class TargetBandScreen extends ConsumerWidget {
  const TargetBandScreen({super.key, this.editing = false});

  /// Editing the plan from the Profile (see [OnboardingScaffold.editing]).
  final bool editing;

  static const _step = OnboardingStep.targetBand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = watchPlan(ref, editing: editing).targetBand;
    final controller = planEditor(ref, editing: editing);

    return OnboardingScaffold(
      step: _step,
      editing: editing,
      canSkip: false,
      title: "What's your target band score?",
      note: 'This is your goal, not a guaranteed result.',
      onContinue: selected == null
          ? null
          : editing
          ? () => savePlanEdit(context, ref)
          : () => goToOnboardingStep(context, ref, _step.next!),
      children: [
        for (final band in TargetBand.values) ...[
          _BandCard(
            band: band,
            selected: band == selected,
            onTap: () => controller.setTargetBand(band),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
      ],
    );
  }
}

class _BandCard extends StatelessWidget {
  const _BandCard({
    required this.band,
    required this.selected,
    required this.onTap,
  });

  final TargetBand band;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = band.value;
    return SelectionCard(
      title: band.descriptor,
      subtitle: switch (band) {
        TargetBand.band7 => 'Common for postgraduate study',
        TargetBand.notSure => "We'll suggest one after your placement check",
        _ => null,
      },
      badge: band == TargetBand.band7
          ? const AppPill(
              label: 'Popular',
              size: AppPillSize.small,
              background: AppColors.accent,
              foreground: AppColors.onAccent,
            )
          : null,
      leading: SelectionLeadingBox(
        text: value,
        icon: value == null ? Icons.help_outline_rounded : null,
        color: selected ? AppColors.onPrimary : AppColors.primary,
        background: selected ? AppColors.primary : AppColors.primaryTint,
      ),
      state: selected ? SelectionCardState.selected : SelectionCardState.idle,
      onTap: onTap,
    );
  }
}
