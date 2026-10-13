import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_repository.dart';
import '../domain/onboarding_state.dart';

/// [OnboardingRepository] backed by shared_preferences, stored as JSON.
class PrefsOnboardingRepository implements OnboardingRepository {
  PrefsOnboardingRepository([Future<SharedPreferences>? prefs])
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const _key = 'onboarding.v1';

  final Future<SharedPreferences> _prefs;

  @override
  Future<OnboardingState> load() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null) return const OnboardingState();
    try {
      return OnboardingState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (error) {
      // Corrupt or incompatible data: start over rather than crash.
      debugPrint('Discarding saved onboarding state: $error');
      return const OnboardingState();
    }
  }

  @override
  Future<void> save(OnboardingState state) async {
    await (await _prefs).setString(_key, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    await (await _prefs).remove(_key);
  }
}
