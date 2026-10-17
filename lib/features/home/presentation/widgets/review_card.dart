import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// "Up next for review": saved mistakes and vocabulary due today.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.mistakesDue,
    required this.wordsDue,
    required this.onOpen,
  });

  final int mistakesDue;
  final int wordsDue;
  final VoidCallback onOpen;

  /// "3 saved mistakes", "1 vocabulary card due" or "2 mistakes · 5 words".
  static String dueLabel(int mistakes, int words) {
    String plural(int n, String one, String many) => n == 1 ? one : many;
    if (words == 0) {
      return plural(mistakes, '1 saved mistake', '$mistakes saved mistakes');
    }
    if (mistakes == 0) {
      return plural(
        words,
        '1 vocabulary card due',
        '$words vocabulary cards due',
      );
    }
    return '${plural(mistakes, '1 mistake', '$mistakes mistakes')} · '
        '${plural(words, '1 word', '$words words')}';
  }

  @override
  Widget build(BuildContext context) {
    final due = dueLabel(mistakesDue, wordsDue);
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
