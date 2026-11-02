import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../learn/domain/course.dart';
import '../../../progress/domain/progress_state.dart';

/// Lesson results: score, XP, the daily goal and saved mistakes. For a
/// checkpoint, also whether the unit is mastered, or which lessons to
/// review. Never a band.
class LessonCompleteView extends StatelessWidget {
  const LessonCompleteView({
    super.key,
    required this.lessonTitle,
    required this.completion,
    required this.minutesToday,
    required this.dailyGoal,
    this.isCheckpoint = false,
    this.reviewLessons = const [],
    this.onOpenLesson,
  });

  final String lessonTitle;
  final LessonCompletion completion;
  final int minutesToday;
  final int dailyGoal;
  final bool isCheckpoint;

  /// Checkpoint only: the lessons the mistakes came from, in path order.
  final List<Lesson> reviewLessons;
  final ValueChanged<Lesson>? onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final mistakes = completion.mistakes;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        const Center(child: SuccessBadge()),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            isCheckpoint ? 'Checkpoint complete' : 'Lesson complete',
            style: AppTextStyles.headlineLg,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          lessonTitle,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ResultStatTile(
                  key: const ValueKey('score'),
                  label: 'Score',
                  value:
                      '${completion.correctFirstTry}/${completion.questionCount}',
                  caption: 'correct',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  key: const ValueKey('xpEarned'),
                  label: 'XP earned',
                  value: '+${completion.xp}',
                  caption: 'XP',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DailyGoalTile(minutes: minutesToday, goal: dailyGoal),
              ),
            ],
          ),
        ),
        if (isCheckpoint) ...[
          const SizedBox(height: AppSpacing.lg),
          if (completion.correctFirstTry >= Lesson.masteryScore)
            InfoBanner(
              key: const ValueKey('mastered'),
              type: InfoBannerType.success,
              title: 'Mastered',
              message:
                  'You answered ${Lesson.masteryScore} or more of '
                  '${completion.questionCount} correctly. This unit is '
                  'marked as mastered.',
            )
          else ...[
            const Text(
              'Review these lessons',
              key: ValueKey('reviewLessons'),
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your mistakes came from these lessons. Score '
              '${Lesson.masteryScore}/${completion.questionCount} or more '
              'to master the unit.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            for (final lesson in reviewLessons) ...[
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                key: ValueKey('review-${lesson.id}'),
                onTap: onOpenLesson == null
                    ? null
                    : () => onOpenLesson!(lesson),
                semanticLabel: '${lesson.label}: ${lesson.title}. Open lesson',
                padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.label.toUpperCase(),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(lesson.title, style: AppTextStyles.bodyMd),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          mistakes.isEmpty ? 'No mistakes this time' : 'Mistakes to review',
          style: AppTextStyles.headlineSm,
        ),
        const SizedBox(height: AppSpacing.smd),
        if (mistakes.isEmpty)
          Text(
            'Every question was correct on the first try.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          )
        else
          for (final m in mistakes) ...[
            _MistakeCard(mistake: m),
            const SizedBox(height: AppSpacing.smd),
          ],
      ],
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.mistake});

  final SavedMistake mistake;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPill(
            label: 'Saved for review',
            icon: Icons.bookmark_rounded,
            background: AppColors.warningTint,
            foreground: AppColors.text,
            iconColor: AppColors.warning,
            size: AppPillSize.small,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(mistake.prompt, style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              text: 'Your answer: ',
              children: [
                TextSpan(
                  text: mistake.yourAnswer,
                  style: const TextStyle(
                    color: AppColors.errorText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text.rich(
            TextSpan(
              text: 'Correct answer: ',
              children: [
                TextSpan(
                  text: mistake.correctAnswer,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            style: AppTextStyles.bodySm,
          ),
        ],
      ),
    );
  }
}
