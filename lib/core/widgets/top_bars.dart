import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'progress.dart';

const _barHeight = 64.0;

/// Circular back button. The arrow icon mirrors automatically in RTL.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Go back',
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        highlightColor: AppColors.primaryTint,
      ),
    );
  }
}

/// Top bar for onboarding steps: back button, centered "Step X of Y" with a
/// segmented progress bar, and an optional trailing action (e.g. Skip).
class OnboardingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const OnboardingTopBar({
    super.key,
    required this.step,
    required this.totalSteps,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final bool showBack;

  /// Usually a ghost [AppButton] such as "Skip".
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: NavigationToolbar(
              leading: showBack ? AppBackButton(onPressed: onBack) : null,
              middle: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      'Step $step of $totalSteps',
                      style: AppTextStyles.tabular(AppTextStyles.labelMd),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedStepProgress(current: step, total: totalSteps),
                ],
              ),
              trailing: trailing,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for auth screens: back button and an optional trailing action
/// (e.g. "Log in" on the sign-up screen). No title; the screen has its own.
class AuthTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthTopBar({
    super.key,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (showBack) AppBackButton(onPressed: onBack),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
