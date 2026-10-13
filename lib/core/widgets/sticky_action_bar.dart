import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom area that stays above the keyboard and safe area, holding the
/// screen's main action(s).
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: AppShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.smd,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}
