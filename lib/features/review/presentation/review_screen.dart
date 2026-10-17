import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Placeholder until vocabulary review is built.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScaffold(
      title: 'Review',
      icon: Icons.style_rounded,
      heading: 'Review is coming soon',
      message: 'Spaced review of your saved vocabulary will appear here.',
    );
  }
}
