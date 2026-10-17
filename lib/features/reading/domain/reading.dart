import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Question types, in the order a passage lists them.
enum ReadingQuestionType {
  trueFalseNotGiven('True / False / Not Given'),
  multipleChoice('Multiple choice'),
  matchingHeadings('Matching headings'),
  sentenceCompletion('Sentence completion');

  const ReadingQuestionType(this.label);

  final String label;
}

enum ReadingMode {
  /// No timer; Check per question with the explanation.
  learning,

  /// The full passage in [ReadingPassage.timedMinutes], no feedback until
  /// submitted.
  timed,
}

/// A paragraph of a passage, stored sentence by sentence so evidence can
/// point at an exact sentence.
@immutable
class ReadingParagraph {
  const ReadingParagraph(this.sentences);

  final List<String> sentences;

  /// The sentences joined by single spaces.
  String get text => sentences.join(' ');

  /// Where sentence [index] sits in [text].
  TextRange rangeOf(int index) {
    var start = 0;
    for (var i = 0; i < index; i++) {
      start += sentences[i].length + 1;
    }
    return TextRange(start: start, end: start + sentences[index].length);
  }
}

/// Where the answer to a question is found: a paragraph and a sentence in
/// it, both 0-based.
@immutable
class EvidenceSpan {
  const EvidenceSpan(this.paragraph, this.sentence);

  final int paragraph;
  final int sentence;

  @override
  bool operator ==(Object other) =>
      other is EvidenceSpan &&
      other.paragraph == paragraph &&
      other.sentence == sentence;

  @override
  int get hashCode => Object.hash(paragraph, sentence);
}

/// An academic reading passage with its questions.
@immutable
class ReadingPassage {
  const ReadingPassage({
    required this.id,
    required this.title,
    required this.topic,
    required this.paragraphs,
    required this.questions,
  });

  static const timedMinutes = 20;

  final String id;
  final String title;

  /// One line about the subject, shown in the hub.
  final String topic;

  /// Labelled A, B, C… in order.
  final List<ReadingParagraph> paragraphs;
  final List<ReadingQuestion> questions;

  static String paragraphLabel(int index) => String.fromCharCode(65 + index);

  int get wordCount =>
      paragraphs.fold(0, (sum, p) => sum + p.text.split(RegExp(r'\s+')).length);

  ReadingQuestion? questionById(String id) =>
      questions.where((q) => q.id == id).firstOrNull;

  /// The questions to practise: all of them, or only [type].
  List<ReadingQuestion> questionsFor(ReadingQuestionType? type) => type == null
      ? questions
      : questions.where((q) => q.type == type).toList();

  /// Question types this passage has, in order.
  List<ReadingQuestionType> get types => [
    for (final t in ReadingQuestionType.values)
      if (questions.any((q) => q.type == t)) t,
  ];
}

/// The learner's answer to one question.
@immutable
sealed class ReadingResponse {
  const ReadingResponse();
}

/// An option index into [ChoiceReadingQuestion.options].
class ChoiceResponse extends ReadingResponse {
  const ChoiceResponse(this.index);

  final int index;

  @override
  bool operator ==(Object other) =>
      other is ChoiceResponse && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// Typed words for a completion question.
class TextResponse extends ReadingResponse {
  const TextResponse(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is TextResponse && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

@immutable
sealed class ReadingQuestion {
  const ReadingQuestion({
    required this.id,
    required this.explanation,
    required this.evidence,
  });

  /// Fixed id such as "uhi-q3". Saved mistakes refer to it.
  final String id;
  final String explanation;
  final EvidenceSpan evidence;

  ReadingQuestionType get type;

  /// The question text as shown and as saved with a mistake.
  String get prompt;

  String get correctAnswer;

  /// The answer is "Not Given": the passage has no information on it, so
  /// its evidence is only the related part of the passage.
  bool get isNotGiven => false;

  bool isAnswered(ReadingResponse? response);
  bool isCorrect(ReadingResponse? response);

  /// [response] as text, e.g. "Not Given" or what was typed.
  String? describe(ReadingResponse? response);
}

/// A question answered by picking one of [options].
sealed class ChoiceReadingQuestion extends ReadingQuestion {
  const ChoiceReadingQuestion({
    required super.id,
    required super.explanation,
    required super.evidence,
  });

  List<String> get options;
  int get correctIndex;

  /// Whether a review may show [options] in a shuffled order. True / False /
  /// Not Given keep their conventional order.
  bool get shuffleOptions => true;

  @override
  String get correctAnswer => options[correctIndex];

  @override
  bool isAnswered(ReadingResponse? response) => response is ChoiceResponse;

  @override
  bool isCorrect(ReadingResponse? response) =>
      response is ChoiceResponse && response.index == correctIndex;

  @override
  String? describe(ReadingResponse? response) => switch (response) {
    ChoiceResponse(:final index) when index >= 0 && index < options.length =>
      options[index],
    _ => null,
  };
}

enum Tfng {
  /// The statement agrees with the information in the passage.
  trueAnswer('True'),

  /// The statement contradicts the information in the passage.
  falseAnswer('False'),

  /// There is no information on this in the passage.
  notGiven('Not Given');

  const Tfng(this.label);

  final String label;
}

class TfngQuestion extends ChoiceReadingQuestion {
  const TfngQuestion({
    required super.id,
    required this.statement,
    required this.answer,
    required super.explanation,
    required super.evidence,
  });

  static final labels = [for (final t in Tfng.values) t.label];

  final String statement;
  final Tfng answer;

  @override
  ReadingQuestionType get type => ReadingQuestionType.trueFalseNotGiven;

  @override
  String get prompt => statement;

  @override
  List<String> get options => labels;

  @override
  int get correctIndex => answer.index;

  @override
  bool get shuffleOptions => false;

  @override
  bool get isNotGiven => answer == Tfng.notGiven;
}

class ReadingMultipleChoiceQuestion extends ChoiceReadingQuestion {
  const ReadingMultipleChoiceQuestion({
    required super.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required super.explanation,
    required super.evidence,
  });

  @override
  final String prompt;
  @override
  final List<String> options;
  @override
  final int correctIndex;

  @override
  ReadingQuestionType get type => ReadingQuestionType.multipleChoice;
}

/// Choose the heading for one paragraph from the passage's list of
/// headings ([options]), which includes headings that fit no paragraph.
/// The evidence is the sentence that best shows the paragraph's topic.
class HeadingQuestion extends ChoiceReadingQuestion {
  const HeadingQuestion({
    required super.id,
    required this.paragraph,
    required this.options,
    required this.correctIndex,
    required super.explanation,
    required super.evidence,
  });

  /// 0-based paragraph index.
  final int paragraph;
  @override
  final List<String> options;
  @override
  final int correctIndex;

  @override
  ReadingQuestionType get type => ReadingQuestionType.matchingHeadings;

  @override
  String get prompt => 'Paragraph ${ReadingPassage.paragraphLabel(paragraph)}';

  /// "i", "ii" … "x" for the heading at [index].
  static String numeral(int index) => const [
    'i',
    'ii',
    'iii',
    'iv',
    'v',
    'vi',
    'vii',
    'viii',
    'ix',
    'x',
  ][index];
}

/// Complete a sentence with words from the passage.
class CompletionQuestion extends ReadingQuestion {
  const CompletionQuestion({
    required super.id,
    required this.sentence,
    required this.answer,
    this.variants = const [],
    this.maxWords = 2,
    required super.explanation,
    required super.evidence,
  });

  static const blank = '____';

  /// Contains [blank] once.
  final String sentence;
  final String answer;

  /// Other accepted answers. Matching ignores case and extra spaces, but
  /// spelling must be exact.
  final List<String> variants;
  final int maxWords;

  @override
  ReadingQuestionType get type => ReadingQuestionType.sentenceCompletion;

  @override
  String get prompt => sentence;

  @override
  String get correctAnswer => answer;

  /// "NO MORE THAN TWO WORDS".
  String get wordLimitLabel =>
      'NO MORE THAN ${const ['ONE', 'TWO', 'THREE'][maxWords - 1]} '
      '${maxWords == 1 ? 'WORD' : 'WORDS'}';

  /// Lower case, trimmed, with single spaces between words.
  static String normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static int wordCount(String text) {
    final n = normalize(text);
    return n.isEmpty ? 0 : n.split(' ').length;
  }

  @override
  bool isAnswered(ReadingResponse? response) =>
      response is TextResponse && normalize(response.text).isNotEmpty;

  @override
  bool isCorrect(ReadingResponse? response) {
    if (response is! TextResponse) return false;
    final given = normalize(response.text);
    if (given.isEmpty || wordCount(given) > maxWords) return false;
    return [answer, ...variants].any((a) => normalize(a) == given);
  }

  @override
  String? describe(ReadingResponse? response) =>
      isAnswered(response) ? (response! as TextResponse).text.trim() : null;
}

/// Correct answers out of answered-or-not questions.
@immutable
class ReadingScore {
  const ReadingScore(this.correct, this.total);

  final int correct;
  final int total;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
}

/// Grades [questions] against [responses] (by question id).
@immutable
class ReadingGrade {
  ReadingGrade(this.questions, this.responses);

  final List<ReadingQuestion> questions;
  final Map<String, ReadingResponse> responses;

  bool isCorrect(ReadingQuestion q) => q.isCorrect(responses[q.id]);

  late final int correct = questions.where(isCorrect).length;
  int get total => questions.length;

  /// Score per question type, in [ReadingQuestionType] order.
  late final Map<ReadingQuestionType, ReadingScore> byType = {
    for (final t in ReadingQuestionType.values)
      if (questions.any((q) => q.type == t))
        t: ReadingScore(
          questions.where((q) => q.type == t && isCorrect(q)).length,
          questions.where((q) => q.type == t).length,
        ),
  };

  List<ReadingQuestion> get wrong =>
      questions.where((q) => !isCorrect(q)).toList();
}
