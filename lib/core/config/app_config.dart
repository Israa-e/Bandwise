import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time settings, read from `--dart-define-from-file=env.json`.
///
/// Only the public anon key belongs here. A service_role key must never be
/// in the app or the repo.
@immutable
class AppConfig {
  const AppConfig({this.supabaseUrl = '', this.supabaseAnonKey = ''});

  static const fromEnvironment = AppConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Without both keys the app runs offline, as a guest only.
  bool get accountsEnabled =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}

/// Overridden in `main` (and in tests).
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment,
);
