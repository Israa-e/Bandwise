import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/onboarding_state.dart';
import '../onboarding_controller.dart';
import '../onboarding_navigation.dart';

/// Layout shared by numbered onboarding steps: top bar with back, "Step X of
/// 6" and optional Skip; a scrollable body; a sticky bottom button.
///
/// Back (top bar or system) goes to the previous step. Skip clears this
/// step's answer and moves on.
class OnboardingScaffold extends ConsumerWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.children,
    required this.onContinue,
    this.subtitle,
    this.note,
    this.canSkip = true,
    this.continueLabel = 'Continue',
    this.continueIcon = Icons.arrow_forward_rounded,
    this.header,
    this.onBack,
    this.bodyKey,
  });

  final OnboardingStep step;
  final String title;
  final String? subtitle;

  /// Small info line under the title, e.g. "Not an official CEFR level".
  final String? note;
  final List<Widget> children;

  /// Null disables the bottom button (step not valid yet).
  final VoidCallback? onContinue;
  final bool canSkip;
  final String continueLabel;
  final IconData? continueIcon;

  /// Optional widget above the title (e.g. question progress).
  final Widget? header;

  /// Overrides the default back behavior (go to the previous step).
  final VoidCallback? onBack;

  /// Changing this resets the body's scroll position (e.g. per question).
  final Key? bodyKey;

  void _back(BuildContext context, WidgetRef ref) {
    if (onBack != null) return onBack!();
    final previous = step.previous;
    if (previous != null) {
      goToOnboardingStep(context, ref, previous);
    } else {
      context.pop();
    }
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingControllerProvider.notifier).skip(step);
    final next = step.next;
    if (next != null && context.mounted) {
      context.go(onboardingPath(next));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context, ref);
      },
      child: Scaffold(
        appBar: OnboardingTopBar(
          step: step.number!,
          totalSteps: OnboardingStep.totalNumbered,
          onBack: () => _back(context, ref),
          trailing: canSkip
              ? AppButton.ghost(
                  label: 'Skip',
                  compact: true,
                  onPressed: () => _skip(context, ref),
                )
              : null,
        ),
        body: ListView(
          key: bodyKey,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.smd,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            ?header,
            OnboardingHeading(title: title, subtitle: subtitle, note: note),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
        bottomNavigationBar: StickyActionBar(
          child: AppButton.primary(
            label: continueLabel,
            trailingIcon: continueIcon,
            onPressed: onContinue,
          ),
        ),
      ),
    );
  }
}

/// Screen title with an optional subtitle and info note.
class OnboardingHeading extends StatelessWidget {
  const OnboardingHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.note,
  });

  final String title;
  final String? subtitle;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppTextStyles.headlineLg),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          ),
        ],
        if (note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  note!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
