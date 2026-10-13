import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: const EmptyStateView(
        icon: Icons.edit_note_rounded,
        title: 'Practice',
        message: 'Skill practice and mock exams will appear here.',
      ),
    );
  }
}
