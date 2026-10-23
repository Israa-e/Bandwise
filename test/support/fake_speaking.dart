import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bandwise/features/speaking/data/asset_speaking_content_repository.dart';
import 'package:bandwise/features/speaking/domain/speaking.dart';
import 'package:bandwise/features/speaking/domain/speaking_devices.dart';
import 'package:bandwise/features/speaking/domain/speaking_repository.dart';

/// The real content, read from disk.
SpeakingContent loadSpeakingContent() => parseSpeakingContent(
  jsonDecode(File('assets/speaking/content.json').readAsStringSync())
      as Map<String, dynamic>,
);

class FakeSpeakingContentRepository implements SpeakingContentRepository {
  FakeSpeakingContentRepository(this.content);

  final SpeakingContent content;

  @override
  Future<SpeakingContent> fetchContent() async => content;
}

/// Records nothing; tests set the permission and feed loudness levels.
class FakeRecorder implements SpeakingRecorder {
  FakeRecorder({this.status = MicPermission.granted, this.afterRequest}) {
    instances.add(this);
  }

  static final instances = <FakeRecorder>[];

  /// What [permission] returns.
  MicPermission status;

  /// What [requestPermission] returns (and [status] becomes); defaults to
  /// granted.
  MicPermission? afterRequest;

  var requests = 0;
  var settingsOpened = 0;
  final starts = <String>[];
  var stops = 0;
  var cancels = 0;
  String? recordingTo;
  var disposed = false;

  final _levels = StreamController<double>.broadcast(sync: true);

  bool get isRecording => recordingTo != null;

  /// A loudness sample (dBFS) while recording.
  void level(double dbfs) => _levels.add(dbfs);

  @override
  Future<MicPermission> permission() async => status;

  @override
  Future<MicPermission> requestPermission() async {
    requests++;
    return status = afterRequest ?? MicPermission.granted;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> start(String path) async {
    starts.add(path);
    recordingTo = path;
  }

  @override
  Future<String?> stop() async {
    stops++;
    final path = recordingTo;
    recordingTo = null;
    return path;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    recordingTo = null;
  }

  @override
  Stream<double> get amplitude => _levels.stream;

  @override
  Future<void> dispose() async => disposed = true;
}

/// Plays nothing; tests end what is "playing" with [complete].
class FakeSpeakingAudio implements SpeakingAudio {
  FakeSpeakingAudio() {
    instances.add(this);
  }

  static final instances = <FakeSpeakingAudio>[];

  final loaded = <String>[];
  var playing = false;
  var disposed = false;

  final _playing = StreamController<bool>.broadcast(sync: true);
  final _completed = StreamController<void>.broadcast(sync: true);

  String? get current => loaded.lastOrNull;

  @override
  Future<void> loadAsset(String asset) async => loaded.add(asset);

  @override
  Future<void> loadRecording(String path) async => loaded.add(path);

  @override
  Future<void> play() async {
    playing = true;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    if (!playing) return;
    playing = false;
    _playing.add(false);
  }

  /// What was loaded has played to the end.
  void complete() {
    playing = false;
    _playing.add(false);
    _completed.add(null);
  }

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeRecordingStore implements RecordingStore {
  var _n = 0;
  final deleted = <String>[];
  var deletedAll = 0;

  @override
  Future<String> newPath(String attemptId, String questionId) async =>
      'mem/$attemptId/$questionId-${_n++}.m4a';

  @override
  Future<void> delete(String path) async => deleted.add(path);

  @override
  Future<void> deleteAll() async => deletedAll++;
}

class FakeTranscriber implements SpeechTranscriber {
  FakeTranscriber() {
    instances.add(this);
  }

  static final instances = <FakeTranscriber>[];

  var started = 0;

  @override
  Future<bool> start() async {
    started++;
    return true;
  }

  @override
  Future<String?> stop() async => 'I grew up in a small town by the sea';
}
