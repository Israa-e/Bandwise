import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Stores app preferences on the device.
class PrefsSettingsRepository implements SettingsRepository {
  const PrefsSettingsRepository();

  static const _key = 'settings.v1';

  @override
  Future<AppSettings> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async =>
      (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(settings.toJson()),
      );

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
