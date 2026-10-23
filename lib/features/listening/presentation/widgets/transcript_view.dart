import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/listening.dart';

/// The transcript after submitting: each line with its speaker. Lines with
/// an answer are highlighted, with the answer's words marked and the
/// question numbers (green when right, red when wrong). Tapping a line
/// plays the audio from it.
class TranscriptView extends StatelessWidget {
  const TranscriptView({
    super.key,
    required this.set,
    required this.lineKeys,
    required this.onPlayFrom,
    this.grade,
    this.currentLine,
    this.focusedLineId,
    this.controller,
  });

  final ListeningSet set;

  /// By line id, so a line can be scrolled into view.
  final Map<String, GlobalKey> lineKeys;
  final ValueChanged<TranscriptLine> onPlayFrom;

  /// Colours the question numbers by result.
  final ListeningGrade? grade;

  /// The line being played.
  final int? currentLine;

  /// The line jumped to from a question.
  final String? focusedLineId;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('transcript'),
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
          Semantics(
            header: true,
            child: const Text('Transcript', style: AppTextStyles.headlineSm),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Lines with answers are highlighted. Tap a line to play from '
            'there.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.smd),
          for (final (i, line) in set.lines.indexed)
            _Line(
              key: lineKeys[line.id],
              line: line,
              speaker: set.speaker(line.speakerId)?.name ?? line.speakerId,
              questions: set.questionsAt(line.id),
              grade: grade,
              current: i == currentLine,
              focused: line.id == focusedLineId,
              onTap: () => onPlayFrom(line),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.line,
    required this.speaker,
    required this.questions,
    required this.grade,
    required this.current,
    required this.focused,
    required this.onTap,
  });

  final TranscriptLine line;
  final String speaker;
  final List<ListeningQuestion> questions;
  final ListeningGrade? grade;
  final bool current;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final evidence = questions.isNotEmpty;
    final narrator = line.speakerId == 'narrator';
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: [
          '$speaker: ${line.text}',
          for (final q in questions)
            'Answer to question ${q.number}'
                '${switch (grade?.isCorrect(q)) {
                  true => ', correct',
                  false => ', wrong',
                  null => '',
                }}',
          if (current) 'Playing',
        ].join('. '),
        hint: 'Play from here',
        excludeSemantics: true,
        child: Material(
          color: evidence ? AppColors.warningTint : AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.nestedRadius,
            side: BorderSide(
              color: focused || current ? AppColors.primary : AppColors.border,
              width: focused || current ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('line-${line.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          speaker,
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      for (final q in questions) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        _QuestionBadge(
                          number: q.number,
                          correct: grade?.isCorrect(q),
                        ),
                      ],
                      if (current) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        const Icon(
                          Icons.graphic_eq_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text.rich(
                    evidenceSpans(line.text, [
                      for (final q in questions) q.evidence,
                    ]),
                    style: AppTextStyles.bodyMd.copyWith(
                      fontStyle: narrator ? FontStyle.italic : null,
                      color: narrator ? AppColors.textMuted : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionBadge extends StatelessWidget {
  const _QuestionBadge({required this.number, required this.correct});

  final int number;

  /// Null before marking.
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (correct) {
      true => (AppColors.successTint, AppColors.success),
      false => (AppColors.errorTint, AppColors.errorText),
      null => (AppColors.primaryTint, AppColors.primary),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: foreground),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1,
        ),
        child: Text(
          'Q$number',
          style: AppTextStyles.tabular(
            AppTextStyles.labelSm,
          ).copyWith(color: foreground),
        ),
      ),
    );
  }
}

/// [text] with each of [quotes] (the words that give an answer) in bold
/// on the accent.
TextSpan evidenceSpans(String text, List<String> quotes) {
  final ranges = <(int, int)>[
    for (final q in quotes)
      if (text.indexOf(q) case final start when start >= 0)
        (start, start + q.length),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final spans = <TextSpan>[];
  var at = 0;
  for (final (start, end) in ranges) {
    if (start < at) continue;
    if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
    spans.add(
      TextSpan(
        text: text.substring(start, end),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          backgroundColor: AppColors.accent,
        ),
      ),
    );
    at = end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(children: spans);
}
