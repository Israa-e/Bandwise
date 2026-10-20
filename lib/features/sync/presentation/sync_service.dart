import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/app_config.dart';
import '../../../core/utils/clock.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/presentation/progress_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../writing/domain/writing_submission.dart';
import '../../writing/presentation/writing_providers.dart';
import '../data/local_sync_store.dart';
import '../data/supabase_sync_repository.dart';
import '../domain/sync_repository.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.accountsEnabled
      ? SupabaseSyncRepository(sb.Supabase.instance.client)
      : const DisabledSyncRepository();
});

final localSyncStoreProvider = Provider<LocalSyncStore>(
  (ref) => const LocalSyncStore(),
);

enum SyncPhase {
  /// A guest: nothing is synced.
  signedOut,
  idle,
  syncing,

  /// No connection; changes are kept and retried.
  offline,

  /// The server failed; Retry is offered.
  failed,
}

@immutable
class SyncState {
  const SyncState(this.phase, {this.lastSyncedAt});

  final SyncPhase phase;
  final DateTime? lastSyncedAt;

  @override
  bool operator ==(Object other) =>
      other is SyncState &&
      other.phase == phase &&
      other.lastSyncedAt == lastSyncedAt;

  @override
  int get hashCode => Object.hash(phase, lastSyncedAt);
}

/// How to combine this device's data with an account's on login.
enum AdoptMode {
  /// The account's data replaces this device's.
  keepAccount,

  /// This device's data replaces the account's (also used for a new
  /// account).
  replaceAccount,
}

final syncServiceProvider = NotifierProvider<SyncService, SyncState>(
  SyncService.new,
);

/// Local-first sync. The UI only reads local storage; this pushes changed
/// documents (about 3 s after a change, and when the app goes to the
/// background) and pulls on login and app start. Each document is
/// last-write-wins by its `updated_at`; essays merge by id. Offline
/// failures are retried later.
class SyncService extends Notifier<SyncState> {
  static const debounce = Duration(seconds: 3);
  static const retryDelay = Duration(seconds: 30);

  Timer? _debounceTimer;
  Timer? _retryTimer;
  Future<void> _lock = Future.value();

  /// Set while signing out, so nothing more is uploaded.
  var _stopped = false;

  SyncRepository get _remote => ref.read(syncRepositoryProvider);
  LocalSyncStore get _local => ref.read(localSyncStoreProvider);
  DateTime _now() => ref.read(clockProvider)().toUtc();

  @override
  SyncState build() {
    ref.onDispose(_cancelTimers);
    void changed(Object? _, Object? _) => _scheduleUpload();
    ref.listen(onboardingControllerProvider, changed);
    ref.listen(progressControllerProvider, changed);
    ref.listen(settingsControllerProvider, changed);
    ref.listen(writingSubmissionsProvider, changed);
    ref.listen(authUserProvider, (previous, user) {
      if (user == null) {
        _cancelTimers();
        state = const SyncState(SyncPhase.signedOut);
      }
    });

    final user = ref.read(authUserProvider);
    if (user == null) return const SyncState(SyncPhase.signedOut);
    // App start with a saved session: pull, then push what changed. If this
    // device was never set up for the account (e.g. the app closed during
    // login), the account's data wins.
    Future.microtask(() async {
      final meta = await _local.readMeta();
      if (meta.userId == user.id) {
        await syncNow();
      } else {
        await adopt(AdoptMode.keepAccount);
      }
    });
    return const SyncState(SyncPhase.idle);
  }

  void _cancelTimers() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
  }

  void _scheduleUpload() {
    if (_stopped || ref.read(authUserProvider) == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(flush()));
  }

  /// Pulls the account's changes, then pushes this device's.
  Future<bool> syncNow() => _run(() async {
    await _pull();
    await _push();
  });

  /// Pushes pending changes now. Returns whether everything is uploaded.
  Future<bool> flush() {
    _debounceTimer?.cancel();
    return _run(_push);
  }

  /// Sets this device up for the signed-in account after login or
  /// sign-up, combining data as [mode] says.
  Future<bool> adopt(AdoptMode mode) {
    _stopped = false;
    return _run(() async {
      final user = ref.read(authUserProvider)!;
      final meta = await _local.readMeta();
      // A different account starts from scratch.
      if (meta.userId != user.id) {
        await _local.writeMeta(SyncMeta(userId: user.id));
      }
      switch (mode) {
        case AdoptMode.keepAccount:
          await _pull(forceRemote: true);
          await _push();
        case AdoptMode.replaceAccount:
          await _push(forceLocal: true);
      }
    });
  }

  /// Stops uploading, e.g. before signing out.
  void stop() {
    _stopped = true;
    _cancelTimers();
  }

  /// Forgets which account this device synced with.
  Future<void> clearLocalState() => _local.clearMeta();

  /// Whether this device has learning history worth keeping.
  Future<bool> hasLocalProgress() async {
    final progress = await ref.read(progressControllerProvider.future);
    final essays = await ref.read(writingSubmissionsProvider.future);
    return progress.activeDays.isNotEmpty ||
        progress.results.isNotEmpty ||
        progress.readingAttempts.isNotEmpty ||
        essays.isNotEmpty;
  }

  /// Whether the signed-in account already has saved data. Throws
  /// [SyncException].
  Future<bool> remoteHasData() async {
    final user = ref.read(authUserProvider)!;
    final documents = await _remote.fetchDocuments(user.id);
    if (documents.isNotEmpty) return true;
    return (await _remote.fetchEssays(user.id)).isNotEmpty;
  }

  /// Runs one sync task at a time and reports its outcome in [state].
  Future<bool> _run(Future<void> Function() task) {
    final result = _lock.then((_) => _attempt(task));
    _lock = result.then((_) {});
    return result;
  }

  Future<bool> _attempt(Future<void> Function() task) async {
    if (_stopped || !ref.mounted || ref.read(authUserProvider) == null) {
      return false;
    }
    state = SyncState(SyncPhase.syncing, lastSyncedAt: state.lastSyncedAt);
    try {
      await task();
      if (!ref.mounted) return true;
      _retryTimer?.cancel();
      final meta = await _local.readMeta();
      meta.lastSyncedAt = _now();
      await _local.writeMeta(meta);
      state = SyncState(SyncPhase.idle, lastSyncedAt: meta.lastSyncedAt);
      return true;
    } on SyncException catch (e) {
      if (!ref.mounted) return false;
      final offline = e.kind == SyncErrorKind.network;
      state = SyncState(
        offline ? SyncPhase.offline : SyncPhase.failed,
        lastSyncedAt: state.lastSyncedAt,
      );
      if (offline) {
        _retryTimer?.cancel();
        _retryTimer = Timer(retryDelay, () => unawaited(syncNow()));
      }
      return false;
    }
  }

  /// Notes local changes: a document whose content changed gets a new
  /// [DocumentSyncInfo.updatedAt].
  Future<Map<SyncDocumentKey, String>> _observe(SyncMeta meta) async {
    final raws = <SyncDocumentKey, String>{};
    for (final key in SyncDocumentKey.values) {
      final raw = await _local.readDocument(key);
      if (raw == null) continue;
      raws[key] = raw;
      final hash = contentHash(raw);
      final info = meta.documents[key];
      if (info == null || info.observed != hash) {
        meta.documents[key] = DocumentSyncInfo(
          observed: hash,
          synced: info?.synced,
          updatedAt: _now(),
        );
      }
    }
    return raws;
  }

  /// Uploads changed documents and essays. With [forceLocal], everything
  /// on this device replaces the account's copy.
  Future<void> _push({bool forceLocal = false}) async {
    final user = ref.read(authUserProvider);
    if (user == null) return;
    final meta = await _local.readMeta();
    if (meta.userId != user.id) return;
    final raws = await _observe(meta);
    if (forceLocal) {
      for (final key in raws.keys) {
        meta.documents[key] = DocumentSyncInfo(
          observed: meta.documents[key]!.observed,
          updatedAt: _now(),
        );
      }
    }
    await _local.writeMeta(meta);

    final dirty = [
      for (final e in raws.entries)
        if (meta.documents[e.key]!.dirty) e.key,
    ];
    await _remote.upsertDocuments(user.id, [
      for (final key in dirty)
        SyncDocument(
          key: key,
          data: jsonDecode(raws[key]!) as Map<String, dynamic>,
          updatedAt: meta.documents[key]!.updatedAt,
        ),
    ]);
    for (final key in dirty) {
      final info = meta.documents[key]!;
      meta.documents[key] = DocumentSyncInfo(
        observed: info.observed,
        synced: info.observed,
        updatedAt: info.updatedAt,
      );
    }

    final essays = await _local.readEssays();
    if (forceLocal) {
      final local = {for (final e in essays) e.id};
      final remote = await _remote.fetchEssays(user.id);
      await _remote.deleteEssays(user.id, [
        for (final e in remote)
          if (!local.contains(e.id)) e.id,
      ]);
      meta.essays.clear();
    }
    final pending = [
      for (final e in essays)
        if (meta.essays[e.id] != (e.result != null)) e,
    ];
    await _remote.upsertEssays(user.id, pending);
    for (final e in pending) {
      meta.essays[e.id] = e.result != null;
    }
    await _local.writeMeta(meta);
  }

  /// Downloads the account's documents and essays. A document replaces the
  /// local copy when it is newer, or always with [forceRemote].
  Future<void> _pull({bool forceRemote = false}) async {
    final user = ref.read(authUserProvider);
    if (user == null) return;
    final meta = await _local.readMeta();
    if (meta.userId != user.id) return;
    await _observe(meta);
    await _local.writeMeta(meta);

    final remote = await _remote.fetchDocuments(user.id);
    final remoteEssays = await _remote.fetchEssays(user.id);

    final changed = <SyncDocumentKey>{};
    for (final doc in remote.values) {
      final info = meta.documents[doc.key];
      final take =
          forceRemote ||
          info == null ||
          (info.dirty
              ? doc.updatedAt.isAfter(info.updatedAt)
              : !doc.updatedAt.isAtSameMomentAs(info.updatedAt));
      if (!take) continue;
      final raw = jsonEncode(doc.data);
      final hash = contentHash(raw);
      if (info?.observed != hash) {
        await _local.writeDocument(doc.key, raw);
        changed.add(doc.key);
      }
      meta.documents[doc.key] = DocumentSyncInfo(
        observed: hash,
        synced: hash,
        updatedAt: doc.updatedAt,
      );
    }

    final local = await _local.readEssays();
    final merged = forceRemote
        ? ([...remoteEssays]
            ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt)))
        : _mergeEssays(local, remoteEssays);
    if (!listEquals(
      [for (final e in merged) jsonEncode(e.toJson())],
      [for (final e in local) jsonEncode(e.toJson())],
    )) {
      await _local.writeEssays(merged);
      if (ref.mounted) ref.invalidate(writingSubmissionsProvider);
    }
    if (forceRemote) meta.essays.clear();
    for (final e in remoteEssays) {
      meta.essays[e.id] = e.result != null;
    }
    await _local.writeMeta(meta);

    if (!ref.mounted) return;
    for (final key in changed) {
      switch (key) {
        case SyncDocumentKey.onboarding:
          ref.invalidate(onboardingControllerProvider);
        case SyncDocumentKey.progress:
          ref.invalidate(progressControllerProvider);
        case SyncDocumentKey.settings:
          ref.invalidate(settingsControllerProvider);
      }
    }
  }

  /// Every essay from both sides, oldest first. For one id on both sides,
  /// the copy with feedback wins.
  static List<WritingSubmission> _mergeEssays(
    List<WritingSubmission> local,
    List<WritingSubmission> remote,
  ) {
    final byId = {for (final e in local) e.id: e};
    for (final e in remote) {
      final mine = byId[e.id];
      if (mine == null || (mine.result == null && e.result != null)) {
        byId[e.id] = e;
      }
    }
    return byId.values.toList()
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }
}

/// Keeps sync running for the whole app: uploads when the app goes to the
/// background and syncs when it comes back.
class SyncScope extends ConsumerStatefulWidget {
  const SyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncScope> createState() => _SyncScopeState();
}

class _SyncScopeState extends ConsumerState<SyncScope> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(ref.read(syncServiceProvider.notifier).flush()),
      onResume: () =>
          unawaited(ref.read(syncServiceProvider.notifier).syncNow()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the service alive.
    ref.watch(syncServiceProvider);
    return widget.child;
  }
}
