import 'package:flutter/foundation.dart';

import 'speaking.dart';

/// A pause in an answer, from the start of the recording.
@immutable
class SilenceSpan {
  const SilenceSpan(this.start, this.end);

  final Duration start;
  final Duration end;

  Duration get length => end - start;

  Map<String, dynamic> toJson() => {
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
  };

  static SilenceSpan fromJson(Map<String, dynamic> json) => SilenceSpan(
    Duration(milliseconds: json['startMs'] as int),
    Duration(milliseconds: json['endMs'] as int),
  );

  @override
  bool operator ==(Object other) =>
      other is SilenceSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Finds pauses longer than [minLength] in a recording's loudness, fed one
/// sample at a time (the recorder's amplitude stream).
class SilenceDetector {
  SilenceDetector({
    this.threshold = defaultThreshold,
    this.minLength = defaultMinLength,
  });

  /// Quieter than this (dBFS) counts as silence.
  static const defaultThreshold = -40.0;
  static const defaultMinLength = Duration(seconds: 3);

  final double threshold;
  final Duration minLength;

  final _spans = <SilenceSpan>[];
  Duration? _quietSince;

  /// Pauses found so far, in order.
  List<SilenceSpan> get spans => List.unmodifiable(_spans);

  /// [level] in dBFS at [at] from the start of the recording.
  void add(Duration at, double level) {
    if (level < threshold) {
      _quietSince ??= at;
    } else {
      _close(at);
    }
  }

  /// The recording ended at [at]: a pause still going counts up to there.
  List<SilenceSpan> finish(Duration at) {
    _close(at);
    return spans;
  }

  void _close(Duration at) {
    final since = _quietSince;
    _quietSince = null;
    if (since != null && at - since >= minLength) {
      _spans.add(SilenceSpan(since, at));
    }
  }
}

/// Why an answer stopped before the speaker finished.
enum CutShort {
  /// It reached the time allowed (2:00 in Part 2).
  timeLimit('Stopped at the time limit'),

  /// A call, or the app going into the background, stopped the recording.
  interrupted('Stopped by an interruption');

  const CutShort(this.label);

  final String label;
}

/// One recorded answer. Recordings stay on the device.
@immutable
class RecordedAnswer {
  const RecordedAnswer({
    required this.questionId,
    required this.part,
    required this.path,
    required this.duration,
    this.isLongTurn = false,
    this.silences = const [],
    this.cutShort,
    this.transcript,
  });

  final String questionId;
  final SpeakingPart part;

  /// Where the recording is: a file path, or on the web a blob URL that
  /// lasts for the session. Null once recordings are deleted.
  final String? path;
  final Duration duration;

  /// The Part 2 long turn (not its rounding-off question).
  final bool isLongTurn;

  /// Pauses longer than 3 seconds.
  final List<SilenceSpan> silences;
  final CutShort? cutShort;

  /// The phone's automatic transcript, when it was turned on. May contain
  /// mistakes; never an assessment.
  final String? transcript;

  RecordedAnswer withoutRecording() => RecordedAnswer(
    questionId: questionId,
    part: part,
    path: null,
    duration: duration,
    isLongTurn: isLongTurn,
    silences: silences,
    cutShort: cutShort,
  );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'part': part.name,
    'path': ?path,
    'durationMs': duration.inMilliseconds,
    if (isLongTurn) 'longTurn': true,
    'silences': [for (final s in silences) s.toJson()],
    'cutShort': ?cutShort?.name,
    'transcript': ?transcript,
  };

  static RecordedAnswer fromJson(Map<String, dynamic> json) => RecordedAnswer(
    questionId: json['questionId'] as String,
    part: SpeakingPart.values.byName(json['part'] as String),
    path: json['path'] as String?,
    duration: Duration(milliseconds: json['durationMs'] as int),
    isLongTurn: json['longTurn'] as bool? ?? false,
    silences: [
      for (final s in json['silences'] as List? ?? const [])
        SilenceSpan.fromJson(s as Map<String, dynamic>),
    ],
    cutShort: switch (json['cutShort']) {
      final String name => CutShort.values.byName(name),
      _ => null,
    },
    transcript: json['transcript'] as String?,
  );
}

/// A finished speaking session as kept on this device: the recordings,
/// Part 2 notes, transcripts and the learner's self-assessment. Never
/// synced.
@immutable
class SpeakingAttempt {
  const SpeakingAttempt({
    required this.id,
    required this.mode,
    required this.startedAt,
    required this.finishedAt,
    required this.answers,
    this.notes = '',
    this.transcriptOn = false,
    this.selfAssessment = const {},
  });

  final String id;
  final SpeakingMode mode;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<RecordedAnswer> answers;

  /// Part 2 preparation notes.
  final String notes;
  final bool transcriptOn;

  /// Ticked statements per criterion, by index into
  /// [SpeakingCriterion.statements]. Saved; never turned into a score.
  final Map<SpeakingCriterion, Set<int>> selfAssessment;

  Duration get speakingTime =>
      answers.fold(Duration.zero, (sum, a) => sum + a.duration);

  bool get hasRecordings => answers.any((a) => a.path != null);

  SpeakingAttempt copyWith({
    List<RecordedAnswer>? answers,
    Map<SpeakingCriterion, Set<int>>? selfAssessment,
  }) => SpeakingAttempt(
    id: id,
    mode: mode,
    startedAt: startedAt,
    finishedAt: finishedAt,
    answers: answers ?? this.answers,
    notes: notes,
    transcriptOn: transcriptOn,
    selfAssessment: selfAssessment ?? this.selfAssessment,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode.name,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'answers': [for (final a in answers) a.toJson()],
    'notes': notes,
    'transcriptOn': transcriptOn,
    'selfAssessment': {
      for (final e in selfAssessment.entries) e.key.name: [...e.value]..sort(),
    },
  };

  static SpeakingAttempt fromJson(Map<String, dynamic> json) => SpeakingAttempt(
    id: json['id'] as String,
    mode: SpeakingMode.values.byName(json['mode'] as String),
    startedAt: DateTime.parse(json['startedAt'] as String),
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    answers: [
      for (final a in json['answers'] as List)
        RecordedAnswer.fromJson(a as Map<String, dynamic>),
    ],
    notes: json['notes'] as String? ?? '',
    transcriptOn: json['transcriptOn'] as bool? ?? false,
    selfAssessment: {
      for (final e
          in (json['selfAssessment'] as Map<String, dynamic>? ?? {}).entries)
        ?SpeakingCriterion.values.asNameMap()[e.key]: {
          for (final i in e.value as List) i as int,
        },
    },
  );
}

/// How an answer's length compares with what is usual for its part.
enum LengthFit { usual, short, long }

/// The checks done automatically on one answer: measured, not judged.
@immutable
class AnswerCheck {
  const AnswerCheck(this.answer);

  final RecordedAnswer answer;

  /// The usual length for this kind of answer.
  ({Duration min, Duration max}) get target => switch (answer.part) {
    SpeakingPart.part1 => (
      min: const Duration(seconds: 15),
      max: const Duration(seconds: 40),
    ),
    SpeakingPart.part2 when answer.isLongTurn => (
      min: const Duration(seconds: 90),
      max: const Duration(minutes: 2),
    ),
    SpeakingPart.part2 => (
      min: const Duration(seconds: 5),
      max: const Duration(seconds: 30),
    ),
    SpeakingPart.part3 => (
      min: const Duration(seconds: 30),
      max: const Duration(seconds: 90),
    ),
  };

  LengthFit get fit {
    final t = target;
    // A long turn stopped at 2:00 is as long as it can be.
    if (answer.duration < t.min) return LengthFit.short;
    if (answer.duration > t.max + const Duration(seconds: 1)) {
      return LengthFit.long;
    }
    return LengthFit.usual;
  }

  /// "Aim for 1:30–2:00" or "Usually 0:15–0:40".
  String get targetLabel => answer.isLongTurn
      ? 'Aim for ${formatSpeakingTime(target.min)}–'
            '${formatSpeakingTime(target.max)}'
      : 'Usually ${formatSpeakingTime(target.min)}–'
            '${formatSpeakingTime(target.max)}';

  /// The Part 2 note for a long turn under a minute, said gently.
  bool get longTurnUnderAMinute =>
      answer.isLongTurn && answer.duration < const Duration(minutes: 1);
}

/// "1:05"; hours become minutes.
String formatSpeakingTime(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
