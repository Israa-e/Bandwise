import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant {
  /// Purple fill. The main action on a screen.
  primary,

  /// Lime fill. Reward claims, milestones and other high-energy actions.
  secondary,

  /// White with a border. Alternative actions next to a primary button.
  outline,

  /// Transparent. Low-emphasis actions such as "Skip".
  ghost,
}

/// The app's button. Use [AppButton.primary], [AppButton.secondary] or
/// [AppButton.ghost].
///
/// Passing a null [onPressed] renders the disabled state. [isLoading] shows a
/// spinner and blocks taps while keeping the button's size.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.compact = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.compact = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.compact = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = true,
    this.compact = false,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;

  /// Fill the available width.
  final bool expand;

  /// 40px tall instead of 52px, for inline actions inside cards.
  final bool compact;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors();
    final height = compact ? 40.0 : 52.0;
    final textStyle = compact ? AppTextStyles.labelLg : AppTextStyles.button;
    final showGlow =
        variant == AppButtonVariant.primary && _enabled && !compact;

    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 20, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle.copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: 20, color: foreground),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: isLoading ? '$label, loading' : null,
      excludeSemantics: isLoading,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: AppRadii.buttonRadius,
          boxShadow: showGlow ? AppShadows.primaryButton : null,
        ),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.buttonRadius,
            side: variant == AppButtonVariant.outline
                ? const BorderSide(color: AppColors.border, width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: compact ? AppSpacing.md : AppSpacing.lg,
              ),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _colors() {
    // Loading keeps the enabled look so the button doesn't flash grey.
    final disabled = onPressed == null;
    return switch (variant) {
      AppButtonVariant.primary when disabled => (
        AppColors.disabledFill,
        AppColors.textDisabled,
      ),
      AppButtonVariant.primary => (AppColors.primary, AppColors.onPrimary),
      AppButtonVariant.secondary when disabled => (
        AppColors.disabledFill,
        AppColors.textDisabled,
      ),
      AppButtonVariant.secondary => (AppColors.accent, AppColors.onAccent),
      AppButtonVariant.outline when disabled => (
        AppColors.card,
        AppColors.textDisabled,
      ),
      AppButtonVariant.outline => (AppColors.card, AppColors.text),
      AppButtonVariant.ghost when disabled => (
        Colors.transparent,
        AppColors.textDisabled,
      ),
      AppButtonVariant.ghost => (Colors.transparent, AppColors.textMuted),
    };
  }
}
