import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../onboarding/presentation/onboarding_navigation.dart';
import '../../profile/presentation/data_controls.dart';
import '../../sync/domain/sync_repository.dart';
import '../../sync/presentation/sync_service.dart';
import '../domain/auth_service.dart';
import 'auth_providers.dart';

/// What deleting the account removes.
const deleteAccountItems = [
  'Your account and sign-in',
  'Progress synced to your account: plan, lessons, XP, streak, reviews '
      'and reading attempts',
  'Essays saved to your account, with their feedback',
  'Everything stored on this device',
];

/// After logging in (or resetting the password): combines this device's
/// data with the account's, then opens the right screen.
///
/// - The account has data and this device has guest progress: the learner
///   chooses (keeping the account's progress is the default).
/// - The account has data: it replaces this device's.
/// - The account is empty: this device's data is uploaded.
Future<void> finishLogin(
  BuildContext context,
  WidgetRef ref,
  AuthUser user,
) async {
  ref.read(authUserProvider.notifier).set(user);
  final sync = ref.read(syncServiceProvider.notifier);
  var mode = AdoptMode.keepAccount;
  try {
    if (!await sync.remoteHasData()) {
      mode = AdoptMode.replaceAccount;
    } else if (await sync.hasLocalProgress()) {
      if (!context.mounted) return;
      mode = await showKeepOrReplaceDialog(context);
    }
  } on SyncException {
    // Offline right after logging in: keep the account's data; the sync
    // retries later.
  }
  await sync.adopt(mode);
  await ref.read(onboardingControllerProvider.notifier).markSignedIn();
  if (context.mounted) await _openAfterAuth(context, ref);
}

/// After signing up with a session: uploads this device's data to the new
/// account and continues.
Future<void> finishSignUp(
  BuildContext context,
  WidgetRef ref,
  AuthUser user,
) async {
  ref.read(authUserProvider.notifier).set(user);
  await ref.read(syncServiceProvider.notifier).adopt(AdoptMode.replaceAccount);
  await ref.read(onboardingControllerProvider.notifier).markSignedIn();
  if (context.mounted) await _openAfterAuth(context, ref);
}

/// Home when the plan is set up, otherwise where onboarding left off.
Future<void> _openAfterAuth(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(onboardingControllerProvider.notifier);
  final plan = await ref.read(onboardingControllerProvider.future);
  if (!context.mounted) return;
  if (plan.completed) {
    context.go(AppRoutes.home);
  } else if (plan.step == OnboardingStep.plan) {
    // Signed up or logged in from the end of onboarding.
    await controller.complete();
    if (context.mounted) context.go(AppRoutes.home);
  } else if (plan.step == OnboardingStep.welcome) {
    await controller.start(asGuest: false);
    if (context.mounted) {
      context.go(onboardingPath(OnboardingStep.targetBand));
    }
  } else {
    context.go(onboardingPath(plan.step));
  }
}

/// Asks how to combine this device's guest progress with an account that
/// already has some. Keeping the account's progress is the default.
Future<AdoptMode> showKeepOrReplaceDialog(BuildContext context) async {
  var choice = AdoptMode.keepAccount;
  final result = await showDialog<AdoptMode>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: const ValueKey('keepOrReplaceDialog'),
        title: const Text('This account already has progress'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This device also has progress from studying as a guest. '
              'Which should your account keep?',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: AppSpacing.md),
            SelectionCard(
              key: const ValueKey('keepAccount'),
              title: "Keep your account's progress",
              subtitle:
                  'Use the progress saved in your account. The guest '
                  'progress on this device is replaced.',
              state: choice == AdoptMode.keepAccount
                  ? SelectionCardState.selected
                  : SelectionCardState.idle,
              onTap: () => setState(() => choice = AdoptMode.keepAccount),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectionCard(
              key: const ValueKey('replaceAccount'),
              title: "Replace it with this device's progress",
              subtitle:
                  "Upload this device's progress. The progress saved in "
                  'your account is replaced and can’t be recovered.',
              state: choice == AdoptMode.replaceAccount
                  ? SelectionCardState.selected
                  : SelectionCardState.idle,
              onTap: () => setState(() => choice = AdoptMode.replaceAccount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, choice),
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
  return result ?? AdoptMode.keepAccount;
}

/// Signs out after a final sync; this device's data is cleared and the app
/// returns to Welcome.
Future<void> signOutFlow(BuildContext context, WidgetRef ref) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Sign out?',
    message:
        'Your progress is synced to your account first. Then it is removed '
        'from this device; log in again to get it back.',
    confirmLabel: 'Sign out',
    destructive: false,
  );
  if (!confirmed || !context.mounted) return;
  final sync = ref.read(syncServiceProvider.notifier);
  final synced = await sync.flush();
  if (!synced) {
    if (!context.mounted) return;
    final anyway = await showConfirmDialog(
      context,
      title: "Couldn't sync",
      message:
          "You're offline or the sync failed. If you sign out now, changes "
          'since your last sync will be lost.',
      confirmLabel: 'Sign out anyway',
    );
    if (!anyway) return;
  }
  sync.stop();
  await ref.read(authServiceProvider).signOut();
  ref.read(authUserProvider.notifier).set(null);
  await _clearDevice(ref);
  if (context.mounted) context.go(AppRoutes.welcome);
}

/// Deletes the account on the server (after a confirmation that names what
/// goes), then clears this device and returns to Welcome. On failure the
/// account and data stay, and a message explains.
Future<void> deleteAccountFlow(BuildContext context, WidgetRef ref) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete your account?',
    message: 'This permanently deletes:',
    items: deleteAccountItems,
    footnote:
        "This can't be undone. You'll start again from the Welcome "
        'screen.',
    confirmLabel: 'Delete account',
  );
  if (!confirmed || !context.mounted) return;
  final sync = ref.read(syncServiceProvider.notifier)..stop();
  try {
    await ref.read(authServiceProvider).deleteAccount();
  } on AuthFailure catch (e) {
    // Still signed in: keep syncing.
    await sync.adopt(AdoptMode.keepAccount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text("Your account wasn't deleted. ${e.message}")),
      );
    return;
  }
  ref.read(authUserProvider.notifier).set(null);
  await _clearDevice(ref);
  if (context.mounted) context.go(AppRoutes.welcome);
}

Future<void> _clearDevice(WidgetRef ref) async {
  await deleteAllData(ref);
  await ref.read(syncServiceProvider.notifier).clearLocalState();
}
