import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Placeholder until notifications are built.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScaffold(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      heading: 'No notifications yet',
      message: 'Reminders and updates will appear here.',
    );
  }
}
