import 'package:flutter/painting.dart';

/// Bandwise color tokens.
///
/// These are the only colors allowed in the app. Screens and widgets must
/// reference these tokens instead of hardcoding color values. Derived tokens
/// (muted text, borders, tracks) are the base tokens at a fixed opacity.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6558D3);
  static const onPrimary = Color(0xFFFFFFFF);
  static const accent = Color(0xFFDDF6A7);
  static const onAccent = text;

  // Surfaces
  static const background = Color(0xFFF7F6FC);
  static const card = Color(0xFFFFFFFF);

  /// Background of a selected card (paired with a 2px [primary] border).
  static const selectedSurface = Color(0xFFF5F3FF);

  /// Light primary wash for icon containers, info banners and hover fills.
  /// Opaque (primary @ 10% over white) so shadows don't show through.
  static const primaryTint = Color(0xFFF0EEFB);

  // Text
  static const text = Color(0xFF25243A);
  static const textMuted = Color(0xB325243A); // text @ 70%
  static const textDisabled = Color(0x6625243A); // text @ 40%

  // Lines
  static const border = Color(0x1F25243A); // text @ 12%
  static const borderSubtle = Color(0x0A25243A); // text @ 4%
  static const disabledFill = Color(0x1425243A); // text @ 8%

  /// Unfilled part of progress bars, rings and step segments.
  static const track = Color(0x266558D3); // primary @ 15%

  /// Past-day bars in activity charts (today uses [primary]).
  static const chartBar = Color(0x596558D3); // primary @ 35%

  /// Focus ring around inputs.
  static const focusRing = Color(0x266558D3); // primary @ 15%

  // Status
  static const success = Color(0xFF38A169);
  static const successTint = Color(0xFFEDFDF5);
  static const warning = Color(0xFFE29A36);
  static const warningTint = Color(0xFFFEF9EE);

  /// Error color for borders and icons.
  static const error = Color(0xFFE5484D);

  /// Error color for text (higher contrast than [error]).
  static const errorText = Color(0xFFB42318);

  /// Opaque (error @ ~8% over white) so shadows don't show through.
  static const errorTint = Color(0xFFFDF0F0);

  // Skills
  static const listening = Color(0xFF7BA7F7);
  static const listeningTint = Color(0xFFEEF4FE);
  static const reading = Color(0xFF70C2B4);
  static const readingTint = Color(0xFFEDF8F5);
  static const writing = Color(0xFFF69E7B);
  static const writingTint = Color(0xFFFEF4F0);
  static const speaking = Color(0xFFA07BE6);
  static const speakingTint = Color(0xFFF5F1FD);

  /// Shadow base color (text color; opacity is applied in [AppShadows]).
  static const shadow = text;
}
