import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/presentation/progress_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../writing/presentation/writing_providers.dart';

/// What "Reset progress" deletes. The study plan and settings stay.
const resetProgressItems = [
  'Lessons completed and their results',
  'XP, streak and study time',
  'Saved mistakes, vocabulary reviews and review dates',
  'Reading and listening practice attempts',
  'Essays, drafts and their feedback',
  'Achievements (they are worked out from the above)',
];

/// What "Delete all data" deletes on top of [resetProgressItems].
const deleteAllExtraItems = [
  'Your study plan: goal, exam date, daily time, focus skills, level '
      'and placement answers',
  'Settings: daily reminder and reduce motion',
];

/// The app's version, e.g. "0.1.0 (1)".
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});

/// Deletes the learning history ([resetProgressItems]); keeps the
/// onboarding answers and settings.
Future<void> resetProgress(WidgetRef ref) async {
  await ref.read(progressControllerProvider.notifier).reset();
  await ref.read(writingRepositoryProvider).clear();
  ref
    ..invalidate(writingSubmissionsProvider)
    ..invalidate(writingDraftsProvider);
}

/// Deletes everything stored on this device. The app starts again at
/// Welcome.
Future<void> deleteAllData(WidgetRef ref) async {
  await resetProgress(ref);
  await ref.read(settingsControllerProvider.notifier).clear();
  await ref.read(onboardingControllerProvider.notifier).reset();
}
