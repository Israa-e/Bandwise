import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/speaking_devices.dart';

/// Keeps recordings in the app's documents folder, under speaking/. On the
/// web the recorder returns blob URLs, which last only for the session.
class FileRecordingStore implements RecordingStore {
  const FileRecordingStore();

  /// Set once a recording file has been made, so deleting everything only
  /// touches the file system when there can be something to delete.
  static const _usedKey = 'speaking.recordings.used.v1';

  Future<Directory> _root() async =>
      Directory('${(await getApplicationDocumentsDirectory()).path}/speaking');

  @override
  Future<String> newPath(String attemptId, String questionId) async {
    final name = '${questionId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    if (kIsWeb) return name;
    await (await SharedPreferences.getInstance()).setBool(_usedKey, true);
    final dir = Directory('${(await _root()).path}/$attemptId');
    await dir.create(recursive: true);
    return '${dir.path}/$name';
  }

  @override
  Future<void> delete(String path) async {
    if (kIsWeb) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteAll() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_usedKey) ?? false)) return;
    final root = await _root();
    if (await root.exists()) await root.delete(recursive: true);
    await prefs.remove(_usedKey);
  }
}
