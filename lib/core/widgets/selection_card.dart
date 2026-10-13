import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_chip.dart';

/// Whether a [SelectionCard] belongs to a single-choice or multi-choice group.
enum SelectionMode { single, multi }

/// Visual state of a [SelectionCard].
enum SelectionCardState {
  /// Not selected, tappable.
  idle,

  /// Chosen by the user, before any checking.
  selected,

  /// Shown after checking: this is the right answer.
  correct,

  /// Shown after checking: the user chose this and it is wrong.
  incorrect,

  /// Not tappable. Also used for the other options once an answer is checked.
  disabled,
}

/// Layout of a [SelectionCard].
enum SelectionCardLayout {
  /// Full-width row: leading, text, indicator. For lists of options.
  row,

  /// Square-ish tile: leading and indicator on top, text below. For grids.
  tile,
}

/// A tappable option card for onboarding choices and quiz answers.
///
/// Status is never conveyed by color alone: correct/incorrect add an icon and
/// a text badge, and the state is exposed to screen readers.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.title,
    required this.state,
    this.onTap,
    this.mode = SelectionMode.single,
    this.layout = SelectionCardLayout.row,
    this.subtitle,
    this.leading,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final SelectionCardState state;
  final VoidCallback? onTap;
  final SelectionMode mode;
  final SelectionCardLayout layout;

  /// Optional icon box or letter marker before the title.
  final Widget? leading;

  /// Optional pill next to the title (e.g. "Popular").
  final Widget? badge;

  bool get _isChecked =>
      state == SelectionCardState.selected ||
      state == SelectionCardState.correct ||
      state == SelectionCardState.incorrect;

  bool get _interactive =>
      onTap != null && state != SelectionCardState.disabled;

  @override
  Widget build(BuildContext context) {
    final style = _CardStyle.of(state);

    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: AppTextStyles.headlineSm.copyWith(color: style.textColor),
          ),
        ),
        if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge!],
      ],
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleRow,
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
        if (state == SelectionCardState.correct ||
            state == SelectionCardState.incorrect) ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusBadge(correct: state == SelectionCardState.correct),
        ],
      ],
    );

    final indicator = _Indicator(mode: mode, state: state);

    final body = switch (layout) {
      SelectionCardLayout.row => Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.smd),
          ],
          Expanded(child: text),
          const SizedBox(width: AppSpacing.smd),
          indicator,
        ],
      ),
      SelectionCardLayout.tile => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 116),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [?leading, const Spacer(), indicator],
            ),
            const SizedBox(height: AppSpacing.smd),
            text,
          ],
        ),
      ),
    };

    return Semantics(
      inMutuallyExclusiveGroup: mode == SelectionMode.single,
      checked: _isChecked,
      enabled: _interactive,
      button: false,
      value: switch (state) {
        SelectionCardState.correct => 'Correct',
        SelectionCardState.incorrect => 'Incorrect',
        _ => null,
      },
      child: Opacity(
        opacity: state == SelectionCardState.disabled ? 0.6 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: style.borderColor,
              width: style.borderWidth,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _interactive ? onTap : null,
              borderRadius: AppRadii.cardRadius,
              child: Padding(
                // Keep content in place when the border thickens.
                padding: EdgeInsetsDirectional.all(
                  AppSpacing.md + 2 - style.borderWidth,
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon box used as a [SelectionCard.leading].
class SelectionLeadingBox extends StatelessWidget {
  const SelectionLeadingBox({
    super.key,
    this.icon,
    this.text,
    this.color = AppColors.primary,
    this.background = AppColors.primaryTint,
    this.circle = false,
  }) : assert(icon != null || text != null);

  final IconData? icon;
  final String? text;
  final Color color;
  final Color background;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: circle ? null : AppRadii.nestedRadius,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: icon != null
          ? Icon(icon, color: color, size: 22)
          : Text(
              text!,
              style: AppTextStyles.tabular(
                AppTextStyles.headlineSm,
              ).copyWith(color: color, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class _CardStyle {
  const _CardStyle({
    required this.background,
    required this.borderColor,
    required this.borderWidth,
  }) : textColor = AppColors.text;

  final Color background;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;

  static _CardStyle of(SelectionCardState state) => switch (state) {
    SelectionCardState.idle || SelectionCardState.disabled => const _CardStyle(
      background: AppColors.card,
      borderColor: AppColors.border,
      borderWidth: 1.5,
    ),
    SelectionCardState.selected => const _CardStyle(
      background: AppColors.selectedSurface,
      borderColor: AppColors.primary,
      borderWidth: 2,
    ),
    SelectionCardState.correct => const _CardStyle(
      background: AppColors.successTint,
      borderColor: AppColors.success,
      borderWidth: 2,
    ),
    SelectionCardState.incorrect => const _CardStyle(
      background: AppColors.errorTint,
      borderColor: AppColors.error,
      borderWidth: 2,
    ),
  };
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.mode, required this.state});

  final SelectionMode mode;
  final SelectionCardState state;

  @override
  Widget build(BuildContext context) {
    final (fill, icon, iconColor) = switch (state) {
      SelectionCardState.selected => (
        AppColors.primary,
        Icons.check_rounded,
        AppColors.onPrimary,
      ),
      SelectionCardState.correct => (
        AppColors.success,
        Icons.check_rounded,
        AppColors.onPrimary,
      ),
      SelectionCardState.incorrect => (
        AppColors.error,
        Icons.close_rounded,
        AppColors.onPrimary,
      ),
      _ => (null, null, null),
    };

    final radius = mode == SelectionMode.multi
        ? const BorderRadius.all(Radius.circular(6))
        : null;
    final shape = mode == SelectionMode.single
        ? BoxShape.circle
        : BoxShape.rectangle;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: fill,
        shape: shape,
        borderRadius: radius,
        border: fill == null
            ? Border.all(color: AppColors.border, width: 2)
            : null,
      ),
      child: icon == null ? null : Icon(icon, size: 16, color: iconColor),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      size: AppPillSize.small,
      label: correct ? 'Correct' : 'Incorrect',
      icon: correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
      iconColor: correct ? AppColors.success : AppColors.error,
      background: AppColors.card,
      foreground: correct ? AppColors.text : AppColors.errorText,
    );
  }
}
