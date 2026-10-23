import 'package:flutter/foundation.dart';

enum SpeakingPart {
  part1('Part 1', 'Questions about yourself'),
  part2('Part 2', 'Long turn with a cue card'),
  part3('Part 3', 'Discussion');

  const SpeakingPart(this.label, this.description);

  final String label;
  final String description;
}

enum SpeakingMode {
  /// One question at a time; record, play back, re-record; no time
  /// pressure.
  practice('Practice'),

  /// Like practice, with no visible timers, a calm layout and gentle
  /// prompts. Never scored.
  confidence('Confidence'),

  /// The real format: the examiner's questions play once and recording
  /// starts after each; no hints.
  timed('Timed test');

  const SpeakingMode(this.label);

  final String label;
}

/// Something the examiner says, with its recording. Every line, question
/// included, has a stable id that names its audio file.
@immutable
class ExaminerLine {
  const ExaminerLine({required this.id, required this.text});

  final String id;
  final String text;

  String get audioAsset => 'assets/speaking/mp3/$id.mp3';
}

/// A question the candidate answers.
@immutable
class SpeakingQuestion extends ExaminerLine {
  const SpeakingQuestion({
    required super.id,
    required super.text,
    required this.part,
  });

  final SpeakingPart part;
}

/// A Part 1 topic: the examiner introduces it, then asks its questions.
@immutable
class Part1Topic {
  const Part1Topic({
    required this.id,
    required this.title,
    required this.intro,
    required this.questions,
  });

  final String id;
  final String title;
  final ExaminerLine intro;
  final List<SpeakingQuestion> questions;
}

/// A Part 2 cue card with its rounding-off question and the Part 3
/// discussion on its theme.
@immutable
class CueCard {
  const CueCard({
    required this.id,
    required this.title,
    required this.topic,
    required this.prompt,
    required this.bullets,
    required this.explain,
    required this.roundingOff,
    required this.part3Title,
    required this.part3Intro,
    required this.part3Questions,
  });

  final String id;

  /// Short name for lists: "A skill you learned".
  final String title;

  /// What the examiner says when handing over the card.
  final ExaminerLine topic;

  /// "Describe a skill you learned outside school or work."
  final String prompt;

  /// "You should say:" points.
  final List<String> bullets;

  /// "and explain how this skill has been useful to you."
  final String explain;

  /// The long turn itself, as a question: the card is the prompt. Its id is
  /// the card's.
  SpeakingQuestion get longTurn =>
      SpeakingQuestion(id: id, text: prompt, part: SpeakingPart.part2);

  /// Asked straight after the long turn.
  final SpeakingQuestion roundingOff;

  final String part3Title;
  final ExaminerLine part3Intro;
  final List<SpeakingQuestion> part3Questions;
}

/// All speaking content, from assets/speaking/content.json.
@immutable
class SpeakingContent {
  SpeakingContent({
    required this.examiner,
    required this.part1,
    required this.cueCards,
  });

  final Map<String, ExaminerLine> examiner;
  final List<Part1Topic> part1;
  final List<CueCard> cueCards;

  ExaminerLine line(String id) => examiner[id]!;

  /// Every line with audio, in a stable order.
  List<ExaminerLine> get allLines => [
    ...examiner.values,
    for (final t in part1) ...[t.intro, ...t.questions],
    for (final c in cueCards) ...[
      c.topic,
      c.roundingOff,
      c.part3Intro,
      ...c.part3Questions,
    ],
  ];

  /// Questions by id, the Part 2 long turns included.
  late final Map<String, SpeakingQuestion> questions = {
    for (final t in part1)
      for (final q in t.questions) q.id: q,
    for (final c in cueCards) ...{
      c.id: c.longTurn,
      c.roundingOff.id: c.roundingOff,
      for (final q in c.part3Questions) q.id: q,
    },
  };

  CueCard? cueCard(String id) => cueCards.where((c) => c.id == id).firstOrNull;

  /// The card a question belongs to (its long turn, rounding-off or Part 3
  /// question).
  CueCard? cueCardFor(String questionId) => cueCards
      .where(
        (c) =>
            c.id == questionId ||
            c.roundingOff.id == questionId ||
            c.part3Questions.any((q) => q.id == questionId),
      )
      .firstOrNull;
}

/// The four speaking criteria, with plain-language statements the learner
/// can tick about their own answers. Ticks are saved but never turned into
/// a score.
enum SpeakingCriterion {
  fluencyCoherence('Fluency and Coherence', [
    'Can I keep talking without long pauses?',
    'Can I link my ideas with words like "because", "so" and "on the other '
        'hand"?',
    'Can I give a reason or an example for my answers?',
    'Can I keep going for most of the two minutes in Part 2?',
  ]),
  lexicalResource('Lexical Resource', [
    'Can I use words for the topic instead of very general ones?',
    "Can I explain an idea another way when I can't find a word?",
    'Can I use a few less common words or phrases correctly?',
  ]),
  grammaticalRange('Grammatical Range and Accuracy', [
    'Can I use past, present and future forms correctly?',
    'Can I use longer sentences with "when", "if" or "which"?',
    'Can I speak without mistakes that make me hard to follow?',
  ]),
  pronunciation('Pronunciation', [
    'Can I be understood without the listener working hard?',
    'Can I stress the important words in a sentence?',
    'Can I say word endings like -ed and -s clearly?',
    'Can I let my voice rise and fall naturally?',
  ]);

  const SpeakingCriterion(this.label, this.statements);

  final String label;
  final List<String> statements;
}

/// Confidence mode: questions that help organise ideas, by part.
List<String> gentlePromptsFor(SpeakingPart part) => switch (part) {
  SpeakingPart.part1 => [
    'Answer the question first.',
    'Then add a reason or a small example.',
  ],
  SpeakingPart.part2 => [
    'Who?',
    'When?',
    'Where?',
    'What happened?',
    'Why did it matter?',
  ],
  SpeakingPart.part3 => [
    'What do you think?',
    'Why?',
    'Can you give an example?',
    'Would anyone see it differently?',
  ],
};
