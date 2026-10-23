import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/reading.dart';

/// A reading question's text and answer input, without a card around it.
/// Used in reading sessions and in review.
///
/// Once [revealed], the input is locked and shows which answer is correct.
class ReadingQuestionBody extends StatelessWidget {
  const ReadingQuestionBody({
    super.key,
    required this.question,
    required this.response,
    required this.onChanged,
    this.revealed = false,
    this.optionOrder,
    this.compactHeadings = false,
  });

  final ReadingQuestion question;
  final ReadingResponse? response;

  /// Null makes the input read-only.
  final ValueChanged<ReadingResponse?>? onChanged;
  final bool revealed;

  /// Option indexes in display order; null keeps the original order.
  final List<int>? optionOrder;

  /// Matching headings as numeral chips (i, ii, iii…), for when the list of
  /// headings is shown once above the questions. Otherwise every heading
  /// is listed in full.
  final bool compactHeadings;

  @override
  Widget build(BuildContext context) {
    final question = this.question;
    return switch (question) {
      HeadingQuestion() when compactHeadings => _HeadingChips(
        question: question,
        picked: _picked,
        revealed: revealed,
        onPick: _onPick,
      ),
      ChoiceReadingQuestion() => _ChoiceList(
        question: question,
        picked: _picked,
        revealed: revealed,
        optionOrder: optionOrder,
        onPick: _onPick,
      ),
      CompletionQuestion() => _CompletionInput(
        key: ValueKey('completion-${question.id}'),
        question: question,
        response: response,
        revealed: revealed,
        onChanged: onChanged,
      ),
    };
  }

  int? get _picked => switch (response) {
    ChoiceResponse(:final index) => index,
    _ => null,
  };

  ValueChanged<int>? get _onPick {
    final onChanged = this.onChanged;
    if (revealed || onChanged == null) return null;
    return (i) => onChanged(ChoiceResponse(i));
  }
}

SelectionCardState _stateFor(
  int i, {
  required int? picked,
  required int correctIndex,
  required bool revealed,
}) {
  if (!revealed) {
    return i == picked ? SelectionCardState.selected : SelectionCardState.idle;
  }
  if (i == correctIndex) return SelectionCardState.correct;
  if (i == picked) return SelectionCardState.incorrect;
  return SelectionCardState.disabled;
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.question,
    required this.picked,
    required this.revealed,
    required this.optionOrder,
    required this.onPick,
  });

  final ChoiceReadingQuestion question;
  final int? picked;
  final bool revealed;
  final List<int>? optionOrder;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final question = this.question;
    final order =
        optionOrder ?? List.generate(question.options.length, (i) => i);
    final heading = question is HeadingQuestion;
    final tfng = question is TfngQuestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          heading
              ? 'Choose the heading for ${question.prompt}.'
              : question.prompt,
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.smd),
        for (final (position, i) in order.indexed) ...[
          if (position > 0) const SizedBox(height: AppSpacing.sm),
          SelectionCard(
            title: question.options[i],
            leading: tfng
                ? null
                : SelectionLeadingBox(
                    text: heading
                        ? HeadingQuestion.numeral(i)
                        : String.fromCharCode(65 + position),
                  ),
            state: _stateFor(
              i,
              picked: picked,
              correctIndex: question.correctIndex,
              revealed: revealed,
            ),
            onTap: onPick == null ? null : () => onPick!(i),
          ),
        ],
      ],
    );
  }
}

/// "Paragraph B", a row of numerals (one per heading), the chosen
/// heading's text, and "View headings" for the full list.
class _HeadingChips extends StatelessWidget {
  const _HeadingChips({
    required this.question,
    required this.picked,
    required this.revealed,
    required this.onPick,
  });

  final HeadingQuestion question;
  final int? picked;
  final bool revealed;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < question.options.length; i++)
              AnswerChip(
                label: HeadingQuestion.numeral(i),
                semanticLabel:
                    'Heading ${HeadingQuestion.numeral(i)}: ${question.options[i]}',
                state: _stateFor(
                  i,
                  picked: picked,
                  correctIndex: question.correctIndex,
                  revealed: revealed,
                ),
                onTap: onPick == null ? null : () => onPick!(i),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          switch (picked) {
            final i? => '${HeadingQuestion.numeral(i)}. ${question.options[i]}',
            null => 'No heading chosen yet',
          },
          key: ValueKey('chosen-${question.id}'),
          style: AppTextStyles.bodySm.copyWith(
            color: picked == null ? AppColors.textMuted : AppColors.text,
            fontStyle: picked == null ? FontStyle.italic : null,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _showHeadings(context),
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: const Text('View headings'),
          ),
        ),
      ],
    );
  }

  /// The full list of headings. When the question is still open, tapping a
  /// heading chooses it.
  Future<void> _showHeadings(BuildContext context) async {
    final onPick = this.onPick;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('List of headings', style: AppTextStyles.headlineSm),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                onPick == null
                    ? 'For ${question.prompt}.'
                    : 'Choose the heading for ${question.prompt}.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.smd),
              for (var i = 0; i < question.options.length; i++) ...[
                SelectionCard(
                  key: ValueKey('sheet-heading-$i'),
                  title: question.options[i],
                  leading: SelectionLeadingBox(
                    text: HeadingQuestion.numeral(i),
                  ),
                  state: _stateFor(
                    i,
                    picked: picked,
                    correctIndex: question.correctIndex,
                    revealed: revealed,
                  ),
                  onTap: onPick == null
                      ? null
                      : () => Navigator.pop(sheetContext, i),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
    if (chosen != null) onPick?.call(chosen);
  }
}

class _CompletionInput extends StatefulWidget {
  const _CompletionInput({
    super.key,
    required this.question,
    required this.response,
    required this.revealed,
    required this.onChanged,
  });

  final CompletionQuestion question;
  final ReadingResponse? response;
  final bool revealed;
  final ValueChanged<ReadingResponse?>? onChanged;

  @override
  State<_CompletionInput> createState() => _CompletionInputState();
}

class _CompletionInputState extends State<_CompletionInput> {
  late final _controller = TextEditingController(
    text: switch (widget.response) {
      TextResponse(:final text) => text,
      _ => '',
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final parts = q.sentence.split(CompletionQuestion.blank);
    final typed = _controller.text.trim();
    final words = CompletionQuestion.wordCount(typed);
    final tooLong = words > q.maxWords;
    final onChanged = widget.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: parts.first),
              TextSpan(
                text: typed.isEmpty ? '______' : typed,
                style: TextStyle(
                  color: typed.isEmpty
                      ? AppColors.textDisabled
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (parts.length > 1) TextSpan(text: parts.sublist(1).join()),
            ],
          ),
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.smd),
        AppTextField(
          label: 'Your answer',
          controller: _controller,
          enabled: !widget.revealed && onChanged != null,
          helperText: q.wordLimitLabel,
          errorText: tooLong && !widget.revealed
              ? 'Use ${q.wordLimitLabel.toLowerCase()}'
              : null,
          textInputAction: TextInputAction.done,
          onChanged: (text) {
            setState(() {});
            onChanged?.call(text.trim().isEmpty ? null : TextResponse(text));
          },
        ),
      ],
    );
  }
}
