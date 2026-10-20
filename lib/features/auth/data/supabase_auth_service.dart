import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/auth_service.dart';

/// [AuthService] on Supabase Auth. Passwords and sessions are handled by
/// Supabase; the session is kept on the device by supabase_flutter.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final sb.SupabaseClient _client;

  /// Name of the Edge Function that deletes the signed-in user.
  static const deleteAccountFunction = 'delete-account';

  static const _timeout = Duration(seconds: 20);

  sb.GoTrueClient get _auth => _client.auth;

  @override
  bool get isConfigured => true;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges =>
      _auth.onAuthStateChange.map((s) => _toUser(s.session?.user));

  static AuthUser? _toUser(sb.User? user) {
    if (user == null) return null;
    final name = user.userMetadata?['display_name'];
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: name is String && name.trim().isNotEmpty ? name : null,
    );
  }

  @override
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _guard(
        () => _auth.signUp(
          email: email.trim(),
          password: password,
          data: {'display_name': name.trim()},
        ),
      );
      return response.session == null
          ? SignUpOutcome.confirmEmail
          : SignUpOutcome.signedIn;
    } on _EmailTaken {
      // Don't reveal that the email is registered.
      return SignUpOutcome.confirmEmail;
    }
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    final response = await _guard(
      () => _auth.signInWithPassword(email: email.trim(), password: password),
    );
    return _toUser(response.user)!;
  }

  @override
  Future<void> sendPasswordResetCode(String email) async {
    try {
      await _guard(() => _auth.resetPasswordForEmail(email.trim()));
    } on AuthFailure catch (e) {
      // Only problems the learner can act on; never "no such account".
      if (e.kind == AuthErrorKind.network ||
          e.kind == AuthErrorKind.rateLimited) {
        rethrow;
      }
    }
  }

  @override
  Future<AuthUser> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _guard(
      () => _auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: sb.OtpType.recovery,
      ),
    );
    final user = _toUser(response.user);
    if (user == null) throw const AuthFailure(AuthErrorKind.invalidCode);
    return user;
  }

  @override
  Future<void> updatePassword(String password) =>
      _guard(() => _auth.updateUser(sb.UserAttributes(password: password)));

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(_timeout);
    } catch (_) {
      // Offline: the local session is cleared anyway.
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _guard(() => _client.functions.invoke(deleteAccountFunction));
    await signOut();
  }

  /// Runs [request], turning Supabase and network errors into
  /// [AuthFailure]s.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on sb.AuthRetryableFetchException {
      throw const AuthFailure(AuthErrorKind.network);
    } on sb.AuthException catch (e) {
      final code = e.code;
      if (code == 'user_already_exists' || code == 'email_exists') {
        throw const _EmailTaken();
      }
      throw AuthFailure(_kindFor(code, e.statusCode, e.message));
    } on sb.FunctionException catch (e) {
      throw AuthFailure(
        e.status == 429 ? AuthErrorKind.rateLimited : AuthErrorKind.unknown,
      );
    } on http.ClientException {
      throw const AuthFailure(AuthErrorKind.network);
    } on TimeoutException {
      throw const AuthFailure(AuthErrorKind.network);
    }
  }

  static AuthErrorKind _kindFor(String? code, String? status, String message) {
    switch (code) {
      case 'invalid_credentials':
        return AuthErrorKind.invalidCredentials;
      case 'email_not_confirmed':
        return AuthErrorKind.emailNotConfirmed;
      case 'weak_password':
        return AuthErrorKind.weakPassword;
      case 'otp_expired' || 'otp_disabled' || 'bad_code_verifier':
        return AuthErrorKind.invalidCode;
      case 'same_password':
        return AuthErrorKind.samePassword;
      case 'over_request_rate_limit' ||
          'over_email_send_rate_limit' ||
          'over_sms_send_rate_limit':
        return AuthErrorKind.rateLimited;
    }
    if (status == '429') return AuthErrorKind.rateLimited;
    // Older servers send no code.
    if (message.toLowerCase().contains('invalid login credentials')) {
      return AuthErrorKind.invalidCredentials;
    }
    return AuthErrorKind.unknown;
  }
}

/// Sign-up with a registered email; reported as [SignUpOutcome.confirmEmail].
class _EmailTaken implements Exception {
  const _EmailTaken();
}
