import 'package:flutter/foundation.dart';

import '../../writing/domain/writing_submission.dart';

/// The synced documents: their key on the server and on the device. Review
/// schedules and removed words are part of the progress document.
enum SyncDocumentKey {
  onboarding('onboarding', 'onboarding.v1'),
  progress('progress', 'progress.v1'),
  settings('settings', 'settings.v1');

  const SyncDocumentKey(this.remote, this.local);

  /// `user_documents.key`.
  final String remote;

  /// The shared_preferences key the repositories use.
  final String local;

  static SyncDocumentKey? byRemote(String key) =>
      values.where((k) => k.remote == key).firstOrNull;
}

/// One saved document, as JSON, with the time it last changed.
@immutable
class SyncDocument {
  const SyncDocument({
    required this.key,
    required this.data,
    required this.updatedAt,
  });

  final SyncDocumentKey key;
  final Map<String, dynamic> data;
  final DateTime updatedAt;
}

/// Why a sync request failed.
enum SyncErrorKind {
  /// No connection: retried later.
  network,

  /// The server refused or failed.
  failed,
}

class SyncException implements Exception {
  const SyncException(this.kind, [this.detail]);

  final SyncErrorKind kind;
  final String? detail;

  @override
  String toString() =>
      'SyncException(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// The account's copy of the learner's data on the server. Every method
/// throws [SyncException] on failure.
abstract interface class SyncRepository {
  Future<Map<SyncDocumentKey, SyncDocument>> fetchDocuments(String userId);

  /// Adds or replaces each document.
  Future<void> upsertDocuments(String userId, List<SyncDocument> documents);

  Future<List<WritingSubmission>> fetchEssays(String userId);

  /// Adds or replaces each essay (by id).
  Future<void> upsertEssays(String userId, List<WritingSubmission> essays);

  /// Deletes the account's essays with these ids.
  Future<void> deleteEssays(String userId, List<String> ids);
}

/// Used when accounts aren't configured; nobody is signed in to sync.
class DisabledSyncRepository implements SyncRepository {
  const DisabledSyncRepository();

  static const _error = SyncException(SyncErrorKind.failed, 'not configured');

  @override
  Future<Map<SyncDocumentKey, SyncDocument>> fetchDocuments(String userId) =>
      Future.error(_error);

  @override
  Future<void> upsertDocuments(String userId, List<SyncDocument> documents) =>
      Future.error(_error);

  @override
  Future<List<WritingSubmission>> fetchEssays(String userId) =>
      Future.error(_error);

  @override
  Future<void> upsertEssays(String userId, List<WritingSubmission> essays) =>
      Future.error(_error);

  @override
  Future<void> deleteEssays(String userId, List<String> ids) =>
      Future.error(_error);
}
