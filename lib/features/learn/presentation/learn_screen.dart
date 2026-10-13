import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: const EmptyStateView(
        icon: Icons.menu_book_rounded,
        title: 'Learn',
        message: 'Your learning path and units will appear here.',
      ),
    );
  }
}
