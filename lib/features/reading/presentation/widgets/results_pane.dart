import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/reading.dart';
import 'questions_pane.dart';

/// Reading results: the raw score, accuracy by question type, and every
/// question with its answer and explanation. Never a band score.
class ResultsPane extends StatelessWidget {
  const ResultsPane({
    super.key,
    required this.grade,
    required this.xp,
    required this.timeUp,
    required this.onShowEvidence,
    this.controller,
  });

  final ReadingGrade grade;
  final int xp;

  /// Submitted automatically when the time ran out.
  final bool timeUp;
  final ValueChanged<ReadingQuestion> onShowEvidence;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final score = ReadingScore(grade.correct, grade.total);
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
          if (timeUp) ...[
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
                    key: const ValueKey('readingScore'),
                    label: 'Score',
                    value: '${score.correct}/${score.total}',
                    caption: 'correct',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ResultStatTile(
                    label: 'Accuracy',
                    value: '${score.percent}%',
                    caption: 'of questions',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ResultStatTile(
                    key: const ValueKey('readingXp'),
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
          for (final (i, q) in grade.questions.indexed) ...[
            AppCard(
              key: ValueKey('result-${q.id}'),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${i + 1} · ${q.type.label}',
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
                  AnswerExplanation(
                    correct: grade.isCorrect(q),
                    correctAnswer: _answerText(q, q.correctAnswer),
                    yourAnswer: switch (q.describe(grade.responses[q.id])) {
                      final a? => _answerText(q, a),
                      null => null,
                    },
                    showYourAnswer: true,
                    explanation: q.explanation,
                    onShowEvidence: () => onShowEvidence(q),
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

  /// Headings with their numeral, e.g. "ii. How building materials…".
  static String _answerText(ReadingQuestion q, String answer) {
    if (q is! HeadingQuestion) return answer;
    final i = q.options.indexOf(answer);
    return i < 0 ? answer : '${HeadingQuestion.numeral(i)}. $answer';
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.score});

  final ReadingQuestionType type;
  final ReadingScore score;

  @override
  Widget build(BuildContext context) {
    final text = '${score.correct}/${score.total} · ${score.percent}%';
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
                text,
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
