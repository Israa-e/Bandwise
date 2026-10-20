import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/app_config.dart';
import '../data/supabase_auth_service.dart';
import '../domain/auth_service.dart';

/// Supabase when the build has keys; otherwise accounts are off.
final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.accountsEnabled
      ? SupabaseAuthService(sb.Supabase.instance.client)
      : const DisabledAuthService();
});

/// The signed-in account, or null for a guest.
final authUserProvider = NotifierProvider<AuthUserController, AuthUser?>(
  AuthUserController.new,
);

class AuthUserController extends Notifier<AuthUser?> {
  @override
  AuthUser? build() {
    final service = ref.watch(authServiceProvider);
    final subscription = service.userChanges.listen((user) {
      if (user != state) state = user;
    });
    ref.onDispose(subscription.cancel);
    return service.currentUser;
  }

  /// Updates at once after an action, without waiting for the stream.
  void set(AuthUser? user) => state = user;
}
