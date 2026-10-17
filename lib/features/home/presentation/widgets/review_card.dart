import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// "Up next for review": mistakes saved from lessons.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.dueCount, required this.onOpen});

  final int dueCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final due = dueCount == 1 ? '1 saved mistake' : '$dueCount saved mistakes';
    return AppCard(
      onTap: onOpen,
      semanticLabel: 'Up next for review: $due',
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: AppRadii.nestedRadius,
              ),
              child: const Icon(
                Icons.style_rounded,
                size: 20,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UP NEXT FOR REVIEW',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(due, style: AppTextStyles.labelLg),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
