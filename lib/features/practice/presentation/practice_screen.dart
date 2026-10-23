import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/skill.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';

/// The Practice tab: one card per skill, each opening its hub.
///
/// [initialSkill] comes from the `skill` query parameter, e.g. when a skill
/// card on Home opens this tab, and is shown highlighted. The study plan's
/// focus skills are tagged "Focus".
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key, this.initialSkill});

  final Skill? initialSkill;

  static bool isAvailable(Skill skill) => hubFor(skill) != null;

  /// The skill's practice hub, or null while it's coming soon.
  static String? hubFor(Skill skill) => switch (skill) {
    Skill.listening => AppRoutes.listeningHub,
    Skill.reading => AppRoutes.readingHub,
    Skill.writing => AppRoutes.writingHub,
    Skill.speaking => AppRoutes.speakingHub,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus =
        ref.watch(onboardingControllerProvider).value?.skills ?? const {};
    Widget card(Skill skill) => PracticeSkillCard(
      skill: skill,
      selected: skill == initialSkill,
      focus: focus.contains(skill),
      onTap: () =>
          context.push(hubFor(skill) ?? AppRoutes.practiceSkill(skill)),
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

    return Scaffold(
      appBar: const TabTopBar(title: 'Practice'),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.page,
          AppSpacing.smd,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Choose a skill to practise with exam-style questions.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          row(Skill.listening, Skill.reading),
          const SizedBox(height: AppSpacing.smd),
          row(Skill.writing, Skill.speaking),
        ],
      ),
    );
  }
}

/// A skill on the Practice tab, in the skill's colors.
class PracticeSkillCard extends StatelessWidget {
  const PracticeSkillCard({
    super.key,
    required this.skill,
    required this.selected,
    required this.onTap,
    this.focus = false,
  });

  final Skill skill;
  final bool selected;
  final VoidCallback onTap;

  /// One of the study plan's focus skills.
  final bool focus;

  @override
  Widget build(BuildContext context) {
    final available = PracticeScreen.isAvailable(skill);
    final subtitle = switch (skill) {
      Skill.reading =>
        'Passages with True / False / Not Given, headings and more',
      Skill.listening =>
        'Conversations and discussions with form, choice and matching '
            'questions',
      Skill.writing => 'Task 1 reports and Task 2 essays, with feedback',
      Skill.speaking =>
        'Record answers to all three parts, then review them yourself',
    };
    return AppCard(
      key: ValueKey('practice-${skill.name}'),
      selected: selected,
      color: selected ? null : skill.tint,
      onTap: onTap,
      semanticLabel: [
        skill.label,
        available ? subtitle : 'Coming soon',
        if (focus) 'Focus skill',
      ].join(', '),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadii.nestedRadius,
                  ),
                  child: Icon(skill.icon, color: skill.color, size: 22),
                ),
                if (focus)
                  const Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppPill(
                        key: ValueKey('focusTag'),
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
            Text(skill.label, style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const Spacer(),
            const SizedBox(height: AppSpacing.smd),
            if (available)
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Start',
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              )
            else
              const AppPill(
                label: 'Coming soon',
                background: AppColors.card,
                foreground: AppColors.textMuted,
                size: AppPillSize.small,
              ),
          ],
        ),
      ),
    );
  }
}
