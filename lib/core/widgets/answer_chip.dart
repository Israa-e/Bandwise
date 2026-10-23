import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'selection_card.dart';

/// A short answer (a numeral or letter) to tap, in the states of a
/// [SelectionCard]. Used for matching headings and matching questions.
class AnswerChip extends StatelessWidget {
  const AnswerChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.state,
    required this.onTap,
  });

  final String label;

  /// What screen readers hear, e.g. "Heading ii: …".
  final String semanticLabel;
  final SelectionCardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (state) {
      SelectionCardState.selected => (
        AppColors.selectedSurface,
        AppColors.primary,
        AppColors.primary,
      ),
      SelectionCardState.correct => (
        AppColors.successTint,
        AppColors.success,
        AppColors.text,
      ),
      SelectionCardState.incorrect => (
        AppColors.errorTint,
        AppColors.error,
        AppColors.errorText,
      ),
      SelectionCardState.disabled => (
        AppColors.card,
        AppColors.border,
        AppColors.textDisabled,
      ),
      SelectionCardState.idle => (
        AppColors.card,
        AppColors.border,
        AppColors.text,
      ),
    };
    final selected =
        state == SelectionCardState.selected ||
        state == SelectionCardState.correct ||
        state == SelectionCardState.incorrect;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.buttonRadius,
          side: BorderSide(color: border, width: selected ? 2 : 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 44,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelLg.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
