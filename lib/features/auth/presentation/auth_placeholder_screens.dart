import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';

/// Placeholder until auth is built.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AuthTopBar(),
      body: EmptyStateView(
        icon: Icons.lock_outline_rounded,
        title: 'Log in',
        message: 'Logging in is coming soon.',
      ),
    );
  }
}

/// Placeholder until auth is built. Reached from the plan screen when the
/// user chose "Sign up with email". Onboarding completes here, so a restart
/// before this point returns to the plan.
class CreateAccountScreen extends ConsumerWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const AuthTopBar(),
      body: EmptyStateView(
        icon: Icons.person_add_alt_1_outlined,
        title: 'Create your account',
        message:
            'Account creation is coming soon. Your plan is saved on this '
            'device.',
        action: AppButton.primary(
          label: 'Continue to Home',
          expand: false,
          onPressed: () async {
            await ref.read(onboardingControllerProvider.notifier).complete();
            if (context.mounted) context.go(AppRoutes.home);
          },
        ),
      ),
    );
  }
}
