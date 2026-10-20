import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/writing.dart';
import '../domain/writing_repository.dart';
import '../domain/writing_submission.dart';
import 'writing_content.dart';

/// Serves the bundled [writingTasks].
class MockWritingTaskRepository implements WritingTaskRepository {
  const MockWritingTaskRepository();

  @override
  Future<List<WritingTask>> fetchTasks() async => writingTasks;
}

/// Stores drafts and submissions on the device.
class PrefsWritingRepository implements WritingRepository {
  const PrefsWritingRepository();

  static const _draftsKey = 'writing.drafts.v1';
  static const _submissionsKey = 'writing.submissions.v1';

  Future<Map<String, dynamic>> _readMap(String key) async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(String key, Object value) async =>
      (await SharedPreferences.getInstance()).setString(key, jsonEncode(value));

  @override
  Future<Map<String, WritingDraft>> loadDrafts() async {
    final json = await _readMap(_draftsKey);
    return {
      for (final e in json.entries)
        e.key: WritingDraft.fromJson(e.value as Map<String, dynamic>),
    };
  }

  @override
  Future<void> saveDraft(WritingDraft draft) async {
    final json = await _readMap(_draftsKey);
    json[draft.id] = draft.toJson();
    await _write(_draftsKey, json);
  }

  @override
  Future<void> deleteDraft(String id) async {
    final json = await _readMap(_draftsKey);
    if (json.remove(id) != null) await _write(_draftsKey, json);
  }

  @override
  Future<List<WritingSubmission>> loadSubmissions() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _submissionsKey,
    );
    if (raw == null) return [];
    try {
      return [
        for (final s in jsonDecode(raw) as List)
          WritingSubmission.fromJson(s as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSubmission(WritingSubmission submission) async {
    final all = await loadSubmissions();
    final i = all.indexWhere((s) => s.id == submission.id);
    if (i >= 0) {
      all[i] = submission;
    } else {
      all.add(submission);
    }
    await _write(_submissionsKey, [for (final s in all) s.toJson()]);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftsKey);
    await prefs.remove(_submissionsKey);
  }
}
