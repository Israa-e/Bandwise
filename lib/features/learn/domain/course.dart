import 'package:flutter/foundation.dart';

/// The whole learning path: units of lessons, each ending in a checkpoint.
@immutable
class Course {
  const Course(this.units);

  final List<Unit> units;

  Unit unit(int number) => units.firstWhere((u) => u.number == number);

  /// Every lesson in path order (unit by unit, checkpoints included).
  Iterable<Lesson> get lessons => units.expand((u) => u.lessons);

  Lesson? lessonById(String id) => lessons.where((l) => l.id == id).firstOrNull;
}

@immutable
class Unit {
  const Unit({
    required this.number,
    required this.title,
    required this.focus,
    required this.lessons,
  });

  /// 1-based.
  final int number;
  final String title;

  /// Short tag such as "Vocabulary" or "Grammar".
  final String focus;

  /// Regular lessons in order, then the checkpoint last.
  final List<Lesson> lessons;

  /// "Unit 1: Everyday academic vocabulary".
  String get fullTitle => 'Unit $number: $title';
}

@immutable
class Lesson {
  const Lesson({
    required this.unit,
    required this.number,
    required this.title,
    required this.objective,
    required this.learnItems,
    required this.estimatedMinutes,
    this.exercises = const [],
    this.isCheckpoint = false,
  });

  /// 1-based unit number.
  final int unit;

  /// 1-based position in the unit. The checkpoint comes after the lessons.
  final int number;
  final String title;
  final String objective;

  /// The three "You will learn" points.
  final List<String> learnItems;
  final int estimatedMinutes;

  /// Empty until the lesson's content is written ("Content coming soon").
  final List<Exercise> exercises;
  final bool isCheckpoint;

  String get id => isCheckpoint ? 'u$unit-checkpoint' : 'u$unit-l$number';

  bool get isPlayable => exercises.isNotEmpty;

  /// Exercises that are scored (everything except flashcards).
  int get questionCount => exercises.whereType<QuestionExercise>().length;

  /// "Lesson 2" or "Checkpoint".
  String get label => isCheckpoint ? 'Checkpoint' : 'Lesson $number';
}

/// One step in a lesson.
@immutable
sealed class Exercise {
  const Exercise({required this.explanation});

  /// Shown after checking, or under a revealed flashcard.
  final String explanation;
}

/// A word to learn: front shows the word, reveal shows meaning and example.
/// Not scored.
class FlashcardExercise extends Exercise {
  const FlashcardExercise({
    required this.word,
    required this.partOfSpeech,
    required this.meaning,
    required this.example,
    required super.explanation,
  });

  final String word;

  /// e.g. "verb", "noun", "adjective".
  final String partOfSpeech;
  final String meaning;

  /// An academic example sentence using [word].
  final String example;
}

/// A scored exercise with one correct option.
sealed class QuestionExercise extends Exercise {
  const QuestionExercise({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required super.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];
}

class MultipleChoiceExercise extends QuestionExercise {
  const MultipleChoiceExercise({
    required super.prompt,
    required super.options,
    required super.correctIndex,
    required super.explanation,
    this.passage,
  });

  /// Optional sentence or short text the question is about.
  final String? passage;
}

/// A sentence with one gap ([blank]) and options to fill it.
class FillBlankExercise extends QuestionExercise {
  const FillBlankExercise({
    required this.sentence,
    required super.options,
    required super.correctIndex,
    required super.explanation,
    super.prompt = 'Choose the word that completes the sentence.',
  }) : assert(sentence != '');

  static const blank = '____';

  /// Contains [blank] exactly once.
  final String sentence;
}
