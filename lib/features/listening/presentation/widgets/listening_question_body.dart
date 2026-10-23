import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/listening.dart';

/// A listening question's text and answer input, without a card around it.
/// Used in listening sessions and in review.
///
/// Once [revealed], the input is locked and shows which answer is correct.
class ListeningQuestionBody extends StatelessWidget {
  const ListeningQuestionBody({
    super.key,
    required this.question,
    required this.response,
    required this.onChanged,
    this.revealed = false,
    this.autocorrect = true,
    this.showMatchingOptions = false,
  });

  final ListeningQuestion question;

  /// The option key or the typed answer.
  final String? response;

  /// Null makes the input read-only.
  final ValueChanged<String?>? onChanged;
  final bool revealed;

  /// False in timed mode: the exam has no spell check or autocorrect.
  final bool autocorrect;

  /// Matching: list the options under the question. Sessions show them
  /// once above the group instead.
  final bool showMatchingOptions;

  @override
  Widget build(BuildContext context) {
    final question = this.question;
    return switch (question.type) {
      ListeningQuestionType.formCompletion => _CompletionInput(
        key: ValueKey('completion-${question.id}'),
        question: question,
        response: response,
        revealed: revealed,
        autocorrect: autocorrect,
        onChanged: onChanged,
      ),
      ListeningQuestionType.multipleChoice => _ChoiceList(
        question: question,
        picked: response,
        revealed: revealed,
        onPick: _onPick,
      ),
      ListeningQuestionType.matching => _MatchingChips(
        question: question,
        picked: response,
        revealed: revealed,
        showOptions: showMatchingOptions,
        onPick: _onPick,
      ),
    };
  }

  ValueChanged<String>? get _onPick {
    final onChanged = this.onChanged;
    if (revealed || onChanged == null) return null;
    return onChanged;
  }
}

SelectionCardState _stateFor(
  String key, {
  required String? picked,
  required String answer,
  required bool revealed,
}) {
  if (!revealed) {
    return key == picked
        ? SelectionCardState.selected
        : SelectionCardState.idle;
  }
  if (key == answer) return SelectionCardState.correct;
  if (key == picked) return SelectionCardState.incorrect;
  return SelectionCardState.disabled;
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.question,
    required this.picked,
    required this.revealed,
    required this.onPick,
  });

  final ListeningQuestion question;
  final String? picked;
  final bool revealed;
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    final onPick = this.onPick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.smd),
        for (final (i, option) in question.options.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          SelectionCard(
            key: ValueKey('option-${question.id}-${option.key}'),
            title: option.text,
            leading: SelectionLeadingBox(text: option.key),
            state: _stateFor(
              option.key,
              picked: picked,
              answer: question.answer,
              revealed: revealed,
            ),
            onTap: onPick == null ? null : () => onPick(option.key),
          ),
        ],
      ],
    );
  }
}

/// The item to match, a row of letters, and the chosen option's text.
class _MatchingChips extends StatelessWidget {
  const _MatchingChips({
    required this.question,
    required this.picked,
    required this.revealed,
    required this.showOptions,
    required this.onPick,
  });

  final ListeningQuestion question;
  final String? picked;
  final bool revealed;
  final bool showOptions;
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    final onPick = this.onPick;
    final chosen = question.optionFor(picked);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
        ),
        if (showOptions) ...[
          const SizedBox(height: AppSpacing.sm),
          MatchingOptionsList(options: question.options),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in question.options)
              AnswerChip(
                key: ValueKey('chip-${question.id}-${option.key}'),
                label: option.key,
                semanticLabel: '${option.key}: ${option.text}',
                state: _stateFor(
                  option.key,
                  picked: picked,
                  answer: question.answer,
                  revealed: revealed,
                ),
                onTap: onPick == null ? null : () => onPick(option.key),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          chosen == null
              ? 'No answer chosen yet'
              : '${chosen.key}. ${chosen.text}',
          key: ValueKey('chosen-${question.id}'),
          style: AppTextStyles.bodySm.copyWith(
            color: chosen == null ? AppColors.textMuted : AppColors.text,
            fontStyle: chosen == null ? FontStyle.italic : null,
          ),
        ),
      ],
    );
  }
}

/// The lettered options of a matching group ("A  use it as the main
/// evidence").
class MatchingOptionsList extends StatelessWidget {
  const MatchingOptionsList({super.key, required this.options});

  final List<ListeningOption> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    o.key,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(child: Text(o.text, style: AppTextStyles.bodyMd)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompletionInput extends StatefulWidget {
  const _CompletionInput({
    super.key,
    required this.question,
    required this.response,
    required this.revealed,
    required this.autocorrect,
    required this.onChanged,
  });

  final ListeningQuestion question;
  final String? response;
  final bool revealed;
  final bool autocorrect;
  final ValueChanged<String?>? onChanged;

  @override
  State<_CompletionInput> createState() => _CompletionInputState();
}

class _CompletionInputState extends State<_CompletionInput> {
  late final _controller = TextEditingController(text: widget.response ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final limit = q.wordLimit;
    final parts = q.prompt.split(ListeningQuestion.blank);
    final typed = _controller.text.trim();
    final tooLong = limit != null && typed.isNotEmpty && !limit.allows(typed);
    final onChanged = widget.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: parts.first),
              TextSpan(
                text: typed.isEmpty ? ListeningQuestion.blank : typed,
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
          label: 'Answer to question ${q.number}',
          controller: _controller,
          enabled: !widget.revealed && onChanged != null,
          helperText: limit?.label,
          errorText: tooLong && !widget.revealed
              ? 'Write ${limit.label.toLowerCase()}'
              : null,
          autocorrect: widget.autocorrect,
          textInputAction: TextInputAction.done,
          onChanged: (text) {
            setState(() {});
            onChanged?.call(text.trim().isEmpty ? null : text);
          },
        ),
      ],
    );
  }
}
