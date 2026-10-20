import 'package:flutter/foundation.dart';

import 'writing.dart';

/// A rule-based check of an essay's length or layout. Not AI: shown as
/// "Checked automatically".
@immutable
class EssayCheck {
  const EssayCheck({
    required this.id,
    required this.passed,
    required this.title,
    this.suggestion,
  });

  final String id;
  final bool passed;

  /// E.g. "15 words — Task 2 needs at least 250".
  final String title;

  /// What to change, when the check didn't pass.
  final String? suggestion;
}

/// Paragraphs a [type] essay is expected to have, and how to lay them out.
const _paragraphPlan = {
  WritingTaskType.task1: (
    minimum: 3,
    plan: 'an introduction, an overview and one or two body paragraphs',
  ),
  WritingTaskType.task2: (
    minimum: 4,
    plan: 'an introduction, two body paragraphs and a conclusion',
  ),
};

String _plural(int n, String word) => n == 1 ? '1 $word' : '$n ${word}s';

/// Word count against the minimum, and paragraph count, worked out from
/// [text]. Numbers are counted, never estimated.
List<EssayCheck> essayChecks(WritingTaskType type, String text) {
  final words = countWords(text);
  final paragraphs = paragraphsOf(text).length;
  final layout = _paragraphPlan[type]!;
  final wordsLabel = _plural(words, 'word');
  final paragraphsLabel = _plural(paragraphs, 'paragraph');
  return [
    words < type.minWords
        ? EssayCheck(
            id: 'wordCount',
            passed: false,
            title:
                '$wordsLabel — ${type.label} needs at least ${type.minWords}',
            suggestion:
                'Answers under ${type.minWords} words lose marks. Develop '
                'your points further before you resubmit.',
          )
        : EssayCheck(
            id: 'wordCount',
            passed: true,
            title: '$wordsLabel — meets the ${type.minWords}-word minimum',
          ),
    paragraphs < layout.minimum
        ? EssayCheck(
            id: 'paragraphs',
            passed: false,
            title: paragraphsLabel,
            suggestion: 'Use ${layout.plan}.',
          )
        : EssayCheck(id: 'paragraphs', passed: true, title: paragraphsLabel),
  ];
}
