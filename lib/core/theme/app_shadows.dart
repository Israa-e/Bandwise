import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Shadow tokens.
abstract final class AppShadows {
  /// Resting card: 0 4 16 rgba(37,36,58,0.06).
  static final card = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// Raised surfaces such as the bottom nav and sticky footers.
  static final raised = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.08),
      offset: const Offset(0, -4),
      blurRadius: 24,
    ),
  ];

  /// Under a top bar while content is scrolled beneath it.
  static final topBar = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.08),
      offset: const Offset(0, 1),
      blurRadius: 8,
    ),
  ];

  /// Glow under the primary button.
  static final primaryButton = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      offset: const Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  /// 3px focus ring drawn outside an input's border.
  static const focusRing = [
    BoxShadow(color: AppColors.focusRing, spreadRadius: 3),
  ];
}
