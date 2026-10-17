import 'package:flutter/foundation.dart';

/// The two IELTS Academic writing tasks.
enum WritingTaskType {
  task1(
    label: 'Task 1',
    kind: 'Academic report',
    minutes: 20,
    minWords: 150,
    criteria: [
      WritingCriterion.taskAchievement,
      WritingCriterion.coherenceCohesion,
      WritingCriterion.lexicalResource,
      WritingCriterion.grammaticalRange,
    ],
  ),
  task2(
    label: 'Task 2',
    kind: 'Essay',
    minutes: 40,
    minWords: 250,
    criteria: [
      WritingCriterion.taskResponse,
      WritingCriterion.coherenceCohesion,
      WritingCriterion.lexicalResource,
      WritingCriterion.grammaticalRange,
    ],
  );

  const WritingTaskType({
    required this.label,
    required this.kind,
    required this.minutes,
    required this.minWords,
    required this.criteria,
  });

  final String label;
  final String kind;

  /// Recommended (and, in timed mode, allowed) time.
  final int minutes;

  /// Responses under this are penalised.
  final int minWords;

  /// The four criteria, in the order they are shown. Task 1 uses Task
  /// Achievement; Task 2 uses Task Response.
  final List<WritingCriterion> criteria;

  /// "20 min · 150+ words".
  String get summary => '$minutes min · $minWords+ words';
}

/// An assessment criterion. [id] is the backend contract's criterion id.
enum WritingCriterion {
  taskAchievement('taskAchievement', 'Task Achievement'),
  taskResponse('taskResponse', 'Task Response'),
  coherenceCohesion('coherenceCohesion', 'Coherence and Cohesion'),
  lexicalResource('lexicalResource', 'Lexical Resource'),
  grammaticalRange('grammaticalRange', 'Grammatical Range and Accuracy');

  const WritingCriterion(this.id, this.label);

  final String id;
  final String label;

  static WritingCriterion? byId(String id) =>
      values.where((c) => c.id == id).firstOrNull;
}

enum WritingMode { learning, timed }

/// One series of a line graph, e.g. a city.
@immutable
class ChartSeries {
  const ChartSeries(this.name, this.values);

  final String name;

  /// One value per x label.
  final List<num> values;
}

/// A line graph for a Task 1 prompt.
@immutable
class LineChartData {
  const LineChartData({
    required this.title,
    required this.xLabels,
    required this.series,
    required this.yMax,
    required this.yStep,
    required this.unit,
  });

  final String title;
  final List<String> xLabels;
  final List<ChartSeries> series;
  final num yMax;
  final num yStep;

  /// Appended to values, e.g. "%".
  final String unit;
}

/// A writing prompt with its sample essay.
@immutable
class WritingTask {
  const WritingTask({
    required this.id,
    required this.type,
    required this.topic,
    required this.prompt,
    required this.instructions,
    required this.sampleEssay,
    this.chart,
  });

  final String id;
  final WritingTaskType type;

  /// Short label for lists, e.g. "Cycling to work".
  final String topic;
  final String prompt;

  /// "Summarise the information…" / "Write at least 250 words."
  final String instructions;

  /// A mid-level answer to the prompt, with the kind of errors learners
  /// make. Used by the mock feedback and the debug "Use sample essay".
  final String sampleEssay;

  /// Task 1 only.
  final LineChartData? chart;
}

final _word = RegExp(r"[A-Za-z0-9À-ɏ]+(?:['’.,\-][A-Za-z0-9À-ɏ]+)*");

/// Words in [text] as IELTS counts them: a run of letters or digits,
/// keeping "it's", "well-known", "12%" (as "12") and "3.5" together.
int countWords(String text) => _word.allMatches(text).length;

/// Paragraphs of [text]: non-empty blocks separated by line breaks.
List<String> paragraphsOf(String text) => [
  for (final p in text.split(RegExp(r'\n+')))
    if (p.trim().isNotEmpty) p.trim(),
];

/// [text] with paragraphs separated by exactly one blank line and no
/// trailing spaces, so equal essays compare equal.
String normalizeEssay(String text) => paragraphsOf(
  text,
).map((p) => p.replaceAll(RegExp(r'[ \t]+'), ' ')).join('\n\n');

/// Each paragraph of [text] (as in [paragraphsOf]) with its offset in
/// [text], so annotation offsets can be placed in it.
List<({int start, String text})> paragraphSpansOf(String text) => [
  for (final m in RegExp(r'[^\n]+').allMatches(text))
    if (m[0]!.trim() case final p when p.isNotEmpty)
      (start: m.start + m[0]!.indexOf(p), text: p),
];
