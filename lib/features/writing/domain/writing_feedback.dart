import 'package:flutter/foundation.dart';

import 'writing.dart';

/// Shown with every estimate.
const estimateLabel = 'AI practice estimate — not an official IELTS score';

/// A practice estimate: a range 0.5 wide, e.g. 6.0–6.5.
@immutable
class EstimateRange {
  const EstimateRange(this.low, this.high);

  final double low;
  final double high;

  /// "6.0–6.5".
  String get label => '${low.toStringAsFixed(1)}–${high.toStringAsFixed(1)}';

  /// "6.0 to 6.5", for screen readers.
  String get spoken =>
      '${low.toStringAsFixed(1)} to ${high.toStringAsFixed(1)}';

  Map<String, dynamic> toJson() => {'low': low, 'high': high};

  static EstimateRange fromJson(Map<String, dynamic> json) => EstimateRange(
    (json['low'] as num).toDouble(),
    (json['high'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is EstimateRange && other.low == low && other.high == high;

  @override
  int get hashCode => Object.hash(low, high);
}

@immutable
class CriterionFeedback {
  const CriterionFeedback({
    required this.id,
    required this.range,
    required this.strength,
    required this.improvement,
    required this.explanation,
  });

  /// A [WritingCriterion.id].
  final String id;
  final EstimateRange range;
  final String strength;
  final String improvement;
  final String explanation;

  WritingCriterion? get criterion => WritingCriterion.byId(id);

  Map<String, dynamic> toJson() => {
    'id': id,
    ...range.toJson(),
    'strength': strength,
    'improvement': improvement,
    'explanation': explanation,
  };

  static CriterionFeedback fromJson(Map<String, dynamic> json) =>
      CriterionFeedback(
        id: json['id'] as String,
        range: EstimateRange.fromJson(json),
        strength: json['strength'] as String,
        improvement: json['improvement'] as String,
        explanation: json['explanation'] as String,
      );
}

@immutable
class TopImprovement {
  const TopImprovement({required this.title, required this.detail});

  final String title;
  final String detail;

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};

  static TopImprovement fromJson(Map<String, dynamic> json) => TopImprovement(
    title: json['title'] as String,
    detail: json['detail'] as String,
  );
}

enum AnnotationType {
  grammar('Grammar'),
  vocabulary('Vocabulary'),
  cohesion('Cohesion'),
  task('Task');

  const AnnotationType(this.label);

  final String label;
}

/// A note on one span of the essay. [start] and [end] are offsets into the
/// submitted text, and `text.substring(start, end) == original`.
@immutable
class Annotation {
  const Annotation({
    required this.id,
    required this.type,
    required this.criterionId,
    required this.start,
    required this.end,
    required this.original,
    required this.suggestion,
    required this.why,
  });

  final String id;
  final AnnotationType type;
  final String criterionId;
  final int start;
  final int end;
  final String original;

  /// A suggested alternative for the span, or for task notes what to add.
  final String suggestion;
  final String why;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'criterionId': criterionId,
    'start': start,
    'end': end,
    'original': original,
    'suggestion': suggestion,
    'why': why,
  };

  static Annotation fromJson(Map<String, dynamic> json) => Annotation(
    id: json['id'] as String,
    type: AnnotationType.values.byName(json['type'] as String),
    criterionId: json['criterionId'] as String,
    start: json['start'] as int,
    end: json['end'] as int,
    original: json['original'] as String,
    suggestion: json['suggestion'] as String,
    why: json['why'] as String,
  );
}

@immutable
class ParagraphNote {
  const ParagraphNote({required this.paragraph, required this.note});

  /// 0-based paragraph index.
  final int paragraph;
  final String note;

  Map<String, dynamic> toJson() => {'paragraph': paragraph, 'note': note};

  static ParagraphNote fromJson(Map<String, dynamic> json) => ParagraphNote(
    paragraph: json['paragraph'] as int,
    note: json['note'] as String,
  );
}

/// Feedback on one essay. This is the contract the AI backend will return.
@immutable
class WritingFeedback {
  const WritingFeedback({
    required this.taskType,
    required this.overall,
    required this.criteria,
    required this.topImprovements,
    required this.annotations,
    required this.paragraphNotes,
    required this.createdAt,
  });

  final WritingTaskType taskType;
  final EstimateRange overall;
  final List<CriterionFeedback> criteria;
  final List<TopImprovement> topImprovements;
  final List<Annotation> annotations;
  final List<ParagraphNote> paragraphNotes;
  final DateTime createdAt;

  CriterionFeedback? criterion(String id) =>
      criteria.where((c) => c.id == id).firstOrNull;

  List<Annotation> annotationsFor(String criterionId) => [
    for (final a in annotations)
      if (a.criterionId == criterionId) a,
  ];

  WritingFeedback copyWith({List<Annotation>? annotations}) => WritingFeedback(
    taskType: taskType,
    overall: overall,
    criteria: criteria,
    topImprovements: topImprovements,
    annotations: annotations ?? this.annotations,
    paragraphNotes: paragraphNotes,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'taskType': taskType.name,
    'overall': overall.toJson(),
    'criteria': [for (final c in criteria) c.toJson()],
    'topImprovements': [for (final t in topImprovements) t.toJson()],
    'annotations': [for (final a in annotations) a.toJson()],
    'paragraphNotes': [for (final p in paragraphNotes) p.toJson()],
    'createdAt': createdAt.toIso8601String(),
  };

  static WritingFeedback fromJson(Map<String, dynamic> json) => WritingFeedback(
    taskType: WritingTaskType.values.byName(json['taskType'] as String),
    overall: EstimateRange.fromJson(json['overall'] as Map<String, dynamic>),
    criteria: [
      for (final c in json['criteria'] as List)
        CriterionFeedback.fromJson(c as Map<String, dynamic>),
    ],
    topImprovements: [
      for (final t in json['topImprovements'] as List? ?? const [])
        TopImprovement.fromJson(t as Map<String, dynamic>),
    ],
    annotations: [
      for (final a in json['annotations'] as List? ?? const [])
        Annotation.fromJson(a as Map<String, dynamic>),
    ],
    paragraphNotes: [
      for (final p in json['paragraphNotes'] as List? ?? const [])
        ParagraphNote.fromJson(p as Map<String, dynamic>),
    ],
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// The outcome of [validateFeedback].
@immutable
class FeedbackValidation {
  const FeedbackValidation({
    required this.feedback,
    required this.errors,
    required this.droppedAnnotations,
  });

  /// The feedback with bad annotations removed; null when [errors] isn't
  /// empty.
  final WritingFeedback? feedback;

  /// Problems that make the feedback unusable.
  final List<String> errors;

  /// Ids of annotations removed because they don't match the essay.
  final List<String> droppedAnnotations;

  bool get isValid => errors.isEmpty;
}

/// Checks feedback against the rules before it is shown:
/// - every range is between 1 and 9, in 0.5 steps, and 0.5 wide;
/// - the criteria are exactly the task type's four;
/// - the overall range lies within the span of the criteria ranges.
///
/// Annotations that don't quote [essay] exactly (`essay[start:end] !=
/// original`), name another criterion, or overlap an earlier one are
/// dropped rather than failing the whole feedback.
FeedbackValidation validateFeedback(WritingFeedback feedback, String essay) {
  final errors = <String>[];

  void checkRange(String what, EstimateRange r) {
    bool onStep(double v) => (v * 2) == (v * 2).roundToDouble();
    if (r.low < 1 || r.high > 9) errors.add('$what is outside 1–9');
    if (!onStep(r.low) || !onStep(r.high)) {
      errors.add('$what is not in 0.5 steps');
    }
    if (r.high - r.low != 0.5) errors.add('$what is not 0.5 wide');
  }

  checkRange('overall', feedback.overall);
  for (final c in feedback.criteria) {
    checkRange(c.id, c.range);
  }

  final expected = [for (final c in feedback.taskType.criteria) c.id];
  final actual = [for (final c in feedback.criteria) c.id];
  if (actual.length != expected.length || !expected.every(actual.contains)) {
    errors.add(
      'criteria $actual do not match ${feedback.taskType.label} $expected',
    );
  }

  if (feedback.criteria.isNotEmpty) {
    final lowest = feedback.criteria
        .map((c) => c.range.low)
        .reduce((a, b) => a < b ? a : b);
    final highest = feedback.criteria
        .map((c) => c.range.high)
        .reduce((a, b) => a > b ? a : b);
    if (feedback.overall.low < lowest || feedback.overall.high > highest) {
      errors.add('overall is outside the criteria span $lowest–$highest');
    }
  }

  final kept = <Annotation>[];
  final dropped = <String>[];
  final sorted = [...feedback.annotations]
    ..sort((a, b) => a.start.compareTo(b.start));
  for (final a in sorted) {
    final quotes =
        a.start >= 0 &&
        a.end <= essay.length &&
        a.start < a.end &&
        essay.substring(a.start, a.end) == a.original;
    final overlaps = kept.isNotEmpty && a.start < kept.last.end;
    if (quotes && expected.contains(a.criterionId) && !overlaps) {
      kept.add(a);
    } else {
      dropped.add(a.id);
    }
  }

  return FeedbackValidation(
    feedback: errors.isEmpty ? feedback.copyWith(annotations: kept) : null,
    errors: errors,
    droppedAnnotations: dropped,
  );
}

/// General advice for an essay that wasn't analysed: no ranges, no
/// annotations.
@immutable
class GeneralWritingFeedback {
  const GeneralWritingFeedback({
    required this.taskType,
    required this.criteriaTips,
    required this.checklist,
  });

  final WritingTaskType taskType;

  /// One tip per criterion, in the task type's order.
  final Map<WritingCriterion, String> criteriaTips;

  /// Things to check before revising.
  final List<TopImprovement> checklist;
}
