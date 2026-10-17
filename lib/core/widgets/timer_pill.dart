import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "18:42" in tabular figures. Turns to the warning color from [warningAt].
/// Not animated.
class TimerPill extends StatelessWidget {
  const TimerPill({
    super.key,
    required this.remaining,
    this.warningAt = const Duration(minutes: 5),
  });

  final Duration remaining;

  /// From this much time left the pill turns to the warning color.
  final Duration warningAt;

  static String format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final warning = remaining <= warningAt;
    final text = format(remaining);
    return Semantics(
      label:
          'Time left: ${remaining.inMinutes} minutes '
          '${remaining.inSeconds % 60} seconds',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: warning ? AppColors.warningTint : AppColors.primaryTint,
          borderRadius: AppRadii.pillRadius,
          border: warning ? Border.all(color: AppColors.warning) : null,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.smd,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: warning ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                text,
                key: const ValueKey('timer'),
                style: AppTextStyles.tabular(
                  AppTextStyles.labelLg,
                ).copyWith(color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
