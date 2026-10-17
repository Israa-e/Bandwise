import 'package:flutter/material.dart';

import '../../../core/models/skill.dart';
import '../../../core/theme/skill_style.dart';
import '../../../core/widgets/widgets.dart';

/// Placeholder for a skill whose practice isn't built yet.
class SkillComingSoonScreen extends StatelessWidget {
  const SkillComingSoonScreen({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    return ComingSoonScaffold(
      title: skill.label,
      icon: skill.icon,
      heading: '${skill.label} practice is coming soon',
      message:
          'In the meantime, you can practise Reading and Writing from the '
          'Practice tab.',
    );
  }
}
