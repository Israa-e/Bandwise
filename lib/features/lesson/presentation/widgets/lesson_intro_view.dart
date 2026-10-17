import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../learn/domain/course.dart';

/// What the lesson covers, before it starts.
class LessonIntroView extends StatelessWidget {
  const LessonIntroView({
    super.key,
    required this.unit,
    required this.lesson,
    required this.completedBefore,
  });

  final Unit unit;
  final Lesson lesson;
  final bool completedBefore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppPill(
            label: 'Unit ${unit.number} · ${lesson.label}',
            background: AppColors.primaryTint,
            foreground: AppColors.primary,
            size: AppPillSize.small,
          ),
        ),
        const SizedBox(height: AppSpacing.smd),
        Semantics(
          header: true,
          child: Text(lesson.title, style: AppTextStyles.headlineXl),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          lesson.objective,
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppPill(
              label: '${lesson.estimatedMinutes} min',
              icon: Icons.schedule_rounded,
              background: AppColors.card,
              foreground: AppColors.text,
              iconColor: AppColors.primary,
            ),
            AppPill(
              label: '${lesson.exercises.length} exercises',
              icon: Icons.checklist_rounded,
              background: AppColors.card,
              foreground: AppColors.text,
              iconColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You will learn', style: AppTextStyles.headlineSm),
              const SizedBox(height: AppSpacing.smd),
              for (final item in lesson.learnItems)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsetsDirectional.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(item, style: AppTextStyles.bodyMd)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (completedBefore) ...[
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            type: InfoBannerType.success,
            message:
                "You've completed this lesson. Practise it again to earn more "
                'XP.',
          ),
        ],
      ],
    );
  }
}
