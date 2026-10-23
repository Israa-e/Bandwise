import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Visual state of an [AppTextField].
enum AppTextFieldVisualState { normal, focused, error, disabled }

/// Labeled single-line text input with normal, focused, error and disabled
/// states. Set [isPassword] for an obscured field with a visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.visualStateOverride,
    this.autocorrect = true,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;

  /// Shown under the field when there is no error.
  final String? helperText;

  /// Non-null puts the field in the error state and shows this message.
  final String? errorText;
  final bool enabled;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;

  /// Forces a look regardless of focus. Only for the component gallery.
  final AppTextFieldVisualState? visualStateOverride;

  /// False turns off autocorrect, suggestions and spell check, e.g. for
  /// timed exam answers.
  final bool autocorrect;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownFocusNode;
  bool _obscured = true;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  AppTextFieldVisualState get _state {
    if (widget.visualStateOverride != null) return widget.visualStateOverride!;
    if (!widget.enabled) return AppTextFieldVisualState.disabled;
    if (widget.errorText != null) return AppTextFieldVisualState.error;
    if (_focusNode.hasFocus) return AppTextFieldVisualState.focused;
    return AppTextFieldVisualState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final isError = state == AppTextFieldVisualState.error;
    final isDisabled = state == AppTextFieldVisualState.disabled;

    final (background, borderColor, borderWidth) = switch (state) {
      AppTextFieldVisualState.normal => (AppColors.card, AppColors.border, 1.5),
      AppTextFieldVisualState.focused => (
        AppColors.card,
        AppColors.primary,
        1.5,
      ),
      AppTextFieldVisualState.error => (
        AppColors.errorTint,
        AppColors.error,
        2.0,
      ),
      AppTextFieldVisualState.disabled => (
        AppColors.disabledFill,
        AppColors.borderSubtle,
        1.5,
      ),
    };

    final suffix = widget.isPassword
        ? IconButton(
            onPressed: isDisabled
                ? null
                : () => setState(() => _obscured = !_obscured),
            tooltip: _obscured ? 'Show password' : 'Hide password',
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
          )
        : isError
        ? const Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.smd),
            child: Icon(Icons.error_rounded, size: 20, color: AppColors.error),
          )
        : null;

    final message = widget.errorText ?? widget.helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: AppTextStyles.labelMd.copyWith(
              color: isDisabled ? AppColors.textDisabled : AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedContainer(
          // No animation with reduced motion or on timed exam screens.
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.inputRadius,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: state == AppTextFieldVisualState.focused
                ? AppShadows.focusRing
                : null,
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.smd,
                  ),
                  child: Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              Expanded(
                child: Semantics(
                  label: widget.label,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    obscureText: widget.isPassword && _obscured,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    autofillHints: widget.autofillHints,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.autocorrect,
                    spellCheckConfiguration: widget.autocorrect
                        ? null
                        : const SpellCheckConfiguration.disabled(),
                    style: AppTextStyles.bodyLg.copyWith(
                      color: isDisabled
                          ? AppColors.textDisabled
                          : AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isError) ...[
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: 1),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: AppColors.errorText,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Expanded(
                child: Semantics(
                  liveRegion: isError,
                  child: Text(
                    message,
                    style: AppTextStyles.bodySm.copyWith(
                      color: isError
                          ? AppColors.errorText
                          : AppColors.textMuted,
                      fontWeight: isError ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
