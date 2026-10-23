import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import '../domain/speaking_devices.dart';

/// Records one answer at a time: the recording itself, its pauses (from
/// the loudness stream) and, when turned on, the automatic transcript.
class AnswerCapture extends ChangeNotifier {
  AnswerCapture({
    required this.recorder,
    required this.store,
    required this.attemptId,
    required this.clock,
    this.transcriber,
  });

  final SpeakingRecorder recorder;
  final RecordingStore store;
  final String attemptId;
  final DateTime Function() clock;

  /// Null keeps the transcript off.
  final SpeechTranscriber? transcriber;

  SpeakingQuestion? _question;
  var _isLongTurn = false;
  DateTime? _startedAt;
  String? _path;
  SilenceDetector? _detector;
  StreamSubscription<double>? _levels;
  var _transcribing = false;

  bool get isRecording => _startedAt != null;

  /// The question being answered, while recording.
  SpeakingQuestion? get question => _question;

  /// Time since recording started; zero when not recording.
  Duration get elapsed {
    final started = _startedAt;
    return started == null ? Duration.zero : clock().difference(started);
  }

  Future<void> start(
    SpeakingQuestion question, {
    bool isLongTurn = false,
  }) async {
    if (isRecording) return;
    final path = await store.newPath(attemptId, question.id);
    _question = question;
    _isLongTurn = isLongTurn;
    _path = path;
    _detector = SilenceDetector();
    await recorder.start(path);
    final started = _startedAt = clock();
    _levels = recorder.amplitude.listen(
      (level) => _detector?.add(clock().difference(started), level),
    );
    final transcriber = this.transcriber;
    _transcribing = transcriber != null && await transcriber.start();
    notifyListeners();
  }

  /// Stops and returns the answer. [cutShort] says why, when it wasn't the
  /// speaker's choice.
  Future<RecordedAnswer?> stop({CutShort? cutShort}) async {
    final question = _question;
    if (!isRecording || question == null) return null;
    final duration = elapsed;
    final silences = _detector!.finish(duration);
    final path = _path;
    final isLongTurn = _isLongTurn;
    final transcribing = _transcribing;
    // Stopped from here on, so a second call (several lifecycle events in
    // a row) does nothing.
    _reset();
    final saved = await recorder.stop() ?? path;
    final transcript = transcribing ? await transcriber!.stop() : null;
    return RecordedAnswer(
      questionId: question.id,
      part: question.part,
      path: saved,
      duration: duration,
      isLongTurn: isLongTurn,
      silences: silences,
      cutShort: cutShort,
      transcript: transcript,
    );
  }

  /// Stops and throws the recording away.
  Future<void> discard() async {
    if (!isRecording) return;
    final path = _path;
    final transcribing = _transcribing;
    _reset();
    await recorder.cancel();
    if (transcribing) await transcriber!.stop();
    if (path != null) await store.delete(path);
  }

  void _reset() {
    // Not awaited: nothing depends on the subscription's cleanup.
    unawaited(_levels?.cancel());
    _levels = null;
    _startedAt = null;
    _question = null;
    _path = null;
    _detector = null;
    _transcribing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _levels?.cancel();
    super.dispose();
  }
}
