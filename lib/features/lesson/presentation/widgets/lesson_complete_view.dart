import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../progress/domain/progress_state.dart';

/// Lesson results: score, XP, the daily goal and saved mistakes.
class LessonCompleteView extends StatelessWidget {
  const LessonCompleteView({
    super.key,
    required this.lessonTitle,
    required this.completion,
    required this.minutesToday,
    required this.dailyGoal,
  });

  final String lessonTitle;
  final LessonCompletion completion;
  final int minutesToday;
  final int dailyGoal;

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
          child: const Text(
            'Lesson complete',
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
