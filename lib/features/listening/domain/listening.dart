import 'package:flutter/foundation.dart';

enum ListeningMode {
  /// Pause, replay and seek; Check per question with the explanation;
  /// reading time can be skipped.
  learning,

  /// Like the exam: the audio plays once with no pause or seek, and
  /// answers are marked when submitted.
  timed,
}

/// Question types, in the order a set lists them.
enum ListeningQuestionType {
  formCompletion('Form completion'),
  multipleChoice('Multiple choice'),
  matching('Matching');

  const ListeningQuestionType(this.label);

  final String label;
}

@immutable
class ListeningSpeaker {
  const ListeningSpeaker({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final String role;
}

/// One line of the recording, as spoken by one speaker.
@immutable
class TranscriptLine {
  const TranscriptLine({
    required this.id,
    required this.speakerId,
    required this.text,
  });

  /// Fixed id such as "a014"; questions point at it as their evidence.
  final String id;
  final String speakerId;
  final String text;
}

/// Where a line is in the audio.
@immutable
class LineTiming {
  const LineTiming(this.start, this.end);

  final Duration start;
  final Duration end;
}

/// A lettered option of a multiple-choice or matching question.
@immutable
class ListeningOption {
  const ListeningOption(this.key, this.text);

  /// "A", "B", "C"…
  final String key;
  final String text;
}

/// The most words and numbers a completion answer may have, e.g. ONE WORD
/// AND/OR A NUMBER.
@immutable
class WordLimit {
  const WordLimit({
    required this.maxWords,
    required this.maxNumbers,
    required this.label,
  });

  final int maxWords;
  final int maxNumbers;

  /// As the instructions write it: "ONE WORD AND/OR A NUMBER".
  final String label;

  static final _number = RegExp(r'^[£$]?\d[\d,.:/]*(st|nd|rd|th)?$');

  /// Words and numbers in [answer], counted as IELTS does: a run of digit
  /// groups such as a phone number, or "6th", is one number.
  static ({int words, int numbers}) count(String answer) {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return (words: 0, numbers: 0);
    var words = 0;
    var numbers = 0;
    var previousWasNumber = false;
    for (final token in trimmed.split(RegExp(r'\s+'))) {
      final isNumber = _number.hasMatch(token);
      if (isNumber && !previousWasNumber) numbers++;
      if (!isNumber) words++;
      previousWasNumber = isNumber;
    }
    return (words: words, numbers: numbers);
  }

  bool allows(String answer) {
    final c = count(answer);
    return c.words <= maxWords && c.numbers <= maxNumbers;
  }
}

@immutable
class ListeningQuestion {
  const ListeningQuestion({
    required this.id,
    required this.number,
    required this.type,
    required this.prompt,
    this.options = const [],
    required this.answer,
    this.variants = const [],
    this.wordLimit,
    required this.explanation,
    required this.evidence,
    required this.evidenceLineId,
  });

  /// Unique across the app ("set_a:q3"), so saved mistakes can refer to it.
  final String id;

  /// The question number as in the exam: 1–10 in Part 1, 21–30 in Part 3.
  final int number;
  final ListeningQuestionType type;

  /// A form line with a blank ("Surname: ______"), a question, or the item
  /// to match.
  final String prompt;

  /// For multiple choice and matching.
  final List<ListeningOption> options;

  /// The option key, or the words to write.
  final String answer;

  /// Other accepted answers for completion questions. Matching ignores
  /// case and spaces between digits, but spelling must be exact.
  final List<String> variants;

  /// For completion questions.
  final WordLimit? wordLimit;
  final String explanation;

  /// The words in the evidence line that give the answer.
  final String evidence;
  final String evidenceLineId;

  static const blank = '______';

  bool get isChoice => options.isNotEmpty;

  ListeningOption? optionFor(String? key) =>
      options.where((o) => o.key == key).firstOrNull;

  /// "B. They had seen the problem for themselves." or the words to write.
  String get correctAnswer => describe(answer)!;

  /// Lower case, trimmed, single spaces, and no spaces between digits, so
  /// "07723 418590" matches "07723418590".
  static String normalize(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(RegExp(r'(\d) (?=\d)'), (m) => m[1]!);

  bool isAnswered(String? response) =>
      response != null && response.trim().isNotEmpty;

  bool isCorrect(String? response) {
    if (!isAnswered(response)) return false;
    if (isChoice) return response == answer;
    final limit = wordLimit;
    if (limit != null && !limit.allows(response!)) return false;
    final given = normalize(response!);
    return [answer, ...variants].any((a) => normalize(a) == given);
  }

  /// [response] as text: "B. …" for an option, or what was typed.
  String? describe(String? response) {
    if (!isAnswered(response)) return null;
    if (!isChoice) return response!.trim();
    final option = optionFor(response);
    return option == null ? null : '${option.key}. ${option.text}';
  }
}

/// Questions answered together, with their instructions and the reading
/// time before them.
@immutable
class QuestionGroup {
  const QuestionGroup({
    required this.first,
    required this.last,
    required this.instructions,
    required this.heading,
    required this.readingTimeAfterLineId,
    required this.readingTime,
  });

  /// Question numbers, inclusive.
  final int first;
  final int last;
  final String instructions;
  final String heading;

  /// The line announcing the reading time ("…you have some time to look at
  /// questions 1 to 5"). The audio pauses after it.
  final String readingTimeAfterLineId;
  final Duration readingTime;

  /// "Questions 1–5".
  String get label =>
      first == last ? 'Question $first' : 'Questions $first–$last';

  bool contains(ListeningQuestion q) => q.number >= first && q.number <= last;
}

/// A recording with its transcript and questions.
@immutable
class ListeningSet {
  const ListeningSet({
    required this.id,
    required this.title,
    required this.part,
    required this.context,
    required this.speakers,
    required this.lines,
    required this.groups,
    required this.questions,
    required this.audioAsset,
    this.timings = const {},
  });

  /// After the recording ends, as in the exam.
  static const checkTime = Duration(minutes: 1);

  final String id;
  final String title;

  /// The exam part this set practises: 1–4.
  final int part;

  /// One line about the recording, shown in the hub.
  final String context;
  final List<ListeningSpeaker> speakers;
  final List<TranscriptLine> lines;
  final List<QuestionGroup> groups;
  final List<ListeningQuestion> questions;
  final String audioAsset;

  /// Where each line is in the audio, by line id. Empty until the audio is
  /// built.
  final Map<String, LineTiming> timings;

  bool get hasAudio => timings.length == lines.length;

  Duration get audioLength =>
      timings.values.fold(Duration.zero, (end, t) => t.end > end ? t.end : end);

  /// The audio plus reading and check time: how long timed practice takes.
  Duration get timedLength =>
      groups.fold(audioLength + checkTime, (sum, g) => sum + g.readingTime);

  ListeningSpeaker? speaker(String id) =>
      speakers.where((s) => s.id == id).firstOrNull;

  int lineIndex(String lineId) => lines.indexWhere((l) => l.id == lineId);

  ListeningQuestion? questionById(String id) =>
      questions.where((q) => q.id == id).firstOrNull;

  List<ListeningQuestion> questionsIn(QuestionGroup group) =>
      questions.where(group.contains).toList();

  /// Questions whose answer is in line [lineId].
  List<ListeningQuestion> questionsAt(String lineId) =>
      questions.where((q) => q.evidenceLineId == lineId).toList();

  /// Question types this set has, in order.
  List<ListeningQuestionType> get types => [
    for (final t in ListeningQuestionType.values)
      if (questions.any((q) => q.type == t)) t,
  ];

  /// The line being played at [position]: the last one started by then, so
  /// a pause belongs to the line before it.
  int? lineAt(Duration position) {
    int? current;
    for (final (i, line) in lines.indexed) {
      final timing = timings[line.id];
      if (timing == null || timing.start > position) break;
      current = i;
    }
    return current;
  }

  /// Where the audio pauses for reading time, in order.
  List<({Duration at, QuestionGroup group})> get readingStops => [
    for (final g in groups)
      if (timings[g.readingTimeAfterLineId] case final t?)
        (at: t.end, group: g),
  ];
}

/// Correct answers out of questions for one type.
@immutable
class ListeningScore {
  const ListeningScore(this.correct, this.total);

  final int correct;
  final int total;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
}

/// Grades [questions] against [responses] (by question id).
@immutable
class ListeningGrade {
  ListeningGrade(this.questions, this.responses);

  final List<ListeningQuestion> questions;
  final Map<String, String> responses;

  bool isCorrect(ListeningQuestion q) => q.isCorrect(responses[q.id]);

  late final int correct = questions.where(isCorrect).length;
  int get total => questions.length;

  /// Score per question type, in [ListeningQuestionType] order.
  late final Map<ListeningQuestionType, ListeningScore> byType = {
    for (final t in ListeningQuestionType.values)
      if (questions.any((q) => q.type == t))
        t: ListeningScore(
          questions.where((q) => q.type == t && isCorrect(q)).length,
          questions.where((q) => q.type == t).length,
        ),
  };

  List<ListeningQuestion> get wrong =>
      questions.where((q) => !isCorrect(q)).toList();
}
