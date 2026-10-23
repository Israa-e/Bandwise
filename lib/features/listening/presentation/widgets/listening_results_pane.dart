import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../reading/presentation/widgets/questions_pane.dart';
import '../../domain/listening.dart';

/// Listening results: the raw score, accuracy by question type, and every
/// question with its answer, explanation and "Play from here". Never a
/// band score.
class ListeningResultsPane extends StatelessWidget {
  const ListeningResultsPane({
    super.key,
    required this.grade,
    required this.xp,
    required this.autoSubmitted,
    required this.onPlayFrom,
    this.controller,
  });

  final ListeningGrade grade;
  final int xp;

  /// Timed mode submitted when the check time ran out.
  final bool autoSubmitted;

  /// Plays the audio from the question's evidence line.
  final ValueChanged<ListeningQuestion> onPlayFrom;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final score = ListeningScore(grade.correct, grade.total);
    return SingleChildScrollView(
      key: const PageStorageKey('results'),
      controller: controller,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (autoSubmitted) ...[
            const InfoBanner(
              type: InfoBannerType.warning,
              title: "Time's up",
              message: 'Your answers were submitted automatically.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Semantics(
            header: true,
            child: const Text('Your results', style: AppTextStyles.headlineLg),
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ResultStatTile(
                    key: const ValueKey('listeningScore'),
                    label: 'Score',
                    value: '${score.correct}/${score.total}',
                    caption: 'correct',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ResultStatTile(
                    key: const ValueKey('listeningAccuracy'),
                    label: 'Accuracy',
                    value: '${score.percent}%',
                    caption: 'of questions',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ResultStatTile(
                    key: const ValueKey('listeningXp'),
                    label: 'XP earned',
                    value: '+$xp',
                    caption: 'XP',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: const Text(
              'Accuracy by question type',
              style: AppTextStyles.headlineSm,
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              children: [
                for (final (i, MapEntry(key: type, value: s))
                    in grade.byType.entries.indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _TypeRow(type: type, score: s),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: const Text('Answers', style: AppTextStyles.headlineSm),
          ),
          const SizedBox(height: AppSpacing.smd),
          for (final q in grade.questions) ...[
            AppCard(
              key: ValueKey('result-${q.id}'),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${q.number} · ${q.type.label}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    q.prompt,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.smd),
                  ListeningAnswerExplanation(
                    question: q,
                    correct: grade.isCorrect(q),
                    yourAnswer: q.describe(grade.responses[q.id]),
                    showYourAnswer: true,
                    onPlayFrom: () => onPlayFrom(q),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.smd),
          ],
        ],
      ),
    );
  }
}

/// [AnswerExplanation] with "Play from here" as the evidence link.
class ListeningAnswerExplanation extends StatelessWidget {
  const ListeningAnswerExplanation({
    super.key,
    required this.question,
    required this.correct,
    required this.onPlayFrom,
    this.yourAnswer,
    this.showYourAnswer = false,
  });

  final ListeningQuestion question;
  final bool correct;
  final VoidCallback onPlayFrom;
  final String? yourAnswer;
  final bool showYourAnswer;

  @override
  Widget build(BuildContext context) {
    return AnswerExplanation(
      key: ValueKey('explanation-${question.id}'),
      correct: correct,
      correctAnswer: question.correctAnswer,
      yourAnswer: yourAnswer,
      showYourAnswer: showYourAnswer,
      explanation: question.explanation,
      evidenceLabel: 'Play from here',
      evidenceIcon: Icons.play_circle_outline_rounded,
      onShowEvidence: onPlayFrom,
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.score});

  final ListeningQuestionType type;
  final ListeningScore score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${type.label}: ${score.correct} of ${score.total} correct',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(type.label, style: AppTextStyles.labelMd)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${score.correct}/${score.total} · ${score.percent}%',
                style: AppTextStyles.tabular(
                  AppTextStyles.labelMd,
                ).copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppLinearProgress(value: score.total == 0 ? 0 : score.percent / 100),
        ],
      ),
    );
  }
}
