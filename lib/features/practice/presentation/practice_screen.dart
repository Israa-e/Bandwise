import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// Placeholder Practice tab with a skill picker.
///
/// [initialSkill] comes from the `skill` query parameter, e.g. when a skill
/// shortcut on Home opens this tab.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.initialSkill});

  final Skill? initialSkill;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late Skill? _skill = widget.initialSkill;

  @override
  void didUpdateWidget(PracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSkill != oldWidget.initialSkill) {
      _skill = widget.initialSkill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.page,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in Skill.values)
                  _SkillOption(
                    skill: s,
                    selected: s == skill,
                    onTap: () => setState(() => _skill = s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: EmptyStateView(
              icon: skill?.icon ?? Icons.edit_note_rounded,
              title: skill == null ? 'Practice' : '${skill.label} practice',
              message: skill == null
                  ? 'Skill practice and mock exams will appear here.'
                  : '${skill.label} practice sets are coming soon.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillOption extends StatelessWidget {
  const _SkillOption({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  final Skill skill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillRadius,
            border: selected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: SkillChip(skill: skill),
        ),
      ),
    );
  }
}
