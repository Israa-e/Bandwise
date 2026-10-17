import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../onboarding/domain/placement.dart';
import '../../domain/home_summary.dart';

/// Estimated length of a unit's first lesson, until lesson data exists.
const _firstLessonMinutes = 10;

/// "Continue learning": the lesson in progress, or the recommended starting
/// unit for a learner who hasn't started yet.
class ContinueCard extends StatelessWidget {
  const ContinueCard.resume({
    super.key,
    required LessonProgress this.lesson,
    required this.onOpen,
  }) : start = null;

  const ContinueCard.start({
    super.key,
    required StartingPoint this.start,
    required this.onOpen,
  }) : lesson = null;

  final LessonProgress? lesson;
  final StartingPoint? start;

  /// Opens the lesson. Receives the lesson id.
  final ValueChanged<String> onOpen;

  /// Lesson id for the first lesson of [StartingPoint.unit].
  static String firstLessonId(StartingPoint start) => 'u${start.unit}-l1';

  @override
  Widget build(BuildContext context) {
    final lesson = this.lesson;
    final start = this.start;
    final (tag, tagIcon, title, minutes) = lesson != null
        ? (
            'Unit ${lesson.unit} · ${lesson.unitTitle}',
            null,
            lesson.title,
            lesson.estimatedMinutes,
          )
        : (
            'Recommended start',
            Icons.flag_rounded,
            start!.title,
            _firstLessonMinutes,
          );
    final id = lesson?.id ?? firstLessonId(start!);

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
          if (lesson != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lesson ${lesson.lessonNumber} of ${lesson.lessonCount}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(
                  '${(lesson.progress * 100).round()}% complete',
                  style: AppTextStyles.tabular(
                    AppTextStyles.labelMd,
                  ).copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppLinearProgress(
              value: lesson.progress,
              semanticLabel: 'Lesson progress',
            ),
          ] else
            Text(
              'Lesson 1 · Not started',
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
                  label: lesson != null ? 'Resume lesson' : 'Start lesson',
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
