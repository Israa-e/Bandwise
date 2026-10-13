import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: EmptyStateView(
        icon: Icons.person_rounded,
        title: 'Profile',
        message: 'Your account, goals and settings will appear here.',
        action: kDebugMode
            ? AppButton.ghost(
                label: 'Component gallery',
                leadingIcon: Icons.widgets_outlined,
                onPressed: () => context.push(AppRoutes.componentGallery),
              )
            : null,
      ),
    );
  }
}
