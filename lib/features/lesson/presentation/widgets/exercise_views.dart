import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../learn/domain/course.dart';

/// Front of a flashcard, and the meaning and example once revealed.
class FlashcardView extends StatelessWidget {
  const FlashcardView({
    super.key,
    required this.exercise,
    required this.revealed,
  });

  final FlashcardExercise exercise;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Eyebrow('New word'),
        const SizedBox(height: AppSpacing.smd),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(exercise.word, style: AppTextStyles.headlineXl),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const _PronunciationButton(),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppPill(
                label: exercise.partOfSpeech,
                background: AppColors.primaryTint,
                foreground: AppColors.primary,
                size: AppPillSize.small,
              ),
              if (revealed) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                const _Label('Meaning'),
                const SizedBox(height: AppSpacing.xxs),
                Text(exercise.meaning, style: AppTextStyles.bodyLg),
                const SizedBox(height: AppSpacing.md),
                const _Label('Example'),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  exercise.example,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Think about what it means, then reveal.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (revealed) ...[
          const SizedBox(height: AppSpacing.smd),
          InfoBanner(title: 'How to use it', message: exercise.explanation),
        ],
      ],
    );
  }
}

class _PronunciationButton extends StatelessWidget {
  const _PronunciationButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Pronunciation',
      onPressed: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Audio coming soon'))),
      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryTint,
        minimumSize: const Size.square(48),
      ),
    );
  }
}

/// A multiple-choice or fill-in-the-blank question.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.exercise,
    required this.picked,
    required this.checked,
    required this.onPick,
  });

  final QuestionExercise exercise;
  final int? picked;
  final bool checked;
  final ValueChanged<int> onPick;

  SelectionCardState _stateFor(int i) {
    if (!checked) {
      return i == picked
          ? SelectionCardState.selected
          : SelectionCardState.idle;
    }
    if (i == exercise.correctIndex) return SelectionCardState.correct;
    if (i == picked) return SelectionCardState.incorrect;
    return SelectionCardState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final exercise = this.exercise;
    final (eyebrow, Widget? body) = switch (exercise) {
      MultipleChoiceExercise(:final passage) => (
        'Multiple choice',
        passage == null ? null : _PassageCard(text: passage),
      ),
      FillBlankExercise(:final sentence) => (
        'Fill in the blank',
        _BlankSentence(
          sentence: sentence,
          answer: picked == null ? null : exercise.options[picked!],
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text(exercise.prompt, style: AppTextStyles.headlineMd),
        ),
        if (body != null) ...[const SizedBox(height: AppSpacing.md), body],
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < exercise.options.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.smd),
          SelectionCard(
            title: exercise.options[i],
            leading: SelectionLeadingBox(text: String.fromCharCode(65 + i)),
            state: _stateFor(i),
            onTap: checked ? null : () => onPick(i),
          ),
        ],
      ],
    );
  }
}

class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(child: Text(text, style: AppTextStyles.bodyLg));
  }
}

/// The sentence with its gap, filled in with the picked option.
class _BlankSentence extends StatelessWidget {
  const _BlankSentence({required this.sentence, required this.answer});

  final String sentence;
  final String? answer;

  @override
  Widget build(BuildContext context) {
    final parts = sentence.split(FillBlankExercise.blank);
    final before = parts.first;
    final after = parts.length > 1 ? parts.sublist(1).join() : '';
    final answer = this.answer;
    return AppCard(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: before),
            TextSpan(
              text: answer ?? '______',
              style: TextStyle(
                color: answer == null
                    ? AppColors.textDisabled
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: answer == null ? null : TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
            TextSpan(text: after),
          ],
        ),
        style: AppTextStyles.bodyLg,
      ),
    );
  }
}

/// Result shown after "Check": correct or not, the answer, the explanation
/// and Continue. Wrong answers never block progress.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
    required this.onContinue,
  });

  final bool correct;
  final String correctAnswer;
  final String explanation;
  final VoidCallback onContinue;

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
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          boxShadow: AppShadows.raised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accent, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.headlineSm.copyWith(
                          color: correct ? AppColors.text : AppColors.errorText,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!correct) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text.rich(
                    TextSpan(
                      text: 'Answer: ',
                      children: [
                        TextSpan(
                          text: correctAnswer,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    style: AppTextStyles.bodyMd,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Long explanations scroll instead of pushing Continue away.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.3,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      explanation,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(label: 'Continue', onPressed: onContinue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
    );
  }
}
