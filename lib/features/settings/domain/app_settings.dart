import 'package:flutter/foundation.dart';

/// Whether animations play.
enum MotionPreference {
  /// Follow the device's accessibility setting.
  system('Device setting'),
  reduced('Reduce'),
  full('Allow');

  const MotionPreference(this.label);

  final String label;

  /// Whether to reduce motion, given the device's own setting.
  bool reduce({required bool deviceReduces}) => switch (this) {
    system => deviceReduces,
    reduced => true,
    full => false,
  };
}

/// App preferences that aren't part of the study plan. The daily reminder
/// is part of the plan (see the onboarding state).
@immutable
class AppSettings {
  const AppSettings({this.motion = MotionPreference.system});

  final MotionPreference motion;

  AppSettings copyWith({MotionPreference? motion}) =>
      AppSettings(motion: motion ?? this.motion);

  Map<String, dynamic> toJson() => {'motion': motion.name};

  static AppSettings fromJson(Map<String, dynamic> json) => AppSettings(
    motion:
        MotionPreference.values
            .where((m) => m.name == json['motion'])
            .firstOrNull ??
        MotionPreference.system,
  );
}

/// Where app preferences are stored.
abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<void> clear();
}
