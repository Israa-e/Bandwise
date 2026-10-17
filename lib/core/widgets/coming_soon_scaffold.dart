import 'package:flutter/material.dart';

import 'empty_state_view.dart';
import 'top_bars.dart';

/// Full screen for a destination that isn't built yet: back button, title
/// and an empty state.
class ComingSoonScaffold extends StatelessWidget {
  const ComingSoonScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.heading,
    required this.message,
  });

  /// Top bar title.
  final String title;
  final IconData icon;
  final String heading;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(title)),
      body: EmptyStateView(icon: icon, title: heading, message: message),
    );
  }
}
