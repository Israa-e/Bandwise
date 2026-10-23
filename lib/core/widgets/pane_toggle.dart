import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One tab of a [PaneToggle]. [id] keys it as `pane-<id>`.
typedef PaneTab<T> = ({T value, String id, String label, IconData icon});

/// The phone toggle between two panes of a session, e.g. the passage and
/// the questions. Wider layouts show the panes side by side instead.
class PaneToggle<T> extends StatelessWidget {
  const PaneToggle({
    super.key,
    required this.selected,
    required this.tabs,
    required this.onChanged,
  });

  final T selected;
  final List<PaneTab<T>> tabs;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(PaneTab<T> t) {
      final isSelected = t.value == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          child: Material(
            color: isSelected ? AppColors.card : Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.nestedRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('pane-${t.id}'),
              onTap: () => onChanged(t.value),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        t.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMd.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        0,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.disabledFill,
          borderRadius: AppRadii.buttonRadius,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xxs),
          child: Row(
            children: [
              for (final (i, t) in tabs.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xxs),
                tab(t),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
