import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: EmptyStateView(
        icon: Icons.person_rounded,
        title: 'Profile',
        message: 'Your account, goals and settings will appear here.',
        action: kDebugMode
            ? Column(
                children: [
                  AppButton.ghost(
                    label: 'Component gallery',
                    leadingIcon: Icons.widgets_outlined,
                    onPressed: () => context.push(AppRoutes.componentGallery),
                  ),
                  AppButton.ghost(
                    label: 'Reset onboarding',
                    leadingIcon: Icons.restart_alt_rounded,
                    onPressed: () async {
                      await ref
                          .read(onboardingControllerProvider.notifier)
                          .reset();
                      if (context.mounted) context.go(AppRoutes.splash);
                    },
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
