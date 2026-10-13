import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const EmptyStateView(
        icon: Icons.insights_rounded,
        title: 'Progress',
        message: 'Your study time, accuracy and history will appear here.',
      ),
    );
  }
}
