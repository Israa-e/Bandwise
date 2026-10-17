import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progress_repository.dart';
import '../domain/progress_state.dart';

/// Stores progress on the device with shared_preferences.
class PrefsProgressRepository implements ProgressRepository {
  static const _key = 'progress.v1';

  @override
  Future<ProgressState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const ProgressState();
    try {
      return ProgressState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable data (e.g. from an older format): start fresh.
      return const ProgressState();
    }
  }

  @override
  Future<void> save(ProgressState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
