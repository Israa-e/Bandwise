import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../writing/domain/writing_submission.dart';
import '../domain/sync_repository.dart';

/// Sync bookkeeping for one document.
@immutable
class DocumentSyncInfo {
  const DocumentSyncInfo({
    required this.observed,
    required this.updatedAt,
    this.synced,
  });

  /// Hash of the local content last seen.
  final String observed;

  /// Hash of the content the server has; null if never synced.
  final String? synced;

  /// When the document last changed (locally, or on the server for a
  /// pulled copy). Compared for last-write-wins.
  final DateTime updatedAt;

  /// Changed on this device since the last sync.
  bool get dirty => synced != observed;

  Map<String, dynamic> toJson() => {
    'observed': observed,
    'synced': synced,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static DocumentSyncInfo fromJson(Map<String, dynamic> json) =>
      DocumentSyncInfo(
        observed: json['observed'] as String,
        synced: json['synced'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// What this device knows about its sync with one account.
class SyncMeta {
  SyncMeta({
    this.userId,
    Map<SyncDocumentKey, DocumentSyncInfo>? documents,
    Map<String, bool>? essays,
    this.lastSyncedAt,
  }) : documents = documents ?? {},
       essays = essays ?? {};

  /// The account whose data this device holds. Uploads happen only for
  /// this account.
  final String? userId;
  final Map<SyncDocumentKey, DocumentSyncInfo> documents;

  /// Essay id → whether the uploaded copy has its feedback.
  final Map<String, bool> essays;
  DateTime? lastSyncedAt;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'documents': {
      for (final e in documents.entries) e.key.remote: e.value.toJson(),
    },
    'essays': essays,
    'lastSyncedAt': lastSyncedAt?.toUtc().toIso8601String(),
  };

  static SyncMeta fromJson(Map<String, dynamic> json) {
    final documents = <SyncDocumentKey, DocumentSyncInfo>{};
    final raw = json['documents'] as Map<String, dynamic>? ?? {};
    for (final e in raw.entries) {
      final key = SyncDocumentKey.byRemote(e.key);
      if (key == null) continue;
      documents[key] = DocumentSyncInfo.fromJson(
        e.value as Map<String, dynamic>,
      );
    }
    return SyncMeta(
      userId: json['userId'] as String?,
      documents: documents,
      essays: {
        for (final e in (json['essays'] as Map<String, dynamic>? ?? {}).entries)
          e.key: e.value as bool,
      },
      lastSyncedAt: switch (json['lastSyncedAt']) {
        final String s => DateTime.parse(s),
        _ => null,
      },
    );
  }
}

/// A stable 32-bit FNV-1a hash of [text] (same result on every platform),
/// with the length, as hex.
String contentHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    // hash * 16777619, kept to 32 bits without overflowing on the web.
    hash = (((hash << 24) & 0xffffffff) + hash * 0x193) & 0xffffffff;
  }
  return '${text.length.toRadixString(16)}-${hash.toRadixString(16)}';
}

/// Reads and writes the device copies of the synced data: the same
/// shared_preferences entries the repositories use, so the UI keeps
/// reading local data.
class LocalSyncStore {
  const LocalSyncStore();

  static const essaysKey = 'writing.submissions.v1';
  static const metaKey = 'sync.meta.v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readDocument(SyncDocumentKey key) async =>
      (await _prefs).getString(key.local);

  Future<void> writeDocument(SyncDocumentKey key, String raw) async =>
      (await _prefs).setString(key.local, raw);

  Future<List<WritingSubmission>> readEssays() async {
    final raw = (await _prefs).getString(essaysKey);
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          WritingSubmission.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> writeEssays(List<WritingSubmission> essays) async =>
      (await _prefs).setString(
        essaysKey,
        jsonEncode([for (final e in essays) e.toJson()]),
      );

  Future<SyncMeta> readMeta() async {
    final raw = (await _prefs).getString(metaKey);
    if (raw == null) return SyncMeta();
    try {
      return SyncMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SyncMeta();
    }
  }

  Future<void> writeMeta(SyncMeta meta) async =>
      (await _prefs).setString(metaKey, jsonEncode(meta.toJson()));

  Future<void> clearMeta() async => (await _prefs).remove(metaKey);
}
