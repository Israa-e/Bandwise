import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/sync/presentation/sync_service.dart';

class BandwiseApp extends ConsumerWidget {
  const BandwiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bandwise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AppScope(child: child!),
    );
  }
}

/// App-wide behaviour above the router: the motion preference and sync.
class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      MotionScope(child: SyncScope(child: child));
}
