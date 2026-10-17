import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../learn/domain/course.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_state.dart';
import 'progress_migration.dart';

/// Stores progress on the device with shared_preferences.
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository({required this.loadCourse});

  static const _key = 'progress.v1';

  /// Needed to migrate progress saved in an older format.
  final Future<Course> Function() loadCourse;

  @override
  Future<ProgressState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const ProgressState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final migrated = migrateProgressJson(json, await loadCourse());
      final state = ProgressState.fromJson(migrated);
      if (!identical(migrated, json)) await save(state);
      return state;
    } catch (_) {
      // Unreadable data: start fresh.
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
