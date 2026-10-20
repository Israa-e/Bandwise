import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs_settings_repository.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => const PrefsSettingsRepository(),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

/// App preferences. Every change is persisted.
class SettingsController extends AsyncNotifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<AppSettings> build() => _repository.load();

  Future<void> setMotion(MotionPreference motion) async {
    final next = (state.value ?? await future).copyWith(motion: motion);
    state = AsyncData(next);
    await _repository.save(next);
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const AsyncData(AppSettings());
  }
}

/// Applies the motion preference below it: widgets that check
/// [MediaQuery.disableAnimationsOf] (the lesson and review celebrations,
/// page transitions) follow the in-app override, or the device setting by
/// default.
class MotionScope extends ConsumerWidget {
  const MotionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference =
        ref.watch(settingsControllerProvider).value?.motion ??
        MotionPreference.system;
    final media = MediaQuery.of(context);
    final reduce = preference.reduce(deviceReduces: media.disableAnimations);
    final theme = Theme.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: reduce),
      child: reduce
          ? Theme(
              data: theme.copyWith(
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: {
                    for (final platform in TargetPlatform.values)
                      platform: const _NoTransitionBuilder(),
                  },
                ),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Shows the new page at once.
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
