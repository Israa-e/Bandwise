import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/writing.dart';
import '../../domain/writing_feedback.dart';

/// A range such as "6.0–6.5" in tabular figures. Screen readers hear it
/// with [estimateLabel].
class EstimateRangeText extends StatelessWidget {
  const EstimateRangeText({
    super.key,
    required this.range,
    this.style = AppTextStyles.headlineSm,
  });

  final EstimateRange range;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${range.spoken}, $estimateLabel',
      excludeSemantics: true,
      child: Text(
        range.label,
        style: AppTextStyles.tabular(style).copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// "AI practice estimate — not an official IELTS score" with an info icon.
class EstimateLabel extends StatelessWidget {
  const EstimateLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            estimateLabel,
            key: const ValueKey('estimateLabel'),
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// How each annotation type looks: an icon, an underline style and a
/// color. Types differ in icon and underline, not only in color.
extension AnnotationStyle on AnnotationType {
  IconData get icon => switch (this) {
    AnnotationType.grammar => Icons.rule_rounded,
    AnnotationType.vocabulary => Icons.abc_rounded,
    AnnotationType.cohesion => Icons.link_rounded,
    AnnotationType.task => Icons.flag_outlined,
  };

  Color get color => switch (this) {
    AnnotationType.grammar => AppColors.error,
    AnnotationType.vocabulary => AppColors.primary,
    AnnotationType.cohesion => AppColors.warning,
    AnnotationType.task => AppColors.text,
  };

  Color get tint => switch (this) {
    AnnotationType.grammar => AppColors.errorTint,
    AnnotationType.vocabulary => AppColors.primaryTint,
    AnnotationType.cohesion => AppColors.warningTint,
    AnnotationType.task => AppColors.disabledFill,
  };

  TextDecorationStyle get underline => switch (this) {
    AnnotationType.grammar => TextDecorationStyle.wavy,
    AnnotationType.vocabulary => TextDecorationStyle.double,
    AnnotationType.cohesion => TextDecorationStyle.dashed,
    AnnotationType.task => TextDecorationStyle.dotted,
  };

  /// "wavy underline", for the legend.
  String get underlineName => switch (this) {
    AnnotationType.grammar => 'Wavy underline',
    AnnotationType.vocabulary => 'Double underline',
    AnnotationType.cohesion => 'Dashed underline',
    AnnotationType.task => 'Dotted underline',
  };
}

/// One paragraph of an essay with [annotations] highlighted. Each
/// highlight starts with its type's icon and is tappable.
///
/// [offset] is where the paragraph starts in the essay; annotation offsets
/// are essay offsets.
class AnnotatedParagraph extends StatefulWidget {
  const AnnotatedParagraph({
    super.key,
    required this.text,
    required this.offset,
    required this.annotations,
    required this.onTap,
  });

  final String text;
  final int offset;
  final List<Annotation> annotations;
  final ValueChanged<Annotation> onTap;

  @override
  State<AnnotatedParagraph> createState() => _AnnotatedParagraphState();
}

class _AnnotatedParagraphState extends State<AnnotatedParagraph> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final text = widget.text;
    final spans = <InlineSpan>[];
    var cursor = 0;
    final inside = [
      for (final a in widget.annotations)
        if (a.start >= widget.offset && a.end <= widget.offset + text.length) a,
    ]..sort((a, b) => a.start.compareTo(b.start));
    for (final a in inside) {
      final start = a.start - widget.offset;
      final end = a.end - widget.offset;
      if (start < cursor) continue;
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      final recognizer = TapGestureRecognizer()..onTap = () => widget.onTap(a);
      _recognizers.add(recognizer);
      spans
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 2),
              child: Icon(a.type.icon, size: 14, color: a.type.color),
            ),
          ),
        )
        ..add(
          TextSpan(
            text: text.substring(start, end),
            recognizer: recognizer,
            semanticsLabel:
                '${a.type.label} note: ${text.substring(start, end)}',
            style: TextStyle(
              backgroundColor: a.type.tint,
              decoration: TextDecoration.underline,
              decorationStyle: a.type.underline,
              decorationColor: a.type.color,
              decorationThickness: 2,
            ),
          ),
        );
      cursor = end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(TextSpan(style: AppTextStyles.bodyLg, children: spans));
  }
}

/// Opens [notes] at [index] in a sheet. "Got it" closes it; "Next" moves
/// to the next note.
Future<void> showAnnotationSheet(
  BuildContext context, {
  required List<Annotation> notes,
  required int index,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => _AnnotationSheet(notes: notes, initialIndex: index),
);

class _AnnotationSheet extends StatefulWidget {
  const _AnnotationSheet({required this.notes, required this.initialIndex});

  final List<Annotation> notes;
  final int initialIndex;

  @override
  State<_AnnotationSheet> createState() => _AnnotationSheetState();
}

class _AnnotationSheetState extends State<_AnnotationSheet> {
  late var _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final note = widget.notes[_index];
    final hasNext = _index < widget.notes.length - 1;
    final criterion = WritingCriterion.byId(note.criterionId);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        child: Column(
          key: ValueKey('note-${note.id}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnnotationTypeBadge(type: note.type),
                const Spacer(),
                Text(
                  '${_index + 1} of ${widget.notes.length}',
                  style: AppTextStyles.tabular(
                    AppTextStyles.labelMd,
                  ).copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            if (criterion != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                criterion.label,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _QuoteBox(
              label: 'You wrote',
              text: note.original,
              background: note.type.tint,
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuoteBox(
              label: note.type == AnnotationType.task
                  ? 'Suggestion'
                  : 'Suggested alternative',
              text: note.suggestion,
              background: AppColors.successTint,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Why', style: AppTextStyles.labelLg),
            const SizedBox(height: AppSpacing.xxs),
            Text(note.why, style: AppTextStyles.bodyMd),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    label: 'Got it',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                if (hasNext) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Next',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () => setState(() => _index++),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  const _QuoteBox({
    required this.label,
    required this.text,
    required this.background,
  });

  final String label;
  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(text, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

/// The type's icon and name.
class AnnotationTypeBadge extends StatelessWidget {
  const AnnotationTypeBadge({super.key, required this.type});

  final AnnotationType type;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: type.label,
      icon: type.icon,
      iconColor: type.color,
      background: type.tint,
      foreground: AppColors.text,
      size: AppPillSize.small,
    );
  }
}

/// A count of notes per type, e.g. "Grammar 4".
class AnnotationStatsRow extends StatelessWidget {
  const AnnotationStatsRow({super.key, required this.annotations});

  final List<Annotation> annotations;

  @override
  Widget build(BuildContext context) {
    Widget tile(AnnotationType type) {
      final n = annotations.where((a) => a.type == type).length;
      return Semantics(
        label: '${type.label}: $n ${n == 1 ? 'note' : 'notes'}',
        excludeSemantics: true,
        child: Container(
          key: ValueKey('stat-${type.name}'),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: type.tint,
            borderRadius: AppRadii.nestedRadius,
          ),
          child: Column(
            children: [
              Icon(type.icon, size: 18, color: type.color),
              const SizedBox(height: 2),
              Text(
                '$n',
                style: AppTextStyles.tabular(AppTextStyles.headlineSm),
              ),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        for (final (i, type) in AnnotationType.values.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(child: tile(type)),
        ],
      ],
    );
  }
}
