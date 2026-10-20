import 'dart:async';

import 'package:bandwise/features/auth/domain/auth_service.dart';
import 'package:bandwise/features/sync/domain/sync_repository.dart';
import 'package:bandwise/features/writing/domain/writing_submission.dart';

class _Account {
  _Account({
    required this.id,
    required this.name,
    required this.password,
    required this.confirmed,
  });

  final String id;
  final String? name;
  String password;
  bool confirmed;
}

/// In-memory accounts. No network.
class FakeAuthService implements AuthService {
  FakeAuthService({this.requireConfirmation = false});

  /// Sign-up needs the email confirmed before logging in.
  bool requireConfirmation;

  final _accounts = <String, _Account>{};
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;
  var _nextId = 1;

  /// The next request fails with this, once.
  AuthErrorKind? failNext;

  /// When set, requests wait for it (to see loading states).
  Completer<void>? gate;

  /// Codes "emailed" for password reset, by email.
  final resetCodes = <String, String>{};

  /// Every email a reset code was requested for, registered or not.
  final resetRequests = <String>[];
  var signUpCalls = 0;
  var deleteCalls = 0;

  void addAccount(
    String email, {
    String password = 'Passw0rd!',
    String? name,
    bool confirmed = true,
  }) => _accounts[email] = _Account(
    id: 'user-${_nextId++}',
    name: name,
    password: password,
    confirmed: confirmed,
  );

  String idOf(String email) => _accounts[email]!.id;
  String passwordOf(String email) => _accounts[email]!.password;
  bool hasAccount(String email) => _accounts.containsKey(email);
  void confirm(String email) => _accounts[email]!.confirmed = true;

  AuthUser _user(String email) {
    final a = _accounts[email]!;
    return AuthUser(id: a.id, email: email, displayName: a.name);
  }

  void _setCurrent(AuthUser? user) {
    _current = user;
    _changes.add(user);
  }

  Future<void> _request() async {
    if (gate case final g?) await g.future;
    if (failNext case final kind?) {
      failNext = null;
      throw AuthFailure(kind);
    }
  }

  @override
  bool get isConfigured => true;

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<SignUpOutcome> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    await _request();
    // A registered email looks like a normal sign-up.
    if (_accounts.containsKey(email)) return SignUpOutcome.confirmEmail;
    addAccount(
      email,
      password: password,
      name: name,
      confirmed: !requireConfirmation,
    );
    if (requireConfirmation) return SignUpOutcome.confirmEmail;
    _setCurrent(_user(email));
    return SignUpOutcome.signedIn;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    await _request();
    final account = _accounts[email.trim()];
    if (account == null || account.password != password) {
      throw const AuthFailure(AuthErrorKind.invalidCredentials);
    }
    if (!account.confirmed) {
      throw const AuthFailure(AuthErrorKind.emailNotConfirmed);
    }
    final user = _user(email.trim());
    _setCurrent(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetCode(String email) async {
    await _request();
    resetRequests.add(email.trim());
    if (_accounts.containsKey(email.trim())) {
      resetCodes[email.trim()] = '123456';
    }
  }

  @override
  Future<AuthUser> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _request();
    if (resetCodes[email.trim()] != code.trim()) {
      throw const AuthFailure(AuthErrorKind.invalidCode);
    }
    resetCodes.remove(email.trim());
    final user = _user(email.trim());
    _setCurrent(user);
    return user;
  }

  @override
  Future<void> updatePassword(String password) async {
    await _request();
    final account = _accounts[_current!.email]!;
    if (account.password == password) {
      throw const AuthFailure(AuthErrorKind.samePassword);
    }
    account.password = password;
  }

  @override
  Future<void> signOut() async => _setCurrent(null);

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    await _request();
    _accounts.remove(_current!.email);
    _setCurrent(null);
  }
}

/// In-memory server copy of each account's data. [online] false makes
/// every request fail like a lost connection.
class FakeSyncRepository implements SyncRepository {
  var online = true;

  /// Fails like a server error (not a lost connection).
  var serverError = false;
  final documents = <String, Map<SyncDocumentKey, SyncDocument>>{};
  final essays = <String, Map<String, WritingSubmission>>{};
  var requests = 0;

  void _check() {
    requests++;
    if (!online) throw const SyncException(SyncErrorKind.network);
    if (serverError) throw const SyncException(SyncErrorKind.failed, 'boom');
  }

  SyncDocument? document(String userId, SyncDocumentKey key) =>
      documents[userId]?[key];

  @override
  Future<Map<SyncDocumentKey, SyncDocument>> fetchDocuments(
    String userId,
  ) async {
    _check();
    return {...?documents[userId]};
  }

  @override
  Future<void> upsertDocuments(
    String userId,
    List<SyncDocument> documents,
  ) async {
    _check();
    final mine = this.documents.putIfAbsent(userId, () => {});
    for (final d in documents) {
      mine[d.key] = d;
    }
  }

  @override
  Future<List<WritingSubmission>> fetchEssays(String userId) async {
    _check();
    return [...?essays[userId]?.values];
  }

  @override
  Future<void> upsertEssays(
    String userId,
    List<WritingSubmission> essays,
  ) async {
    _check();
    final mine = this.essays.putIfAbsent(userId, () => {});
    for (final e in essays) {
      mine[e.id] = e;
    }
  }

  @override
  Future<void> deleteEssays(String userId, List<String> ids) async {
    _check();
    essays[userId]?.removeWhere((id, _) => ids.contains(id));
  }
}
