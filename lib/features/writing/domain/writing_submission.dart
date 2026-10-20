import 'package:flutter/foundation.dart';

import '../../progress/domain/progress_state.dart';

import 'writing.dart';
import 'writing_feedback.dart';

/// What came back for a submitted essay.
sealed class WritingResult {
  const WritingResult();

  Map<String, dynamic> toJson();

  static WritingResult fromJson(Map<String, dynamic> json) =>
      switch (json['kind']) {
        'analysed' => AnalysedResult(
          WritingFeedback.fromJson(json['feedback'] as Map<String, dynamic>),
          sample: json['sample'] as bool? ?? false,
        ),
        _ => const DemoResult(),
      };
}

/// Full feedback on this essay.
class AnalysedResult extends WritingResult {
  const AnalysedResult(this.feedback, {this.sample = false});

  final WritingFeedback feedback;

  /// Prepared feedback for the sample essay, while AI review isn't
  /// connected.
  final bool sample;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'analysed',
    'sample': sample,
    'feedback': feedback.toJson(),
  };
}

/// The essay wasn't analysed: only general advice is shown.
class DemoResult extends WritingResult {
  const DemoResult();

  @override
  Map<String, dynamic> toJson() => {'kind': 'demo'};
}

/// A submitted essay. It can't be edited; a revision is a new submission
/// with [revisionOf] set.
@immutable
class WritingSubmission {
  const WritingSubmission({
    required this.id,
    required this.taskId,
    required this.mode,
    required this.text,
    required this.timeUsed,
    required this.submittedAt,
    this.revisionOf,
    this.timeUp = false,
    this.result,
  });

  final String id;
  final String taskId;
  final WritingMode mode;
  final String text;
  final Duration timeUsed;
  final DateTime submittedAt;

  /// The submission this one revises.
  final String? revisionOf;

  /// Submitted automatically when the time ran out.
  final bool timeUp;

  /// Null until feedback has arrived.
  final WritingResult? result;

  int get wordCount => countWords(text);

  WritingSubmission withResult(WritingResult result) => WritingSubmission(
    id: id,
    taskId: taskId,
    mode: mode,
    text: text,
    timeUsed: timeUsed,
    submittedAt: submittedAt,
    revisionOf: revisionOf,
    timeUp: timeUp,
    result: result,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'mode': mode.name,
    'text': text,
    'timeUsedSeconds': timeUsed.inSeconds,
    'submittedAt': submittedAt.toIso8601String(),
    'revisionOf': ?revisionOf,
    'timeUp': timeUp,
    if (result case final r?) 'result': r.toJson(),
  };

  static WritingSubmission fromJson(Map<String, dynamic> json) =>
      WritingSubmission(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        mode: WritingMode.values.byName(json['mode'] as String),
        text: json['text'] as String,
        timeUsed: Duration(seconds: json['timeUsedSeconds'] as int),
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        revisionOf: json['revisionOf'] as String?,
        timeUp: json['timeUp'] as bool? ?? false,
        result: switch (json['result']) {
          final Map<String, dynamic> r => WritingResult.fromJson(r),
          _ => null,
        },
      );
}

/// XP for submitting [submission] after [earlier]: [XpRules.perNewEssay]
/// for a new essay, nothing for a revision or for an essay already
/// submitted for the same task with the same text.
int essayXp(WritingSubmission submission, Iterable<WritingSubmission> earlier) {
  if (submission.revisionOf != null) return 0;
  final text = normalizeEssay(submission.text);
  final resubmitted = earlier.any(
    (s) =>
        s.id != submission.id &&
        s.taskId == submission.taskId &&
        normalizeEssay(s.text) == text,
  );
  return resubmitted ? 0 : XpRules.perNewEssay;
}

/// An essay being written, saved as the learner types.
@immutable
class WritingDraft {
  const WritingDraft({
    required this.taskId,
    required this.mode,
    required this.startedAt,
    required this.savedAt,
    this.text = '',
    this.notes = '',
    this.activeTime = Duration.zero,
    this.revisionOf,
  });

  final String taskId;
  final WritingMode mode;

  /// Timed mode counts down from here, so the timer survives the app
  /// being closed.
  final DateTime startedAt;
  final DateTime savedAt;
  final String text;

  /// "Plan your essay" notes. Not counted, not submitted.
  final String notes;

  /// Time spent with the editor open (learning mode's time used).
  final Duration activeTime;
  final String? revisionOf;

  /// One draft per task, plus one per submission being revised.
  String get id => draftIdFor(taskId: taskId, revisionOf: revisionOf);

  static String draftIdFor({required String taskId, String? revisionOf}) =>
      revisionOf == null ? 'task:$taskId' : 'revision:$revisionOf';

  WritingDraft copyWith({
    String? text,
    String? notes,
    Duration? activeTime,
    DateTime? savedAt,
  }) => WritingDraft(
    taskId: taskId,
    mode: mode,
    startedAt: startedAt,
    savedAt: savedAt ?? this.savedAt,
    text: text ?? this.text,
    notes: notes ?? this.notes,
    activeTime: activeTime ?? this.activeTime,
    revisionOf: revisionOf,
  );

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'mode': mode.name,
    'startedAt': startedAt.toIso8601String(),
    'savedAt': savedAt.toIso8601String(),
    'text': text,
    'notes': notes,
    'activeSeconds': activeTime.inSeconds,
    'revisionOf': ?revisionOf,
  };

  static WritingDraft fromJson(Map<String, dynamic> json) => WritingDraft(
    taskId: json['taskId'] as String,
    mode: WritingMode.values.byName(json['mode'] as String),
    startedAt: DateTime.parse(json['startedAt'] as String),
    savedAt: DateTime.parse(json['savedAt'] as String),
    text: json['text'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    activeTime: Duration(seconds: json['activeSeconds'] as int? ?? 0),
    revisionOf: json['revisionOf'] as String?,
  );
}
