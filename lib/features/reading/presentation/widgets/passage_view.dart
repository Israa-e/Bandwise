import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reading.dart';

/// The passage, paragraph by paragraph (A, B, C…).
///
/// Long-press to select text; the selection menu has "Highlight". The
/// [evidence] sentence, if any, is marked so "Show in passage" can point at
/// it.
class PassageView extends StatelessWidget {
  const PassageView({
    super.key,
    required this.passage,
    required this.paragraphKeys,
    required this.highlights,
    required this.onHighlight,
    required this.onClearHighlights,
    this.evidence,
    this.controller,
  });

  final ReadingPassage passage;

  /// One per paragraph, to scroll to it.
  final List<GlobalKey> paragraphKeys;

  /// Highlighted ranges per paragraph index.
  final Map<int, List<TextRange>> highlights;
  final void Function(int paragraph, TextRange range) onHighlight;
  final VoidCallback onClearHighlights;
  final EvidenceSpan? evidence;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final hasHighlights = highlights.values.any((r) => r.isNotEmpty);
    // Not lazy: every paragraph must be laid out so "Show in passage" can
    // scroll to any sentence.
    return SingleChildScrollView(
      key: const PageStorageKey('passage'),
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
            child: Text(passage.title, style: AppTextStyles.headlineLg),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            passage.topic,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasHighlights
                      ? 'Highlights stay until you leave this practice.'
                      : 'Tip: press and hold to select text, then Highlight.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (hasHighlights)
                TextButton(
                  onPressed: onClearHighlights,
                  child: const Text('Clear highlights'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < passage.paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            PassageParagraph(
              key: paragraphKeys[i],
              index: i,
              paragraph: passage.paragraphs[i],
              highlights: highlights[i] ?? const [],
              evidenceSentence: evidence?.paragraph == i
                  ? evidence!.sentence
                  : null,
              onHighlight: (range) => onHighlight(i, range),
            ),
          ],
        ],
      ),
    );
  }
}

/// One labelled, selectable paragraph.
class PassageParagraph extends StatelessWidget {
  const PassageParagraph({
    super.key,
    required this.index,
    required this.paragraph,
    required this.highlights,
    required this.onHighlight,
    this.evidenceSentence,
  });

  final int index;
  final ReadingParagraph paragraph;
  final List<TextRange> highlights;
  final ValueChanged<TextRange> onHighlight;

  /// The sentence to mark as evidence, if any.
  final int? evidenceSentence;

  @override
  Widget build(BuildContext context) {
    final label = ReadingPassage.paragraphLabel(index);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: AppRadii.nestedRadius,
          ),
          child: Semantics(
            label: 'Paragraph $label',
            child: ExcludeSemantics(
              child: Text(
                label,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.smd),
        Expanded(
          child: SelectableText.rich(
            TextSpan(children: _spans()),
            style: AppTextStyles.bodyLg,
            contextMenuBuilder: (context, state) {
              final selection = state.textEditingValue.selection;
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: state.contextMenuAnchors,
                buttonItems: [
                  if (selection.isValid && !selection.isCollapsed)
                    ContextMenuButtonItem(
                      label: 'Highlight',
                      onPressed: () {
                        onHighlight(
                          TextRange(start: selection.start, end: selection.end),
                        );
                        state.hideToolbar();
                        state.userUpdateTextEditingValue(
                          state.textEditingValue.copyWith(
                            selection: TextSelection.collapsed(
                              offset: selection.end,
                            ),
                          ),
                          SelectionChangedCause.toolbar,
                        );
                      },
                    ),
                  ...state.contextMenuButtonItems,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// The text split wherever a highlight or the evidence starts or ends.
  List<TextSpan> _spans() {
    final text = paragraph.text;
    final evidence = switch (evidenceSentence) {
      final s? => paragraph.rangeOf(s),
      null => null,
    };
    final cuts = <int>{0, text.length};
    for (final r in [...highlights, ?evidence]) {
      cuts
        ..add(r.start.clamp(0, text.length))
        ..add(r.end.clamp(0, text.length));
    }
    final sorted = cuts.toList()..sort();
    bool covers(TextRange r, int start, int end) =>
        r.start <= start && r.end >= end;
    return [
      for (var i = 0; i + 1 < sorted.length; i++)
        if (sorted[i] < sorted[i + 1])
          _span(
            text.substring(sorted[i], sorted[i + 1]),
            highlighted: highlights.any(
              (r) => covers(r, sorted[i], sorted[i + 1]),
            ),
            evidence:
                evidence != null && covers(evidence, sorted[i], sorted[i + 1]),
          ),
    ];
  }

  static TextSpan _span(
    String text, {
    required bool highlighted,
    required bool evidence,
  }) {
    if (!highlighted && !evidence) return TextSpan(text: text);
    return TextSpan(
      text: text,
      style: TextStyle(
        backgroundColor: evidence ? AppColors.warningTint : AppColors.accent,
        decoration: evidence ? TextDecoration.underline : null,
        decorationColor: AppColors.warning,
        decorationThickness: 2,
      ),
    );
  }
}

/// Scrolls so that [sentence] of the paragraph under [paragraphKey] is on
/// screen. Falls back to the paragraph if its text isn't laid out yet.
void scrollToSentence(
  GlobalKey paragraphKey,
  ReadingParagraph paragraph,
  int sentence,
) {
  final context = paragraphKey.currentContext;
  if (context == null) return;
  final editable = findRenderEditable(context.findRenderObject());
  if (editable == null) {
    Scrollable.ensureVisible(context, alignment: 0.1);
    return;
  }
  final rect = sentenceRect(editable, paragraph.rangeOf(sentence));
  editable.showOnScreen(
    rect: rect.inflate(AppSpacing.xl),
    duration: Duration.zero,
  );
}

/// The area [range] covers in [editable]'s coordinates.
Rect sentenceRect(RenderEditable editable, TextRange range) {
  final boxes = editable.getBoxesForSelection(
    TextSelection(baseOffset: range.start, extentOffset: range.end),
  );
  if (boxes.isEmpty) return Offset.zero & editable.size;
  return boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b));
}

/// The text render object inside a [PassageParagraph].
RenderEditable? findRenderEditable(RenderObject? root) {
  if (root == null) return null;
  if (root is RenderEditable) return root;
  RenderEditable? found;
  root.visitChildren((child) {
    found ??= findRenderEditable(child);
  });
  return found;
}
