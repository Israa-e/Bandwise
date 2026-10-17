import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../progress/domain/review_schedule.dart';

/// Again / Hard / Good / Easy, each with when the item will come back.
class ReviewRatingBar extends StatelessWidget {
  const ReviewRatingBar({
    super.key,
    required this.schedule,
    required this.onRate,
    this.enabled = true,
  });

  /// The item's current schedule (null if never reviewed), used to show
  /// the next interval for each rating.
  final ReviewSchedule? schedule;
  final ValueChanged<ReviewRating> onRate;
  final bool enabled;

  static String hintFor(ReviewSchedule? schedule, ReviewRating rating) {
    if (rating == ReviewRating.again) return 'Soon';
    // Intervals don't depend on the date, so any day works here.
    final days = ReviewSchedule.next(
      schedule,
      rating,
      DateTime(2000),
    ).intervalDays;
    return days == 1 ? '1 day' : '$days days';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How well did you remember it?',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final rating in ReviewRating.values) ...[
              if (rating.index > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RatingButton(
                  rating: rating,
                  hint: hintFor(schedule, rating),
                  onTap: enabled ? () => onRate(rating) : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.hint,
    required this.onTap,
  });

  final ReviewRating rating;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (rating) {
      ReviewRating.again => AppColors.errorText,
      ReviewRating.hard || ReviewRating.good => AppColors.text,
      ReviewRating.easy => AppColors.primary,
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '${rating.label}, next review ${hint.toLowerCase()}',
      excludeSemantics: true,
      // White with a border, so the tiles stand out on the green and red
      // feedback panels too.
      child: Material(
        color: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.buttonRadius,
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      rating.label,
                      style: AppTextStyles.labelLg.copyWith(color: foreground),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hint,
                      style: AppTextStyles.tabular(
                        AppTextStyles.labelSm,
                      ).copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
