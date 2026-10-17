import 'package:flutter/material.dart';

import '../../../../core/models/skill.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/home_summary.dart';

/// 2x2 grid of skill cards. Badges show accuracy or recent activity, never a
/// band.
class SkillShortcuts extends StatelessWidget {
  const SkillShortcuts({
    super.key,
    required this.summary,
    required this.focusSkills,
    required this.today,
    required this.onOpen,
    required this.onViewAll,
  });

  final HomeSummary summary;

  /// Priority skills chosen in onboarding.
  final Set<Skill> focusSkills;
  final DateTime today;
  final ValueChanged<Skill> onOpen;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    Widget card(Skill skill) => _SkillCard(
      skill: skill,
      badge: skillBadgeLabel(skill, summary.activityFor(skill), today),
      focus: focusSkills.contains(skill),
      onTap: () => onOpen(skill),
    );

    Widget row(Skill a, Skill b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: card(a)),
          const SizedBox(width: AppSpacing.smd),
          Expanded(child: card(b)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: const Text(
                  'Skill shortcuts',
                  style: AppTextStyles.headlineSm,
                ),
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        row(Skill.listening, Skill.reading),
        const SizedBox(height: AppSpacing.smd),
        row(Skill.writing, Skill.speaking),
      ],
    );
  }
}

/// Badge text for a skill card, or null for "Start" (no attempts yet).
///
/// Listening and Reading show accuracy; Writing and Speaking show recent
/// activity.
String? skillBadgeLabel(Skill skill, SkillActivity activity, DateTime today) {
  if (!activity.hasAttempts) return null;
  switch (skill) {
    case Skill.listening:
    case Skill.reading:
      final accuracy = activity.accuracyPercent;
      return accuracy == null ? null : '$accuracy% accuracy';
    case Skill.writing:
    case Skill.speaking:
      final (one, many) = skill == Skill.writing
          ? ('essay', 'essays')
          : ('session', 'sessions');
      if (activity.thisWeek > 0) {
        final n = activity.thisWeek;
        return '$n ${n == 1 ? one : many} this week';
      }
      final last = activity.lastPracticed;
      return last == null ? null : 'Last $one ${timeAgoLabel(today, last)}';
  }
}

/// Fixed shortcut content per skill, until practice sets come from data.
(String, String) _shortcutContent(Skill skill) => switch (skill) {
  Skill.listening => ('Section 3 prep', 'Multi-speaker discussions'),
  Skill.reading => ('True / False / Not Given', 'Quick verification drills'),
  Skill.writing => ('Task 1 chart reports', 'Describe trends and changes'),
  Skill.speaking => ('Part 2 cue cards', 'Talk for two minutes'),
};

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.badge,
    required this.focus,
    required this.onTap,
  });

  final Skill skill;

  /// Null shows "Start".
  final String? badge;
  final bool focus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _shortcutContent(skill);
    return AppCard(
      onTap: onTap,
      semanticLabel: [
        skill.label,
        title,
        badge ?? 'Not started',
        if (focus) 'Focus skill',
      ].join(', '),
      padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: skill.tint,
                    borderRadius: AppRadii.nestedRadius,
                  ),
                  child: Icon(skill.icon, size: 18, color: skill.color),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (focus)
                  const Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppPill(
                        label: 'Focus',
                        background: AppColors.accent,
                        foreground: AppColors.onAccent,
                        size: AppPillSize.small,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.smd),
            Text(
              skill.label.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(title, style: AppTextStyles.labelLg),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const Spacer(),
            const SizedBox(height: AppSpacing.smd),
            _Badge(skill: skill, label: badge),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.skill, required this.label});

  final Skill skill;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final start = label == null;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: start ? AppColors.primaryTint : skill.tint,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label ?? 'Start',
              style: AppTextStyles.tabular(
                AppTextStyles.labelSm,
              ).copyWith(color: start ? AppColors.primary : AppColors.text),
            ),
          ),
          if (start) ...[
            const SizedBox(width: AppSpacing.xxs),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}
