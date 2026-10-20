import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../writing/domain/writing.dart';
import '../../writing/domain/writing_submission.dart';
import '../domain/sync_repository.dart';

/// [SyncRepository] on the `user_documents` and `essays` tables. Row Level
/// Security limits every query to the signed-in user's rows.
class SupabaseSyncRepository implements SyncRepository {
  SupabaseSyncRepository(this._client);

  final sb.SupabaseClient _client;

  static const _timeout = Duration(seconds: 20);

  @override
  Future<Map<SyncDocumentKey, SyncDocument>> fetchDocuments(
    String userId,
  ) async {
    final rows = await _guard(
      () => _client
          .from('user_documents')
          .select('key, data, updated_at')
          .eq('user_id', userId),
    );
    final documents = <SyncDocumentKey, SyncDocument>{};
    for (final row in rows) {
      // Keys this version doesn't know are left alone.
      final key = SyncDocumentKey.byRemote(row['key'] as String);
      if (key == null) continue;
      documents[key] = SyncDocument(
        key: key,
        data: row['data'] as Map<String, dynamic>,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
    }
    return documents;
  }

  @override
  Future<void> upsertDocuments(
    String userId,
    List<SyncDocument> documents,
  ) async {
    if (documents.isEmpty) return;
    await _guard(
      () => _client.from('user_documents').upsert([
        for (final d in documents)
          {
            'user_id': userId,
            'key': d.key.remote,
            'data': d.data,
            'updated_at': d.updatedAt.toUtc().toIso8601String(),
          },
      ], onConflict: 'user_id,key'),
    );
  }

  @override
  Future<List<WritingSubmission>> fetchEssays(String userId) async {
    final rows = await _guard(
      () => _client.from('essays').select().eq('user_id', userId),
    );
    return [
      for (final row in rows)
        WritingSubmission.fromJson({
          'id': row['id'],
          'taskId': row['task_id'],
          'mode': row['mode'] ?? WritingMode.learning.name,
          'text': row['text'],
          'timeUsedSeconds': row['time_used_seconds'] ?? 0,
          'submittedAt': DateTime.parse(
            row['submitted_at'] as String,
          ).toLocal().toIso8601String(),
          'revisionOf': row['revision_of'],
          'timeUp': row['time_up'] ?? false,
          'result': ?row['result'],
        }),
    ];
  }

  @override
  Future<void> upsertEssays(
    String userId,
    List<WritingSubmission> essays,
  ) async {
    if (essays.isEmpty) return;
    await _guard(
      () => _client.from('essays').upsert([
        for (final e in essays)
          {
            'id': e.id,
            'user_id': userId,
            'task_id': e.taskId,
            'text': e.text,
            'result': e.result?.toJson(),
            'submitted_at': e.submittedAt.toUtc().toIso8601String(),
            'revision_of': e.revisionOf,
            'mode': e.mode.name,
            'time_used_seconds': e.timeUsed.inSeconds,
            'time_up': e.timeUp,
          },
      ]),
    );
  }

  @override
  Future<void> deleteEssays(String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    await _guard(
      () => _client
          .from('essays')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', ids),
    );
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on http.ClientException catch (e) {
      throw SyncException(SyncErrorKind.network, e.message);
    } on TimeoutException {
      throw const SyncException(SyncErrorKind.network, 'timeout');
    } on sb.AuthRetryableFetchException catch (e) {
      throw SyncException(SyncErrorKind.network, e.message);
    } on sb.PostgrestException catch (e) {
      throw SyncException(SyncErrorKind.failed, e.message);
    } on sb.AuthException catch (e) {
      throw SyncException(SyncErrorKind.failed, e.message);
    }
  }
}
