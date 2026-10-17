import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Static placeholder block shown while content loads.
///
/// Not animated, so it is safe on any screen.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadii.nestedRadius,
  });

  /// Null to fill the available width.
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.disabledFill,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// A card-shaped [SkeletonBox] with the card radius.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(height: height, borderRadius: AppRadii.cardRadius);
  }
}
