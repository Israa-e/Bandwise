import 'package:flutter/material.dart';

import '../models/skill.dart';
import '../theme/app_theme.dart';

/// Rounded pill used for badges, tags and status labels.
///
/// A label too long for the available width is cut with an ellipsis.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconColor,
    this.size = AppPillSize.medium,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  /// Defaults to [foreground].
  final Color? iconColor;
  final AppPillSize size;

  @override
  Widget build(BuildContext context) {
    final small = size == AppPillSize.small;
    return Container(
      height: small ? 22 : 30,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: small ? AppSpacing.sm : AppSpacing.smd,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 14 : 16, color: iconColor ?? foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (small ? AppTextStyles.labelSm : AppTextStyles.labelMd)
                  .copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

enum AppPillSize { small, medium }

/// Skill tag: the skill's icon in its color on its tint.
///
/// The label uses the text color rather than the skill color, because the
/// light skill colors don't meet text contrast on their tints.
class SkillChip extends StatelessWidget {
  const SkillChip({
    super.key,
    required this.skill,
    this.label,
    this.size = AppPillSize.medium,
  });

  final Skill skill;

  /// Defaults to the skill name. Use for e.g. "88% accuracy".
  final String? label;
  final AppPillSize size;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: label ?? skill.label,
      icon: skill.icon,
      iconColor: skill.color,
      background: skill.tint,
      foreground: AppColors.text,
      size: size,
    );
  }
}

/// Study streak counter on the lime accent.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.active = true});

  final int days;

  /// False when today's goal isn't done yet; renders a muted chip.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final label = days == 1 ? '1 day' : '$days days';
    return Semantics(
      label: '$label streak${active ? '' : ', not yet extended today'}',
      excludeSemantics: true,
      child: Container(
        height: 30,
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.sm,
          end: AppSpacing.smd,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.disabledFill,
          borderRadius: AppRadii.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: active ? AppColors.warning : AppColors.textDisabled,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: AppTextStyles.tabular(AppTextStyles.labelMd).copyWith(
                color: active ? AppColors.onAccent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
