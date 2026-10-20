import 'package:flutter/foundation.dart';

import '../../reading/domain/reading.dart';
import '../../writing/domain/writing.dart';
import '../../writing/domain/writing_feedback.dart';
import '../../writing/domain/writing_submission.dart';
import 'progress_state.dart';

/// Rounded percent of [correct] out of [total]; null when [total] is 0.
int? percentOf(int correct, int total) =>
    total == 0 ? null : (correct * 100 / total).round();

/// One point on the recent accuracy chart.
typedef AccuracyPoint = ({DateTime date, int percent});

/// Reading practice in numbers. Raw scores and accuracy only, never bands.
@immutable
class ReadingInsights {
  const ReadingInsights._({
    required this.attempts,
    required this.recent,
    required this.byType,
    required this.weakestType,
  });

  /// Attempts the recent chart and the recommendation look at.
  static const recentCount = 5;

  /// A type needs this many recent answers before it can be called weakest.
  static const minAnswersForWeakest = 2;

  factory ReadingInsights.from(List<ReadingAttempt> attempts) {
    final recentAttempts = attempts.length <= recentCount
        ? attempts
        : attempts.sublist(attempts.length - recentCount);
    return ReadingInsights._(
      attempts: attempts.length,
      recent: [
        for (final a in recentAttempts)
          if (percentOf(a.correct, a.total) case final p?)
            (date: a.date, percent: p),
      ],
      byType: _byType(attempts),
      weakestType: _weakest(_byType(recentAttempts)),
    );
  }

  final int attempts;

  /// Accuracy of the last [recentCount] attempts, oldest first.
  final List<AccuracyPoint> recent;

  /// Answers by question type over every attempt, in type order. Types
  /// never practised are left out.
  final Map<ReadingQuestionType, TypeScore> byType;

  /// The recently practised type with the lowest accuracy, if any type is
  /// below 100% with at least [minAnswersForWeakest] answers. Rule-based.
  final ReadingQuestionType? weakestType;

  bool get isEmpty => attempts == 0;

  static Map<ReadingQuestionType, TypeScore> _byType(
    List<ReadingAttempt> attempts,
  ) {
    final correct = <ReadingQuestionType, int>{};
    final total = <ReadingQuestionType, int>{};
    for (final a in attempts) {
      for (final e in a.byType.entries) {
        final type = ReadingQuestionType.values
            .where((t) => t.name == e.key)
            .firstOrNull;
        if (type == null) continue;
        correct[type] = (correct[type] ?? 0) + e.value.correct;
        total[type] = (total[type] ?? 0) + e.value.total;
      }
    }
    return {
      for (final t in ReadingQuestionType.values)
        if ((total[t] ?? 0) > 0)
          t: TypeScore(correct: correct[t]!, total: total[t]!),
    };
  }

  static ReadingQuestionType? _weakest(
    Map<ReadingQuestionType, TypeScore> byType,
  ) {
    ReadingQuestionType? weakest;
    double? lowest;
    for (final e in byType.entries) {
      final score = e.value;
      if (score.total < minAnswersForWeakest || score.correct == score.total) {
        continue;
      }
      final accuracy = score.correct / score.total;
      // Ties keep the earlier type.
      if (lowest == null || accuracy < lowest) {
        lowest = accuracy;
        weakest = e.key;
      }
    }
    return weakest;
  }
}

/// Essays and estimates for one task type.
@immutable
class WritingTaskInsights {
  const WritingTaskInsights({
    required this.essays,
    required this.revisions,
    required this.latestEstimate,
    required this.latestEstimateOn,
  });

  /// New essays submitted (revisions not included).
  final int essays;
  final int revisions;

  /// The overall range of the most recent essay that has one; demo
  /// feedback has none.
  final EstimateRange? latestEstimate;
  final DateTime? latestEstimateOn;
}

/// Writing practice: counts, the latest practice estimates and what the
/// notes are mostly about.
@immutable
class WritingInsights {
  const WritingInsights._(this.byType, this.topNoteType);

  /// [tasks] maps each submission's task to its type.
  factory WritingInsights.from(
    List<WritingSubmission> submissions,
    List<WritingTask> tasks,
  ) {
    final typeOf = {for (final t in tasks) t.id: t.type};
    final noteCounts = <AnnotationType, int>{};
    final byType = <WritingTaskType, WritingTaskInsights>{};
    for (final type in WritingTaskType.values) {
      final ofType = [
        for (final s in submissions)
          if (typeOf[s.taskId] == type) s,
      ]..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
      final analysed = [
        for (final s in ofType)
          if (s.result case AnalysedResult(:final feedback)) (s, feedback),
      ];
      final latest = analysed.lastOrNull;
      byType[type] = WritingTaskInsights(
        essays: ofType.where((s) => s.revisionOf == null).length,
        revisions: ofType.where((s) => s.revisionOf != null).length,
        latestEstimate: latest?.$2.overall,
        latestEstimateOn: latest?.$1.submittedAt,
      );
      for (final (_, feedback) in analysed) {
        for (final a in feedback.annotations) {
          noteCounts[a.type] = (noteCounts[a.type] ?? 0) + 1;
        }
      }
    }
    AnnotationType? top;
    for (final type in AnnotationType.values) {
      final count = noteCounts[type] ?? 0;
      if (count > 0 && count > (noteCounts[top] ?? 0)) top = type;
    }
    return WritingInsights._(byType, top);
  }

  final Map<WritingTaskType, WritingTaskInsights> byType;

  /// The note type that came up most across all feedback; ties keep the
  /// earlier type. Null when there are no notes.
  final AnnotationType? topNoteType;

  int get essays => byType.values.fold(0, (sum, t) => sum + t.essays);

  bool get isEmpty =>
      byType.values.every((t) => t.essays == 0 && t.revisions == 0);
}

/// "Most of your notes are about grammar".
String noteTypeSentence(AnnotationType type) =>
    'Most of your notes are about ${switch (type) {
      AnnotationType.grammar => 'grammar',
      AnnotationType.vocabulary => 'vocabulary',
      AnnotationType.cohesion => 'cohesion',
      AnnotationType.task => 'answering the task',
    }}';
