import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// A card with a tappable header that shows or hides its content. Not
/// animated, so it suits timed screens.
class CollapsibleCard extends StatefulWidget {
  const CollapsibleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  late var _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle;
    return AppCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.smd,
                  AppSpacing.smd,
                  AppSpacing.smd,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: AppTextStyles.labelLg),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
