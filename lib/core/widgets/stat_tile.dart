import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// A summary number: an icon and label, the value with an optional unit,
/// and an optional footer line. Sized by its parent; use in an
/// [IntrinsicHeight] row of equal tiles.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.unit,
    this.footer,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// e.g. "days", after the value.
  final String? unit;

  /// e.g. "Longest: 5 days".
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: [
        '$label: $value${unit == null ? '' : ' $unit'}',
        ?footer,
      ].join('. '),
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                style: AppTextStyles.tabular(
                  AppTextStyles.headlineSm,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (footer != null) ...[
              const Spacer(),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                footer!,
                style: AppTextStyles.tabular(
                  AppTextStyles.labelSm,
                ).copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
