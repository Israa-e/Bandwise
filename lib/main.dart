import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // From --dart-define-from-file=env.json. Without keys the app runs
  // offline, guest only.
  const config = AppConfig.fromEnvironment;
  if (config.accountsEnabled) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      // The anon key (or the newer publishable key): public by design.
      publishableKey: config.supabaseAnonKey,
    );
  }
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const BandwiseApp(),
    ),
  );
}
