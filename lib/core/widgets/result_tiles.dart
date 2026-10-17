import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';
import 'progress.dart';

/// A success icon in a circle that scales in once. Static when the
/// platform asks for reduced motion.
class SuccessBadge extends StatelessWidget {
  const SuccessBadge({
    super.key,
    this.icon = Icons.check_rounded,
    this.semanticLabel = 'Completed',
  });

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox.square(
      dimension: 72,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.successTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: AppColors.success),
      ),
    );
    final semantic = Semantics(label: semanticLabel, child: badge);
    if (MediaQuery.disableAnimationsOf(context)) return semantic;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: semantic,
    );
  }
}

/// A results stat: label, big value and caption, e.g. "XP earned +12 XP".
/// Sized by its parent; use in an [IntrinsicHeight] row of equal tiles.
class ResultStatTile extends StatelessWidget {
  const ResultStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value $caption',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.tabular(
                  AppTextStyles.headlineMd,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              caption,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Today's study minutes against the daily goal, as a small ring.
class DailyGoalTile extends StatelessWidget {
  const DailyGoalTile({super.key, required this.minutes, required this.goal});

  final int minutes;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily goal: $minutes of $goal minutes',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          children: [
            Text(
              'Daily goal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppCircularProgress(
              value: goal == 0 ? 0 : minutes / goal,
              size: 48,
              strokeWidth: 5,
              center: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
                child: FittedBox(
                  child: Text(
                    '$minutes/${goal}m',
                    key: const ValueKey('goalMinutes'),
                    style: AppTextStyles.tabular(AppTextStyles.labelMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
