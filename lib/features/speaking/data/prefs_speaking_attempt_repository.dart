import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/speaking_attempt.dart';
import '../domain/speaking_repository.dart';

/// Keeps attempts (recording paths, transcripts, notes, self-assessment) on
/// the device. Not part of what is synced.
class PrefsSpeakingAttemptRepository implements SpeakingAttemptRepository {
  const PrefsSpeakingAttemptRepository();

  static const key = 'speaking.attempts.v1';

  @override
  Future<List<SpeakingAttempt>> loadAttempts() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return [];
    try {
      return [
        for (final a in jsonDecode(raw) as List)
          SpeakingAttempt.fromJson(a as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveAttempt(SpeakingAttempt attempt) async {
    final all = await loadAttempts();
    final i = all.indexWhere((a) => a.id == attempt.id);
    if (i >= 0) {
      all[i] = attempt;
    } else {
      all.add(attempt);
    }
    await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode([for (final a in all) a.toJson()]),
    );
  }

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(key);
}
