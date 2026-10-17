import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A section heading, exposed to screen readers as a header.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTextStyles.headlineSm),
      ),
    );
  }
}

/// A pill-shaped filter or choice chip. Selected: primary border and text.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.selectedSurface : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillRadius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: selected ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
