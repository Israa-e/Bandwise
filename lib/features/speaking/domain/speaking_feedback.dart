import 'package:flutter/foundation.dart';

import '../../writing/domain/writing_feedback.dart' show EstimateRange;
import 'speaking.dart';
import 'speaking_attempt.dart';

export '../../writing/domain/writing_feedback.dart'
    show EstimateRange, estimateLabel;

/// A practice estimate for one criterion, with what went well and what to
/// work on.
@immutable
class SpeakingCriterionFeedback {
  const SpeakingCriterionFeedback({
    required this.criterion,
    required this.range,
    required this.strength,
    required this.improvement,
  });

  final SpeakingCriterion criterion;
  final EstimateRange range;
  final String strength;
  final String improvement;

  Map<String, dynamic> toJson() => {
    'criterion': criterion.name,
    ...range.toJson(),
    'strength': strength,
    'improvement': improvement,
  };

  static SpeakingCriterionFeedback fromJson(Map<String, dynamic> json) =>
      SpeakingCriterionFeedback(
        criterion: SpeakingCriterion.values.byName(json['criterion'] as String),
        range: EstimateRange.fromJson(json),
        strength: json['strength'] as String,
        improvement: json['improvement'] as String,
      );
}

/// A note on part of one recorded answer: from [start] to [end] of the
/// answer to [questionId].
@immutable
class SpeakingNote {
  const SpeakingNote({
    required this.id,
    required this.questionId,
    required this.start,
    required this.end,
    required this.criterion,
    required this.note,
  });

  final String id;
  final String questionId;
  final Duration start;
  final Duration end;
  final SpeakingCriterion criterion;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionId': questionId,
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
    'criterion': criterion.name,
    'note': note,
  };

  static SpeakingNote fromJson(Map<String, dynamic> json) => SpeakingNote(
    id: json['id'] as String,
    questionId: json['questionId'] as String,
    start: Duration(milliseconds: json['startMs'] as int),
    end: Duration(milliseconds: json['endMs'] as int),
    criterion: SpeakingCriterion.values.byName(json['criterion'] as String),
    note: json['note'] as String,
  );
}

/// Feedback on a speaking attempt. This is the contract the AI backend will
/// return; nothing produces it yet.
@immutable
class SpeakingFeedback {
  const SpeakingFeedback({
    required this.parts,
    required this.criteria,
    required this.strengths,
    required this.improvements,
    required this.notes,
    required this.createdAt,
  });

  /// The parts that were assessed.
  final List<SpeakingPart> parts;
  final List<SpeakingCriterionFeedback> criteria;
  final List<String> strengths;
  final List<String> improvements;
  final List<SpeakingNote> notes;
  final DateTime createdAt;

  SpeakingFeedback copyWith({List<SpeakingNote>? notes}) => SpeakingFeedback(
    parts: parts,
    criteria: criteria,
    strengths: strengths,
    improvements: improvements,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'parts': [for (final p in parts) p.name],
    'criteria': [for (final c in criteria) c.toJson()],
    'strengths': strengths,
    'improvements': improvements,
    'notes': [for (final n in notes) n.toJson()],
    'createdAt': createdAt.toIso8601String(),
  };

  static SpeakingFeedback fromJson(Map<String, dynamic> json) =>
      SpeakingFeedback(
        parts: [
          for (final p in json['parts'] as List)
            SpeakingPart.values.byName(p as String),
        ],
        criteria: [
          for (final c in json['criteria'] as List)
            SpeakingCriterionFeedback.fromJson(c as Map<String, dynamic>),
        ],
        strengths: (json['strengths'] as List? ?? const []).cast<String>(),
        improvements: (json['improvements'] as List? ?? const [])
            .cast<String>(),
        notes: [
          for (final n in json['notes'] as List? ?? const [])
            SpeakingNote.fromJson(n as Map<String, dynamic>),
        ],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// The outcome of [validateSpeakingFeedback].
@immutable
class SpeakingFeedbackValidation {
  const SpeakingFeedbackValidation({
    required this.feedback,
    required this.errors,
    required this.droppedNotes,
  });

  /// The feedback with bad notes removed; null when [errors] isn't empty.
  final SpeakingFeedback? feedback;
  final List<String> errors;

  /// Ids of notes removed because they don't fit the recordings.
  final List<String> droppedNotes;

  bool get isValid => errors.isEmpty;
}

/// Checks feedback against [attempt] before it is shown:
/// - every range is between 1 and 9, in 0.5 steps, and 0.5 wide;
/// - the criteria are exactly the four speaking criteria, once each;
/// - the parts are ones the attempt has answers for.
///
/// Notes on an answer the attempt doesn't have, or whose time range isn't
/// inside that recording, are dropped rather than failing the feedback.
SpeakingFeedbackValidation validateSpeakingFeedback(
  SpeakingFeedback feedback,
  SpeakingAttempt attempt,
) {
  final errors = <String>[];

  for (final c in feedback.criteria) {
    final r = c.range;
    bool onStep(double v) => (v * 2) == (v * 2).roundToDouble();
    final what = c.criterion.name;
    if (r.low < 1 || r.high > 9) errors.add('$what is outside 1–9');
    if (!onStep(r.low) || !onStep(r.high)) {
      errors.add('$what is not in 0.5 steps');
    }
    if (r.high - r.low != 0.5) errors.add('$what is not 0.5 wide');
  }

  final named = [for (final c in feedback.criteria) c.criterion];
  if (named.length != SpeakingCriterion.values.length ||
      !SpeakingCriterion.values.every(named.contains)) {
    errors.add(
      'criteria ${named.map((c) => c.name).toList()} are not the four '
      'speaking criteria',
    );
  }

  final answered = {for (final a in attempt.answers) a.part};
  if (feedback.parts.isEmpty) errors.add('no parts');
  for (final p in feedback.parts) {
    if (!answered.contains(p)) errors.add('${p.name} has no answers');
  }

  final answers = {for (final a in attempt.answers) a.questionId: a};
  final kept = <SpeakingNote>[];
  final dropped = <String>[];
  for (final n in feedback.notes) {
    final answer = answers[n.questionId];
    final fits =
        answer != null &&
        feedback.parts.contains(answer.part) &&
        n.start >= Duration.zero &&
        n.start < n.end &&
        n.end <= answer.duration;
    if (fits) {
      kept.add(n);
    } else {
      dropped.add(n.id);
    }
  }

  return SpeakingFeedbackValidation(
    feedback: errors.isEmpty ? feedback.copyWith(notes: kept) : null,
    errors: errors,
    droppedNotes: dropped,
  );
}

/// What a review of a speaking attempt gives back.
@immutable
sealed class SpeakingResult {
  const SpeakingResult();
}

/// Validated AI feedback.
class AnalysedSpeakingResult extends SpeakingResult {
  const AnalysedSpeakingResult(this.feedback);

  final SpeakingFeedback feedback;
}

/// No AI review is connected: no estimate is given.
class DemoSpeakingResult extends SpeakingResult {
  const DemoSpeakingResult();
}

/// Reviews speaking attempts. The real implementation will send the
/// recordings to a server function; the app never calls an AI API.
abstract interface class SpeakingFeedbackService {
  Future<SpeakingResult> evaluate(SpeakingAttempt attempt);
}
