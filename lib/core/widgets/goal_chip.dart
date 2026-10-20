import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_chip.dart';

/// The learner's own target, e.g. "Goal 7.0". A goal, never a score.
class GoalChip extends StatelessWidget {
  const GoalChip({super.key, required this.value});

  /// e.g. "7.0".
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your goal: $value',
      excludeSemantics: true,
      child: AppPill(
        label: 'Goal $value',
        icon: Icons.flag_rounded,
        background: AppColors.accent,
        foreground: AppColors.onAccent,
      ),
    );
  }
}
