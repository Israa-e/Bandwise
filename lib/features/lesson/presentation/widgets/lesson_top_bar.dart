import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Lesson top bar: a close button and, during exercises, a progress bar
/// with "3/6".
class LessonTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LessonTopBar({super.key, required this.onClose, this.step, this.total});

  final VoidCallback onClose;

  /// Exercises done so far; null hides the progress bar.
  final int? step;
  final int? total;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final step = this.step;
    final total = this.total;
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
                  tooltip: 'Close lesson',
                  icon: const Icon(Icons.close_rounded, color: AppColors.text),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(48),
                    highlightColor: AppColors.primaryTint,
                  ),
                ),
                if (step != null && total != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppLinearProgress(
                      value: total == 0 ? 0 : step / total,
                      height: 10,
                      semanticLabel: 'Lesson progress',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.smd),
                  Text(
                    '$step/$total',
                    style: AppTextStyles.tabular(
                      AppTextStyles.labelMd,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
