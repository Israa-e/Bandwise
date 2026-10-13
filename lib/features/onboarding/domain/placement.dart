import 'package:flutter/foundation.dart';

import 'onboarding_state.dart';

/// One multiple-choice question in the placement check.
@immutable
class PlacementQuestion {
  const PlacementQuestion({
    required this.category,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.passage,
  });

  /// e.g. "Grammar", "Vocabulary", "Reading".
  final String category;

  /// e.g. "Sentence completion".
  final String type;
  final String prompt;

  /// Sentence or short passage shown under the prompt. "____" marks a gap.
  final String? passage;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

/// Where the plan suggests the learner starts. Rule-based, not a level or band.
@immutable
class StartingPoint {
  const StartingPoint({required this.title, required this.reason});

  final String title;
  final String reason;

  static const _units = [
    'Unit 1: Everyday academic vocabulary',
    'Unit 2: Sentence structure for academic English',
    'Unit 3: Paraphrasing and argument structure',
  ];

  /// Picks a starting unit from the placement score, or from the
  /// self-assessment when placement was skipped.
  static StartingPoint recommend({
    required int? correctAnswers,
    required int totalQuestions,
    required EnglishLevel? selfAssessed,
  }) {
    if (correctAnswers != null && totalQuestions > 0) {
      final ratio = correctAnswers / totalQuestions;
      final unit = ratio < 0.4 ? 0 : (ratio < 0.75 ? 1 : 2);
      return StartingPoint(
        title: _units[unit],
        reason:
            'Based on your placement check '
            '($correctAnswers of $totalQuestions correct).',
      );
    }
    if (selfAssessed != null) {
      final unit = switch (selfAssessed) {
        EnglishLevel.beginner || EnglishLevel.elementary => 0,
        EnglishLevel.intermediate => 1,
        EnglishLevel.upperIntermediate || EnglishLevel.advanced => 2,
      };
      return StartingPoint(
        title: _units[unit],
        reason: 'Based on your self-assessment. You can change it anytime.',
      );
    }
    return StartingPoint(
      title: _units[0],
      reason: 'Starting from the beginning. You can change it anytime.',
    );
  }
}
