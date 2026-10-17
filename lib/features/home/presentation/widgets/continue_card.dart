import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../onboarding/domain/placement.dart';
import '../../domain/home_summary.dart';

/// Used when the first lesson's details aren't available (mock data).
const _fallbackMinutes = 8;

/// "Continue learning": the next lesson on the path, or the recommended
/// starting unit for a learner who hasn't finished a lesson yet.
class ContinueCard extends StatelessWidget {
  const ContinueCard.next({
    super.key,
    required NextLesson this.lesson,
    required this.onOpen,
  }) : start = null;

  /// [lesson] is the first lesson of [start], when known.
  const ContinueCard.start({
    super.key,
    required StartingPoint this.start,
    this.lesson,
    required this.onOpen,
  });

  final NextLesson? lesson;

  /// Set for a learner who hasn't finished a lesson yet.
  final StartingPoint? start;

  /// Opens the lesson. Receives the lesson id.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final lesson = this.lesson;
    final start = this.start;
    final (tag, tagIcon, title) = start == null
        ? ('Unit ${lesson!.unit} · ${lesson.unitTitle}', null, lesson.title)
        : ('Recommended start', Icons.flag_rounded, start.title);
    final minutes = lesson?.estimatedMinutes ?? _fallbackMinutes;
    final id = lesson?.id ?? 'u${start!.unit}-l1';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppPill(
                    label: tag,
                    icon: tagIcon,
                    background: AppColors.primaryTint,
                    foreground: AppColors.primary,
                    size: AppPillSize.small,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadii.nestedRadius,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: AppColors.onAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smd),
          Text(title, style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          if (start == null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    lesson!.label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  '${(lesson.unitProgress * 100).round()}% of unit',
                  style: AppTextStyles.tabular(
                    AppTextStyles.labelMd,
                  ).copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppLinearProgress(
              value: lesson.unitProgress,
              semanticLabel: 'Unit progress',
            ),
          ] else
            Text(
              lesson == null
                  ? 'Lesson 1 · Not started'
                  : 'Lesson 1 · ${lesson.title}',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
          const SizedBox(height: AppSpacing.md),
          // The button moves under the estimate when both don't fit.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.smd,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Est. $minutes min',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                AppButton.primary(
                  label: 'Start lesson',
                  trailingIcon: Icons.arrow_forward_rounded,
                  compact: true,
                  expand: false,
                  onPressed: () => onOpen(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
