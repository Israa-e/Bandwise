import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Placeholder layout matching Home's sections while data loads.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key, required this.padding});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget pair(double height) => Row(
      children: [
        Expanded(child: SkeletonCard(height: height)),
        const SizedBox(width: AppSpacing.smd),
        Expanded(child: SkeletonCard(height: height)),
      ],
    );

    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          children: [
            const SkeletonBox(width: 160, height: 28),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: 220, height: 16),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              children: [
                Expanded(child: SkeletonCard(height: 104)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: SkeletonCard(height: 104)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: SkeletonCard(height: 104)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonCard(height: 196),
            const SizedBox(height: AppSpacing.lg),
            const SkeletonBox(width: 140, height: 22),
            const SizedBox(height: AppSpacing.smd),
            pair(150),
            const SizedBox(height: AppSpacing.smd),
            pair(150),
          ],
        ),
      ),
    );
  }
}
