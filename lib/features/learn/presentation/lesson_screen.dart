import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Placeholder until lessons are built. Opens outside the tab shell, so the
/// bottom nav is hidden.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScaffold(
      title: 'Lesson',
      icon: Icons.menu_book_rounded,
      heading: 'Lessons are coming soon',
      message: 'Your progress is saved. You can pick up from here later.',
    );
  }
}
