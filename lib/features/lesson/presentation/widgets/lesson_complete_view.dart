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
        const Center(child: _CheckBadge()),
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
                child: _ResultCard(
                  key: const ValueKey('score'),
                  label: 'Score',
                  value:
                      '${completion.correctFirstTry}/${completion.questionCount}',
                  caption: 'correct',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ResultCard(
                  key: const ValueKey('xpEarned'),
                  label: 'XP earned',
                  value: '+${completion.xp}',
                  caption: 'XP',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GoalCard(minutes: minutesToday, goal: dailyGoal),
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

/// A check mark that scales in once. Static when the platform asks for
/// reduced motion.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    const badge = SizedBox.square(
      dimension: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.successTint,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 40, color: AppColors.success),
      ),
    );
    final semantic = Semantics(label: 'Completed', child: badge);
    if (MediaQuery.disableAnimationsOf(context)) return semantic;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: semantic,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value $caption',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.tabular(
                  AppTextStyles.headlineMd,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              caption,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.minutes, required this.goal});

  final int minutes;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily goal: $minutes of $goal minutes',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          children: [
            Text(
              'Daily goal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppCircularProgress(
              value: goal == 0 ? 0 : minutes / goal,
              size: 48,
              strokeWidth: 5,
              center: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
                child: FittedBox(
                  child: Text(
                    '$minutes/${goal}m',
                    key: const ValueKey('goalMinutes'),
                    style: AppTextStyles.tabular(AppTextStyles.labelMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
