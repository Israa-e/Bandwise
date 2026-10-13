import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Inter type scale. Line heights and letter spacing follow the design spec.
abstract final class AppTextStyles {
  static const fontFamily = 'Inter';

  static const _tabular = [FontFeature.tabularFigures()];

  static const headlineXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
    color: AppColors.text,
  );

  static const headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.36,
    color: AppColors.text,
  );

  static const headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.text,
  );

  static const headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.18,
    color: AppColors.text,
  );

  static const bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    color: AppColors.text,
  );

  static const bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.065,
    color: AppColors.text,
  );

  static const labelLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    color: AppColors.text,
  );

  static const labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
    color: AppColors.text,
  );

  static const labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.44,
    color: AppColors.text,
  );

  /// Button label.
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  /// Returns [style] with tabular figures, for timers, scores and counters.
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: _tabular);
}
