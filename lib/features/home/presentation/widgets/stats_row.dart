import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Three small cards: streak, total XP and the daily goal ring.
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.streakDays,
    required this.totalXp,
    required this.xpToday,
    required this.minutesToday,
    required this.dailyGoal,
  });

  final int streakDays;
  final int totalXp;
  final int xpToday;
  final int minutesToday;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _streakCard()),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _xpCard()),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _goalCard()),
        ],
      ),
    );
  }

  Widget _streakCard() {
    final unit = streakDays == 1 ? 'day' : 'days';
    final (String footer, Color footerColor, bool check) = streakDays == 0
        ? ('Start today', AppColors.textMuted, false)
        : minutesToday > 0
        ? ('Active today', AppColors.textMuted, true)
        : ('Keep it going', AppColors.textMuted, false);
    return _StatCard(
      semanticLabel: 'Streak: $streakDays $unit. $footer',
      icon: Icons.local_fire_department_rounded,
      iconColor: AppColors.warning,
      label: 'Streak',
      value: '$streakDays',
      unit: unit,
      footer: _Footer(text: footer, color: footerColor, check: check),
    );
  }

  Widget _xpCard() {
    final format = NumberFormat.decimalPattern();
    final (String? footer, Color footerColor) = xpToday > 0
        ? ('+${format.format(xpToday)} today', AppColors.primary)
        : totalXp == 0
        ? ('Earn XP in lessons', AppColors.textMuted)
        : (null, AppColors.textMuted);
    return _StatCard(
      semanticLabel: [
        'Total XP: ${format.format(totalXp)}',
        ?footer,
      ].join('. '),
      icon: Icons.bolt_rounded,
      iconColor: AppColors.primary,
      label: 'Total XP',
      value: format.format(totalXp),
      footer: footer == null ? null : _Footer(text: footer, color: footerColor),
    );
  }

  Widget _goalCard() {
    final left = dailyGoal - minutesToday;
    final done = left <= 0;
    final footer = done ? 'Goal met' : '${left}m left';
    return Semantics(
      label:
          'Daily goal: $minutesToday of $dailyGoal minutes. '
          '${done ? 'Goal met' : '$left minutes left'}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          children: [
            Text(
              'Daily goal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppCircularProgress(
              value: dailyGoal == 0 ? 0 : minutesToday / dailyGoal,
              size: 48,
              strokeWidth: 5,
              center: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
                child: FittedBox(
                  child: Text.rich(
                    TextSpan(
                      text: '$minutesToday',
                      children: [
                        TextSpan(
                          text: '/${dailyGoal}m',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: AppTextStyles.tabular(AppTextStyles.labelMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _Footer(
              text: footer,
              color: AppColors.textMuted,
              check: done,
              center: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.semanticLabel,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.unit,
    this.footer,
  });

  final String semanticLabel;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? unit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                style: AppTextStyles.tabular(
                  AppTextStyles.headlineSm,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (footer != null) ...[
              const Spacer(),
              const SizedBox(height: AppSpacing.xxs),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.text,
    required this.color,
    this.check = false,
    this.center = false,
  });

  final String text;
  final Color color;

  /// Leading success check (the text stays [color] for contrast).
  final bool check;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: AppTextStyles.tabular(
        AppTextStyles.labelSm,
      ).copyWith(color: color),
    );
    if (!check) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 12,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(child: label),
      ],
    );
  }
}
