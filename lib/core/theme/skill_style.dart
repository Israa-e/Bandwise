import 'package:flutter/material.dart';

import '../models/skill.dart';
import 'app_colors.dart';

/// Color and icon tokens for each [Skill].
extension SkillStyle on Skill {
  Color get color => switch (this) {
    Skill.listening => AppColors.listening,
    Skill.reading => AppColors.reading,
    Skill.writing => AppColors.writing,
    Skill.speaking => AppColors.speaking,
  };

  Color get tint => switch (this) {
    Skill.listening => AppColors.listeningTint,
    Skill.reading => AppColors.readingTint,
    Skill.writing => AppColors.writingTint,
    Skill.speaking => AppColors.speakingTint,
  };

  IconData get icon => switch (this) {
    Skill.listening => Icons.headphones_rounded,
    Skill.reading => Icons.menu_book_rounded,
    Skill.writing => Icons.edit_note_rounded,
    Skill.speaking => Icons.mic_rounded,
  };
}
