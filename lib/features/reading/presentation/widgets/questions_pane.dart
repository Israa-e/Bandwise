import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/reading.dart';
import 'reading_question_body.dart';

/// Instructions shown above each group of questions.
String instructionsFor(
  ReadingQuestionType type,
  ReadingPassage passage,
) => switch (type) {
  ReadingQuestionType.trueFalseNotGiven =>
    'Do the following statements agree with the information in the '
        'passage? Choose TRUE if the statement agrees with the '
        'information, FALSE if the statement contradicts the '
        'information, or NOT GIVEN if there is no information on this.',
  ReadingQuestionType.multipleChoice => 'Choose the correct answer.',
  ReadingQuestionType.matchingHeadings =>
    'The passage has ${passage.paragraphs.length} paragraphs, '
        'A–${ReadingPassage.paragraphLabel(passage.paragraphs.length - 1)}. '
        'Choose the correct heading for each paragraph from the list of '
        'headings below.',
  ReadingQuestionType.sentenceCompletion =>
    'Complete the sentences. Choose NO MORE THAN TWO WORDS from the '
        'passage for each answer.',
};

/// The questions of a session, grouped by type with their instructions.
///
/// In learning mode each question has Check, then shows whether it was
/// right, the explanation and "Show in passage". In timed mode there is no
/// feedback until the session is submitted.
class QuestionsPane extends StatelessWidget {
  const QuestionsPane({
    super.key,
    required this.passage,
    required this.questions,
    required this.questionKeys,
    required this.responses,
    required this.flagged,
    required this.checked,
    required this.learning,
    required this.onChanged,
    required this.onToggleFlag,
    required this.onCheck,
    required this.onShowEvidence,
    this.controller,
  });

  final ReadingPassage passage;
  final List<ReadingQuestion> questions;
  final Map<String, GlobalKey> questionKeys;
  final Map<String, ReadingResponse> responses;
  final Set<String> flagged;

  /// Questions checked so far (learning mode).
  final Set<String> checked;
  final bool learning;
  final void Function(ReadingQuestion, ReadingResponse?) onChanged;
  final ValueChanged<ReadingQuestion> onToggleFlag;
  final ValueChanged<ReadingQuestion> onCheck;
  final ValueChanged<ReadingQuestion> onShowEvidence;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    ReadingQuestionType? group;
    for (final (i, q) in questions.indexed) {
      if (q.type != group) {
        group = q.type;
        final last = questions.lastIndexWhere((x) => x.type == group);
        children.add(
          _GroupHeader(
            type: q.type,
            first: i + 1,
            last: last + 1,
            passage: passage,
            headings: q is HeadingQuestion ? q.options : null,
          ),
        );
      }
      final isChecked = checked.contains(q.id);
      children.add(
        Padding(
          key: questionKeys[q.id],
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.smd),
          child: _QuestionCard(
            key: ValueKey('question-${q.id}'),
            number: i + 1,
            question: q,
            response: responses[q.id],
            flagged: flagged.contains(q.id),
            revealed: isChecked,
            onChanged: isChecked ? null : (r) => onChanged(q, r),
            onToggleFlag: () => onToggleFlag(q),
            footer: !learning
                ? null
                : isChecked
                ? _InlineFeedback(
                    question: q,
                    response: responses[q.id],
                    onShowEvidence: () => onShowEvidence(q),
                  )
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton.outline(
                      label: 'Check',
                      compact: true,
                      expand: false,
                      onPressed: q.isAnswered(responses[q.id])
                          ? () => onCheck(q)
                          : null,
                    ),
                  ),
          ),
        ),
      );
    }
    // Not lazy, so the navigator can jump to any question.
    return SingleChildScrollView(
      key: const PageStorageKey('questions'),
      controller: controller,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.type,
    required this.first,
    required this.last,
    required this.passage,
    this.headings,
  });

  final ReadingQuestionType type;
  final int first;
  final int last;
  final ReadingPassage passage;
  final List<String>? headings;

  @override
  Widget build(BuildContext context) {
    final headings = this.headings;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.smd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              first == last ? 'Question $first' : 'Questions $first–$last',
              style: AppTextStyles.headlineSm,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            type.label.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            instructionsFor(type, passage),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          if (headings != null) ...[
            const SizedBox(height: AppSpacing.smd),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('List of headings', style: AppTextStyles.labelLg),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (i, h) in headings.indexed)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              HeadingQuestion.numeral(i),
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(child: Text(h, style: AppTextStyles.bodyMd)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.response,
    required this.flagged,
    required this.revealed,
    required this.onChanged,
    required this.onToggleFlag,
    this.footer,
  });

  final int number;
  final ReadingQuestion question;
  final ReadingResponse? response;
  final bool flagged;
  final bool revealed;
  final ValueChanged<ReadingResponse?>? onChanged;
  final VoidCallback onToggleFlag;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question $number',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              IconButton(
                tooltip: flagged
                    ? 'Remove flag from question $number'
                    : 'Flag question $number',
                isSelected: flagged,
                onPressed: onToggleFlag,
                icon: const Icon(
                  Icons.outlined_flag_rounded,
                  color: AppColors.textMuted,
                ),
                selectedIcon: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.warning,
                ),
                style: IconButton.styleFrom(minimumSize: const Size.square(44)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.smd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReadingQuestionBody(
                  question: question,
                  response: response,
                  revealed: revealed,
                  onChanged: onChanged,
                  compactHeadings: true,
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.smd),
                  footer,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Learning-mode result under a checked question.
class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({
    required this.question,
    required this.response,
    required this.onShowEvidence,
  });

  final ReadingQuestion question;
  final ReadingResponse? response;
  final VoidCallback onShowEvidence;

  @override
  Widget build(BuildContext context) {
    final correct = question.isCorrect(response);
    return Semantics(
      liveRegion: true,
      child: AnswerExplanation(
        correct: correct,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
        notGiven: question.isNotGiven,
        onShowEvidence: onShowEvidence,
      ),
    );
  }
}

/// Right or wrong, the correct answer, the explanation and a link to the
/// evidence. Used under checked questions and in results, for Reading and
/// Listening.
///
/// A Not Given answer has no evidence, so it says so and links to the
/// related part of the passage instead.
class AnswerExplanation extends StatelessWidget {
  const AnswerExplanation({
    super.key,
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
    required this.onShowEvidence,
    this.yourAnswer,
    this.showYourAnswer = false,
    this.notGiven = false,
    this.evidenceLabel,
    this.evidenceIcon = Icons.find_in_page_outlined,
  });

  static const notGivenNote = "This information isn't in the passage.";

  final bool correct;
  final String correctAnswer;
  final String explanation;
  final VoidCallback onShowEvidence;

  /// What the learner answered; null for no answer.
  final String? yourAnswer;
  final bool showYourAnswer;

  /// The correct answer is Not Given.
  final bool notGiven;

  /// The evidence link; defaults to "Show in passage".
  final String? evidenceLabel;
  final IconData evidenceIcon;

  @override
  Widget build(BuildContext context) {
    final (tint, accent, icon, title) = correct
        ? (
            AppColors.successTint,
            AppColors.success,
            Icons.check_circle_rounded,
            'Correct',
          )
        : (
            AppColors.errorTint,
            AppColors.error,
            Icons.cancel_rounded,
            'Not quite',
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.smd,
          AppSpacing.smd,
          AppSpacing.smd,
          AppSpacing.xxs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: accent),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.labelLg.copyWith(
                      color: correct ? AppColors.text : AppColors.errorText,
                    ),
                  ),
                ),
              ],
            ),
            if (showYourAnswer) ...[
              const SizedBox(height: AppSpacing.xs),
              _LabelledValue(
                label: 'Your answer',
                value: yourAnswer ?? 'No answer',
                muted: yourAnswer == null,
              ),
            ],
            if (!correct || showYourAnswer) ...[
              const SizedBox(height: AppSpacing.xxs),
              _LabelledValue(label: 'Correct answer', value: correctAnswer),
            ],
            if (notGiven) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                notGivenNote,
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              explanation,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onShowEvidence,
                icon: Icon(evidenceIcon, size: 18),
                label: Text(
                  evidenceLabel ??
                      (notGiven ? 'Show related part' : 'Show in passage'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelledValue extends StatelessWidget {
  const _LabelledValue({
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontStyle: muted ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
      style: AppTextStyles.bodySm,
    );
  }
}
