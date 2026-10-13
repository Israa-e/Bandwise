import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum InfoBannerType { info, success, warning, error }

/// Inline notice with an icon, optional title, message and optional action.
///
/// Use for disclaimers ("This is not an official level"), tips, and inline
/// errors with a retry.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.type = InfoBannerType.info,
    this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final InfoBannerType type;
  final String? title;

  /// Defaults to an icon matching [type].
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (background, accent, defaultIcon, titleColor) = switch (type) {
      InfoBannerType.info => (
        AppColors.primaryTint,
        AppColors.primary,
        Icons.info_outline_rounded,
        AppColors.text,
      ),
      InfoBannerType.success => (
        AppColors.successTint,
        AppColors.success,
        Icons.check_circle_outline_rounded,
        AppColors.text,
      ),
      InfoBannerType.warning => (
        AppColors.warningTint,
        AppColors.warning,
        Icons.warning_amber_rounded,
        AppColors.text,
      ),
      InfoBannerType.error => (
        AppColors.errorTint,
        AppColors.error,
        Icons.error_outline_rounded,
        AppColors.errorText,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: type == InfoBannerType.error,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.smd + 2,
          AppSpacing.smd,
          AppSpacing.smd + 2,
          AppSpacing.smd,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.buttonRadius,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 1),
              child: Icon(icon ?? defaultIcon, size: 20, color: accent),
            ),
            const SizedBox(width: AppSpacing.smd - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: AppTextStyles.labelLg.copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: AppTextStyles.bodySm.copyWith(
                      color: type == InfoBannerType.error
                          ? AppColors.errorText
                          : AppColors.text,
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: AlignmentDirectional.centerStart,
                        minimumSize: const Size(48, 36),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        foregroundColor: type == InfoBannerType.error
                            ? AppColors.errorText
                            : AppColors.primary,
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
