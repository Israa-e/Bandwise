import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const EmptyStateView(
        icon: Icons.home_rounded,
        title: 'Home',
        message: 'Your daily plan, streak and next lesson will appear here.',
      ),
    );
  }
}
