import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/learn/domain/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every piece of learner-facing text in [lesson].
Iterable<String> _texts(Lesson lesson) sync* {
  yield lesson.title;
  yield lesson.objective;
  yield* lesson.learnItems;
  for (final e in lesson.exercises) {
    yield e.explanation;
    switch (e) {
      case FlashcardExercise():
        yield e.word;
        yield e.partOfSpeech;
        yield e.meaning;
        yield e.example;
      case MultipleChoiceExercise():
        yield e.prompt;
        if (e.passage != null) yield e.passage!;
        yield* e.options;
      case FillBlankExercise():
        yield e.prompt;
        yield e.sentence;
        yield* e.options;
    }
  }
}

final _allTexts = [for (final l in course.lessons) ..._texts(l)];

/// Whitespace- and case-insensitive.
String _norm(String s) =>
    s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

void main() {
  final regular = [
    for (final l in course.lessons)
      if (!l.isCheckpoint) l,
  ];
  final checkpoints = [
    for (final l in course.lessons)
      if (l.isCheckpoint) l,
  ];

  group('structure', () {
    test('three units of five lessons and a checkpoint', () {
      expect(course.units, hasLength(3));
      for (final unit in course.units) {
        expect(unit.lessons, hasLength(6));
        expect(unit.lessons.last.isCheckpoint, isTrue);
        expect(unit.lessons.where((l) => l.isCheckpoint), hasLength(1));
      }
    });

    test('exercise ids are unique across the course', () {
      final ids = [
        for (final l in course.lessons)
          for (final e in l.exercises) e.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('lesson ids and titles are unchanged', () {
      expect(
        [for (final l in course.lessons) '${l.id} ${l.title}'],
        [
          'u1-l1 Words for describing change',
          'u1-l2 Verbs for research and reporting',
          'u1-l3 Nouns for ideas and evidence',
          'u1-l4 Collocations in academic writing',
          'u1-l5 Linking words for contrast',
          'u1-checkpoint Unit 1 checkpoint',
          'u2-l1 Clauses and complete sentences',
          'u2-l2 Relative clauses',
          'u2-l3 The passive in academic writing',
          'u2-l4 Conditionals for possibilities',
          'u2-l5 Building longer noun phrases',
          'u2-checkpoint Unit 2 checkpoint',
          'u3-l1 Paraphrasing with synonyms',
          'u3-l2 Changing word forms',
          'u3-l3 Changing sentence structure',
          'u3-l4 Building a clear main argument',
          'u3-l5 Supporting ideas with examples',
          'u3-checkpoint Unit 3 checkpoint',
        ],
      );
    });

    test('every lesson has an objective, three learn items and minutes', () {
      for (final l in course.lessons) {
        expect(l.objective.trim(), isNotEmpty, reason: l.id);
        expect(l.learnItems, hasLength(3), reason: l.id);
        expect(l.estimatedMinutes, greaterThan(0), reason: l.id);
      }
    });

    test('each lesson has 6 exercises; each checkpoint has 10 questions', () {
      for (final l in regular) {
        expect(l.exercises, hasLength(6), reason: l.id);
        expect(l.questionCount, greaterThanOrEqualTo(3), reason: l.id);
      }
      for (final l in checkpoints) {
        expect(l.exercises, hasLength(10), reason: l.id);
        expect(l.questionCount, 10, reason: l.id);
        expect(Lesson.masteryScore, 8);
      }
    });

    test('ids follow the lesson they belong to', () {
      for (final l in regular) {
        for (final (i, e) in l.exercises.indexed) {
          expect(e.id, '${l.id}-e${i + 1}');
        }
      }
    });

    test('vocabulary lessons start with 2-3 flashcards, others with none', () {
      for (final l in regular) {
        final leading = l.exercises.takeWhile((e) => e is FlashcardExercise);
        final total = l.exercises.whereType<FlashcardExercise>().length;
        expect(leading.length, total, reason: '${l.id}: flashcards first');
      }
      for (final id in ['u1-l2', 'u1-l3', 'u1-l4']) {
        final n = course
            .lessonById(id)!
            .exercises
            .whereType<FlashcardExercise>()
            .length;
        expect(n, inInclusiveRange(2, 3), reason: id);
      }
      for (final id in [
        'u1-l5',
        'u2-l2',
        'u2-l3',
        'u2-l4',
        'u2-l5',
        'u3-l2',
        'u3-l3',
        'u3-l4',
        'u3-l5',
      ]) {
        final first = course.lessonById(id)!.exercises.first;
        expect(first, isA<QuestionExercise>(), reason: id);
        expect(first.explanation.toLowerCase(), contains('rule'), reason: id);
      }
    });

    test('checkpoints take two questions from each of the unit\'s lessons', () {
      for (final unit in course.units) {
        final checkpoint = unit.lessons.last;
        expect(
          checkpoint.exercises.every((e) => e is QuestionExercise),
          isTrue,
        );
        final sources = [
          for (final e in checkpoint.exercises)
            course.sourceLessonOf(e.id)!.number,
        ];
        expect(sources, [1, 1, 2, 2, 3, 3, 4, 4, 5, 5], reason: unit.title);
        expect(
          [for (final e in checkpoint.exercises) e.id],
          [
            for (final n in [1, 2, 3, 4, 5])
              for (final k in [1, 2]) '${checkpoint.id}-l$n-e$k',
          ],
        );
      }
    });
  });

  group('questions', () {
    final questions = [
      for (final l in course.lessons)
        for (final q in l.exercises.whereType<QuestionExercise>()) (l, q),
    ];

    test('four distinct options and exactly one marked correct', () {
      for (final (l, q) in questions) {
        expect(q.options, hasLength(4), reason: q.id);
        expect(
          q.options.map(_norm).toSet(),
          hasLength(4),
          reason: '${q.id}: duplicate options',
        );
        expect(q.correctIndex, inInclusiveRange(0, 3), reason: q.id);
        expect(l.exercises, contains(q));
      }
    });

    test('fill-in-the-blank sentences have exactly one gap', () {
      for (final (_, q) in questions) {
        if (q is FillBlankExercise) {
          expect(
            FillBlankExercise.blank.allMatches(q.sentence),
            hasLength(1),
            reason: q.id,
          );
        }
      }
    });

    test(
      'every explanation is substantial and never cites an option letter',
      () {
        final letter = RegExp(r'\b(option|answer|choice)s? [A-D]\b');
        for (final l in course.lessons) {
          for (final e in l.exercises) {
            expect(e.explanation.length, greaterThan(40), reason: e.id);
            expect(letter.hasMatch(e.explanation), isFalse, reason: e.id);
            // Options are shuffled in reviews, so no positional wording.
            expect(
              RegExp(
                r'\b(first|second|third|fourth|last) '
                r'(option|version|sentence|plan|one|two)',
              ).hasMatch(e.explanation),
              isFalse,
              reason: e.id,
            );
          }
        }
      },
    );

    test(
      'no question is repeated, and answers are spread across positions',
      () {
        // The same generic prompt ("Which sentence is correct?") may be
        // reused, but never with the same sentence or the same options.
        final seen = <String>{};
        for (final (_, q) in questions) {
          final key = _norm(
            '${q.savedPrompt}|${(q.options.toList()..sort()).join('|')}',
          );
          expect(seen.add(key), isTrue, reason: q.id);
        }
        // The new lessons only: the Lesson 1s predate this check.
        final positions = List.filled(4, 0);
        for (final (l, q) in questions) {
          if (!l.id.endsWith('-l1')) positions[q.correctIndex]++;
        }
        final total = positions.fold<int>(0, (a, b) => a + b);
        for (final (i, n) in positions.indexed) {
          expect(n / total, lessThan(0.35), reason: 'position $i: $positions');
          expect(
            n / total,
            greaterThan(0.15),
            reason: 'position $i: $positions',
          );
        }
      },
    );

    test('a wrong option never equals the correct one', () {
      for (final (_, q) in questions) {
        final correct = _norm(q.correctAnswer);
        final others = [
          for (final (i, o) in q.options.indexed)
            if (i != q.correctIndex) _norm(o),
        ];
        expect(others, isNot(contains(correct)), reason: q.id);
      }
    });
  });

  group('flashcards', () {
    final cards = [
      for (final l in course.lessons)
        ...l.exercises.whereType<FlashcardExercise>(),
    ];

    test('words are unique across the whole course', () {
      final words = [for (final c in cards) _norm(c.word)];
      expect(words.toSet(), hasLength(words.length));
    });

    test('each word is a single plain word, used in its example', () {
      for (final c in cards) {
        expect(c.word, matches(RegExp(r'^[a-z]+$')), reason: c.id);
        // The Lesson 1 cards predate this check ("clause" is explained
        // by its example, not used in it).
        if (c.id.contains('-l1-')) continue;
        final stem = c.word.substring(0, c.word.length - 2);
        expect(
          _norm(c.example),
          contains(stem),
          reason: '${c.id}: example should use "${c.word}"',
        );
        expect(c.meaning.trim(), isNotEmpty);
      }
    });
  });

  group('wording', () {
    test('no band text anywhere in the course', () {
      final band = RegExp(r'\bbands?\b', caseSensitive: false);
      final decimal = RegExp(r'\b\d\.\d\b');
      for (final t in _allTexts) {
        expect(band.hasMatch(t), isFalse, reason: t);
        expect(decimal.hasMatch(t), isFalse, reason: t);
      }
    });

    test('British spelling', () {
      // American spellings that would slip in. "program" is only right for
      // computer programs, which this course never mentions.
      final american = RegExp(
        r'\b(colors?|colored|organi[z]e[sd]?|organi[z]ing|organi[z]ation|'
        r'analy[z]e[sd]?|analy[z]ing|centers?|centered|behaviors?|'
        r'behavioral|programs?|favors?|favorite|honors?|neighbors?|labor|'
        r'realize[sd]?|recogni[z]e[sd]?|summari[z]e[sd]?|emphasi[z]e[sd]?|'
        r'defense|license|catalog|gray|theater|meter|fiber|aging)\b',
        caseSensitive: false,
      );
      for (final t in _allTexts) {
        expect(american.hasMatch(t), isFalse, reason: t);
      }
    });

    test('no doubled spaces or stray markup in learner-facing text', () {
      for (final t in _allTexts) {
        expect(t, isNot(contains('  ')), reason: t);
        expect(t, isNot(contains('<')), reason: t);
        expect(t, equals(t.trim()), reason: t);
      }
    });

    test('the course makes no claim of AI or official scoring', () {
      final risky = RegExp(r'\b(AI|official|IELTS)\b');
      for (final t in _allTexts) {
        expect(risky.hasMatch(t), isFalse, reason: t);
      }
    });
  });
}
