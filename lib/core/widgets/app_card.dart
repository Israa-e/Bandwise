import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// White card with the standard radius, micro-border and shadow.
///
/// Pass [color] to render a flat tinted card (e.g. a skill tint); tinted cards
/// drop the shadow so they sit flat on the background. Pass [onTap] to make
/// the whole card tappable. [selected] gives the selected-card look: a light
/// primary surface with a 2px primary border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(AppSpacing.card),
    this.color,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tinted = color != null;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardRadius,
        boxShadow: tinted ? null : AppShadows.card,
      ),
      child: Material(
        color: selected ? AppColors.selectedSurface : color ?? AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: selected
              ? const BorderSide(color: AppColors.primary, width: 2)
              : tinted
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null && semanticLabel == null) return card;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: card,
    );
  }
}
