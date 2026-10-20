import 'package:flutter/foundation.dart';

/// A signed-in account.
@immutable
class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;

  /// The name given at sign-up, if any.
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, email, displayName);
}

/// Why an auth request failed, as the learner should hear it.
enum AuthErrorKind {
  invalidCredentials('Email or password is incorrect. Please try again.'),
  emailNotConfirmed(
    'Confirm your email first: open the link we sent you, then log in.',
  ),
  weakPassword(
    'Choose a stronger password: at least 8 characters, with letters and '
    'numbers.',
  ),
  invalidCode(
    'That code is wrong or has expired. Check the email, or send a new code.',
  ),
  samePassword('Choose a password you haven’t used for this account before.'),
  network("Can't reach Bandwise. Check your connection and try again."),
  rateLimited('Too many attempts, try again in a few minutes.'),
  notConfigured("Accounts aren't configured in this build."),
  unknown('Something went wrong. Please try again.');

  const AuthErrorKind(this.message);

  final String message;
}

/// A failed auth request.
class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthErrorKind kind;

  String get message => kind.message;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}

/// What happened after signing up.
enum SignUpOutcome {
  /// The account exists and is signed in.
  signedIn,

  /// Email confirmation is on: the learner must open the link, then log
  /// in. Also returned for an email that already has an account, so
  /// sign-up never reveals which emails are registered.
  confirmEmail,
}

/// Accounts. The real implementation talks to Supabase; without keys the
/// app uses a disabled one and stays guest-only.
abstract interface class AuthService {
  /// False when the build has no Supabase keys.
  bool get isConfigured;

  AuthUser? get currentUser;

  /// Emits on sign-in, sign-out and token or profile changes.
  Stream<AuthUser?> get userChanges;

  /// Throws [AuthFailure].
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Throws [AuthFailure].
  Future<AuthUser> logIn({required String email, required String password});

  /// Emails a 6-digit recovery code. Succeeds whether or not the email has
  /// an account. Throws [AuthFailure] only for network or rate limits.
  Future<void> sendPasswordResetCode(String email);

  /// Checks the recovery code; on success the learner is signed in, so the
  /// password can be changed. Throws [AuthFailure].
  Future<AuthUser> verifyResetCode({
    required String email,
    required String code,
  });

  /// For the signed-in learner. Throws [AuthFailure].
  Future<void> updatePassword(String password);

  /// Ends the session on this device, even when offline.
  Future<void> signOut();

  /// Deletes the signed-in account on the server (through the
  /// delete-account function), then signs out. Throws [AuthFailure].
  Future<void> deleteAccount();
}

/// Used when the build has no Supabase keys: nobody can sign in.
class DisabledAuthService implements AuthService {
  const DisabledAuthService();

  static const _failure = AuthFailure(AuthErrorKind.notConfigured);

  @override
  bool get isConfigured => false;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get userChanges => const Stream.empty();

  @override
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) => Future.error(_failure);

  @override
  Future<AuthUser> logIn({required String email, required String password}) =>
      Future.error(_failure);

  @override
  Future<void> sendPasswordResetCode(String email) => Future.error(_failure);

  @override
  Future<AuthUser> verifyResetCode({
    required String email,
    required String code,
  }) => Future.error(_failure);

  @override
  Future<void> updatePassword(String password) => Future.error(_failure);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() => Future.error(_failure);
}
