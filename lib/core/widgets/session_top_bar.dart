import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'progress.dart';
import 'top_bars.dart';

/// Top bar for full-screen sessions (lessons, reviews): a close button and,
/// optionally, a progress bar with a counter such as "3/6" or "3 of 8".
class SessionTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SessionTopBar({
    super.key,
    required this.onClose,
    this.closeTooltip = 'Close',
    this.progress,
    this.counter,
    this.progressLabel,
  });

  final VoidCallback onClose;
  final String closeTooltip;

  /// 0.0 to 1.0; null hides the progress bar and counter.
  final double? progress;
  final String? counter;

  /// Semantic label for the progress bar.
  final String? progressLabel;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    final counter = this.counter;
    return TopBarSurface(
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              end: AppSpacing.page,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  tooltip: closeTooltip,
                  icon: const Icon(Icons.close_rounded, color: AppColors.text),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(48),
                    highlightColor: AppColors.primaryTint,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppLinearProgress(
                      value: progress,
                      height: 10,
                      semanticLabel: progressLabel,
                    ),
                  ),
                  if (counter != null) ...[
                    const SizedBox(width: AppSpacing.smd),
                    Text(
                      counter,
                      style: AppTextStyles.tabular(
                        AppTextStyles.labelMd,
                      ).copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar for a session with a title: close, the title (and optional
/// subtitle such as "Draft saved"), and an optional trailing widget such as
/// a timer.
class TitledSessionTopBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TitledSessionTopBar({
    super.key,
    required this.title,
    required this.onClose,
    this.closeTooltip = 'Close',
    this.subtitle,
    this.trailing,
  });

  final String title;
  final VoidCallback onClose;
  final String closeTooltip;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    return TopBarSurface(
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              end: AppSpacing.page,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  tooltip: closeTooltip,
                  icon: const Icon(Icons.close_rounded, color: AppColors.text),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(48),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ?subtitle,
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
