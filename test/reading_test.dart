import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/utils/clock.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/home/presentation/home_screen.dart';
import 'package:bandwise/features/lesson/presentation/widgets/exercise_views.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/practice/presentation/practice_screen.dart';
import 'package:bandwise/features/practice/presentation/skill_coming_soon_screen.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/reading/data/reading_content.dart';
import 'package:bandwise/features/reading/domain/reading.dart';
import 'package:bandwise/features/reading/presentation/reading_hub_screen.dart';
import 'package:bandwise/features/reading/presentation/reading_session_screen.dart';
import 'package:bandwise/features/reading/presentation/widgets/passage_view.dart';
import 'package:bandwise/features/reading/presentation/widgets/results_pane.dart';
import 'package:bandwise/features/review/domain/review_planner.dart';
import 'package:bandwise/features/review/presentation/review_screen.dart';
import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 15);

const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  placementSkipped: true,
);

ReadingPassage _passage(String id) =>
    readingPassages.firstWhere((p) => p.id == id);

final _heat = _passage('uhi');
final _time = _passage('time');

/// The fake time the session reads. Tests move it forward.
late DateTime _now;

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

ProviderScope _scope(Widget child) => ProviderScope(
  overrides: [
    todayProvider.overrideWithValue(_today),
    clockProvider.overrideWithValue(() => _now),
  ],
  child: child,
);

Future<void> _launchApp(
  WidgetTester tester, {
  Size size = const Size(390, 1000),
}) async {
  _now = DateTime(2026, 10, 15, 9);
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(_onboarding.toJson()),
  });
  _setSize(tester, size);
  await tester.pumpWidget(_scope(const BandwiseApp()));
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String location) async {
  ProviderScope.containerOf(
    tester.element(find.byType(BandwiseApp)),
  ).read(routerProvider).push(location);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapTab(WidgetTester tester, String label) => _tap(
  tester,
  find.descendant(of: find.byType(AppBottomNav), matching: find.text(label)),
);

Future<ProgressState> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return ProgressState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

Finder _questionCard(ReadingQuestion q) =>
    find.byKey(ValueKey('question-${q.id}'));

Future<void> _showQuestions(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('pane-questions'));
  if (toggle.evaluate().isNotEmpty) await _tap(tester, toggle);
}

Future<void> _showPassage(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('pane-passage'));
  if (toggle.evaluate().isNotEmpty) await _tap(tester, toggle);
}

/// Answers [q] in the questions pane, right or wrong.
Future<void> _answer(
  WidgetTester tester,
  ReadingQuestion q, {
  required bool correct,
}) async {
  final card = _questionCard(q);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  switch (q) {
    case HeadingQuestion():
      final i = correct ? q.correctIndex : (q.correctIndex + 1) % 8;
      await _tap(
        tester,
        find.descendant(
          of: card,
          matching: find.text(HeadingQuestion.numeral(i)),
        ),
      );
    case ChoiceReadingQuestion():
      final i = correct
          ? q.correctIndex
          : (q.correctIndex + 1) % q.options.length;
      await _tap(
        tester,
        find.descendant(
          of: card,
          matching: find.widgetWithText(SelectionCard, q.options[i]),
        ),
      );
    case CompletionQuestion():
      final field = find.descendant(of: card, matching: find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.enterText(field, correct ? q.answer : 'wrong');
      await tester.pumpAndSettle();
  }
}

Future<void> _submit(WidgetTester tester, {String label = 'Submit'}) async {
  await _tap(tester, find.widgetWithText(AppButton, label));
  await _tap(tester, find.widgetWithText(TextButton, 'Submit'));
}

/// Every piece of text on screen.
List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
  for (final t in tester.widgetList<EditableText>(find.byType(EditableText)))
    t.controller.text,
];

final _band = RegExp(r'\bband\b', caseSensitive: false);
final _decimal = RegExp(r'\d\.\d');

void _expectNoBands(WidgetTester tester) {
  final offending = _allText(
    tester,
  ).where((t) => _band.hasMatch(t) || _decimal.hasMatch(t));
  expect(offending, isEmpty);
}

void _background(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// A [Semantics] widget whose own label matches [pattern].
Finder _labelled(Pattern pattern) => find.byWidgetPredicate((w) {
  final label = w is Semantics ? w.properties.label : null;
  return label != null && pattern.allMatches(label).isNotEmpty;
});

/// The navigator button's full semantics label.
Finder _navigatorLabel(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

/// The evidence sentence's rectangle on screen.
Rect _sentenceOnScreen(WidgetTester tester, int paragraph, int sentence) {
  final para = find.byWidgetPredicate(
    (w) => w is PassageParagraph && w.index == paragraph,
  );
  final editable = findRenderEditable(tester.renderObject(para))!;
  final rect = sentenceRect(
    editable,
    _time.paragraphs[paragraph].rangeOf(sentence),
  );
  return MatrixUtils.transformRect(editable.getTransformTo(null), rect);
}

void main() {
  group('grading', () {
    TfngQuestion tfng(Tfng answer) => TfngQuestion(
      id: 't',
      statement: 's',
      answer: answer,
      explanation: 'e',
      evidence: const EvidenceSpan(0, 0),
    );

    test('True / False / Not Given: only the exact answer counts', () {
      for (final answer in Tfng.values) {
        final q = tfng(answer);
        for (final pick in Tfng.values) {
          expect(
            q.isCorrect(ChoiceResponse(pick.index)),
            pick == answer,
            reason: '${answer.label} vs ${pick.label}',
          );
        }
        expect(q.isCorrect(null), isFalse);
        expect(q.isAnswered(null), isFalse);
      }
      expect(TfngQuestion.labels, ['True', 'False', 'Not Given']);
    });

    test('multiple choice and matching headings', () {
      final mc = _heat.questions.whereType<ReadingMultipleChoiceQuestion>();
      for (final q in mc) {
        expect(q.isCorrect(ChoiceResponse(q.correctIndex)), isTrue);
        expect(q.isCorrect(ChoiceResponse((q.correctIndex + 1) % 4)), isFalse);
        expect(q.isCorrect(const TextResponse('anything')), isFalse);
      }
      final h = _heat.questions.whereType<HeadingQuestion>().first;
      expect(h.isCorrect(ChoiceResponse(h.correctIndex)), isTrue);
      expect(h.isCorrect(const ChoiceResponse(7)), isFalse);
      expect(h.describe(ChoiceResponse(h.correctIndex)), h.correctAnswer);
    });

    test('completion: case and spaces ignored, spelling exact, variants', () {
      final canyons =
          _heat.questionById('uhi-q10')! as CompletionQuestion; // urban canyons
      bool ok(String s) => canyons.isCorrect(TextResponse(s));
      expect(ok('urban canyons'), isTrue);
      expect(ok('  Urban   CANYONS '), isTrue);
      expect(ok('canyons'), isTrue, reason: 'accepted variant');
      expect(ok('urban canyon'), isFalse, reason: 'spelling must be exact');
      expect(ok('urban kanyons'), isFalse);
      expect(ok('urban-canyons'), isFalse);
      expect(ok(''), isFalse);
      expect(canyons.isAnswered(const TextResponse('   ')), isFalse);
    });

    test('completion: more than the word limit is wrong', () {
      final albedo = _heat.questionById('uhi-q9')! as CompletionQuestion;
      final london = _time.questionById('time-q10')! as CompletionQuestion;
      expect(albedo.wordLimitLabel, 'NO MORE THAN TWO WORDS');
      expect(albedo.isCorrect(const TextResponse('albedo')), isTrue);
      expect(albedo.isCorrect(const TextResponse('low albedo')), isFalse);
      expect(albedo.isCorrect(const TextResponse('a low albedo')), isFalse);
      expect(london.isCorrect(const TextResponse('London time')), isTrue);
      expect(london.isCorrect(const TextResponse('the London time')), isFalse);
      expect(CompletionQuestion.wordCount(' London   time '), 2);
    });

    test('grade totals and accuracy by type', () {
      final responses = <String, ReadingResponse>{
        for (final q in _heat.questions.whereType<TfngQuestion>())
          q.id: ChoiceResponse(q.correctIndex),
        'uhi-q9': const TextResponse('Albedo'),
        'uhi-q4': const ChoiceResponse(0),
      };
      final grade = ReadingGrade(_heat.questions, responses);
      expect(grade.correct, 4);
      expect(grade.total, 10);
      expect(grade.byType[ReadingQuestionType.trueFalseNotGiven]!.correct, 3);
      expect(grade.byType[ReadingQuestionType.multipleChoice]!.correct, 0);
      expect(grade.byType[ReadingQuestionType.sentenceCompletion]!.correct, 1);
      expect(grade.byType[ReadingQuestionType.matchingHeadings]!.total, 3);
      expect(grade.wrong, hasLength(6));
    });
  });

  group('content', () {
    test('two passages of 650–800 words with 10 questions each', () {
      expect(readingPassages, hasLength(2));
      for (final p in readingPassages) {
        expect(p.wordCount, inInclusiveRange(650, 800), reason: p.id);
        expect(p.paragraphs, hasLength(6), reason: 'paragraphs A–F');
        expect(p.questions, hasLength(10));
        expect(p.types, ReadingQuestionType.values, reason: 'mixed types');
      }
    });

    test('ids are unique; evidence points at a real sentence', () {
      final ids = [
        for (final p in readingPassages)
          for (final q in p.questions) q.id,
        for (final l in course.lessons)
          for (final e in l.exercises) e.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
      for (final p in readingPassages) {
        for (final q in p.questions) {
          final e = q.evidence;
          expect(e.paragraph, lessThan(p.paragraphs.length), reason: q.id);
          expect(
            e.sentence,
            lessThan(p.paragraphs[e.paragraph].sentences.length),
            reason: q.id,
          );
          expect(q.explanation, isNotEmpty);
          if (q is HeadingQuestion) {
            expect(e.paragraph, q.paragraph, reason: q.id);
          }
        }
      }
    });

    test('completion answers are words from their evidence sentence', () {
      for (final p in readingPassages) {
        for (final q in p.questions.whereType<CompletionQuestion>()) {
          final sentence =
              p.paragraphs[q.evidence.paragraph].sentences[q.evidence.sentence];
          for (final a in [q.answer, ...q.variants]) {
            expect(CompletionQuestion.wordCount(a), lessThanOrEqualTo(2));
            expect(sentence.toLowerCase(), contains(a.toLowerCase()));
          }
          expect(q.sentence.split(CompletionQuestion.blank), hasLength(2));
        }
      }
    });

    test('True / False / Not Given uses all three answers; Not Given '
        'topics are absent from the passage', () {
      // The idea each Not Given statement asks about, which the passage
      // must not mention at all.
      const absent = {
        'uhi-q3': ['cost', 'expensive', 'price of'],
        'time-q3': ['largest', 'biggest', 'size'],
        'time-q4': ['award', 'prize', 'honour'],
      };
      for (final p in readingPassages) {
        final tfng = p.questions.whereType<TfngQuestion>();
        expect(tfng.map((q) => q.answer).toSet(), Tfng.values.toSet());
        final text = p.paragraphs.map((x) => x.text).join(' ').toLowerCase();
        for (final q in tfng.where((q) => q.answer == Tfng.notGiven)) {
          expect(absent.keys, contains(q.id));
          for (final word in absent[q.id]!) {
            expect(text, isNot(contains(word)), reason: '${q.id}: $word');
          }
        }
      }
    });

    test('time-q4 reminds learners to answer only from the passage', () {
      expect(
        _time.questionById('time-q4')!.explanation,
        endsWith(
          'Even if you know this from elsewhere, answer only from the '
          'passage.',
        ),
      );
    });

    test('no band text in reading content', () {
      for (final p in readingPassages) {
        final all = [
          p.title,
          p.topic,
          for (final para in p.paragraphs) para.text,
          for (final q in p.questions) ...[
            q.prompt,
            q.explanation,
            q.correctAnswer,
            if (q is ChoiceReadingQuestion) ...q.options,
          ],
        ];
        for (final t in all) {
          expect(_band.hasMatch(t), isFalse, reason: t);
          expect(_decimal.hasMatch(t), isFalse, reason: t);
        }
      }
    });
  });

  group('progress', () {
    ReadingCompletion completion({
      required int correct,
      bool timed = true,
      List<String> wrong = const [],
      DateTime? date,
    }) {
      final day = date ?? _today;
      return ReadingCompletion(
        attempt: ReadingAttempt(
          passageId: 'uhi',
          timed: timed,
          date: day,
          correct: correct,
          total: 10,
          minutes: 18,
          xp: XpRules.forReading(correct: correct, timedPassage: timed),
        ),
        questionIds: [for (final q in _heat.questions) q.id],
        mistakes: [
          for (final id in wrong)
            SavedMistake(
              source: MistakeSource.reading,
              sourceId: 'uhi',
              itemId: id,
              prompt: _heat.questionById(id)!.prompt,
              yourAnswer: 'x',
              correctAnswer: _heat.questionById(id)!.correctAnswer,
              explanation: 'e',
              savedOn: day,
            ),
        ],
      );
    }

    test('XP: 2 per correct, plus 10 for a timed passage', () {
      expect(XpRules.forReading(correct: 7, timedPassage: true), 24);
      expect(XpRules.forReading(correct: 7, timedPassage: false), 14);
      final p = const ProgressState().withReadingAttempt(
        completion(correct: 7, wrong: ['uhi-q1', 'uhi-q9', 'uhi-q10']),
      );
      expect(p.totalXp, 24);
      expect(p.minutesOn(_today), 18);
      expect(p.streak(_today), 1);
    });

    test('wrong answers reach the review queue by id', () {
      final p = const ProgressState().withReadingAttempt(
        completion(correct: 8, wrong: ['uhi-q2', 'uhi-q9']),
      );
      final due = ReviewPlanner(
        course: course,
        progress: p,
        passages: readingPassages,
      ).dueOn(_today);
      expect(due.map((i) => i.key), ['mistake:uhi-q2', 'mistake:uhi-q9']);
      expect(due.first, isA<ReadingMistakeReviewItem>());
      // Lessons don't change.
      expect(p.mistakesFor('uhi'), isEmpty);
    });

    test('a new attempt replaces the mistakes of the questions practised', () {
      final first = const ProgressState().withReadingAttempt(
        completion(correct: 8, wrong: ['uhi-q2', 'uhi-q9']),
      );
      final second = first.withReadingAttempt(
        completion(correct: 9, wrong: ['uhi-q9'], date: DateTime(2026, 10, 16)),
      );
      expect(second.mistakes.map((m) => m.itemId), ['uhi-q9']);
      expect(second.readingAttempts, hasLength(2));
      final restored = ProgressState.fromJson(
        jsonDecode(jsonEncode(second.toJson())) as Map<String, dynamic>,
      );
      expect(restored.readingAttempts.last.correct, 9);
      expect(restored.mistakes.single.savedOn, DateTime(2026, 10, 16));
    });
  });

  group('practice tab', () {
    testWidgets(
      'four skill cards; Listening, Reading and Writing open their hubs, '
      'Speaking is coming soon',
      (tester) async {
        await _launchApp(tester);
        await _tapTab(tester, 'Practice');
        expect(find.byType(PracticeSkillCard), findsNWidgets(4));
        expect(find.text('Coming soon'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('practice-speaking')),
            matching: find.text('Coming soon'),
          ),
          findsOneWidget,
        );

        await _tap(tester, find.byKey(const ValueKey('practice-speaking')));
        expect(find.byType(SkillComingSoonScreen), findsOneWidget);
        expect(find.text('Speaking practice is coming soon'), findsOneWidget);
        await _tap(tester, find.byTooltip('Go back'));

        await _tap(tester, find.byKey(const ValueKey('practice-reading')));
        expect(find.byType(ReadingHubScreen), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Recent attempts'),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomNav), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('No attempts yet. Your scores will appear here.'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
      },
    );

    testWidgets('a type filter limits learning practice to that type', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/practice/reading');
      await tester.scrollUntilVisible(
        find.text('True / False / Not Given'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await _tap(tester, find.text('True / False / Not Given'));
      await _tap(tester, find.widgetWithText(AppButton, 'Start practice'));
      expect(find.byType(ReadingSessionScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      await _showQuestions(tester);
      expect(find.text('Questions 1–3'), findsOneWidget);
      expect(_navigatorLabel('Questions: 0 of 3 answered'), findsOneWidget);
    });
  });

  group('session', () {
    testWidgets('learning mode: Check shows the explanation and the '
        'evidence', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=learning');
      expect(find.byKey(const ValueKey('timer')), findsNothing);
      await _showQuestions(tester);
      final q = _heat.questions[1]; // False
      await _answer(tester, q, correct: true);
      await _tap(
        tester,
        find.descendant(
          of: _questionCard(q),
          matching: find.widgetWithText(AppButton, 'Check'),
        ),
      );
      expect(find.text(q.explanation), findsOneWidget);
      await _tap(
        tester,
        find.descendant(
          of: _questionCard(q),
          matching: find.text('Show in passage'),
        ),
      );
      final para = tester.widget<PassageParagraph>(
        find.byWidgetPredicate((w) => w is PassageParagraph && w.index == 1),
      );
      expect(para.evidenceSentence, 4);
    });

    testWidgets('study minutes count from when the session opened', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=learning');
      _now = _now.add(const Duration(minutes: 12, seconds: 10));
      await _submit(tester, label: 'Finish');
      final saved = await _savedProgress();
      expect(saved.readingAttempts.single.minutes, 13);
      expect(saved.readingAttempts.single.timed, isFalse);
      expect(saved.minutesOn(_today), 13);
    });

    testWidgets('navigator button: short count on phones, full label for '
        'screen readers', (tester) async {
      await _launchApp(tester, size: const Size(320, 640));
      await _go(tester, '/reading/uhi?mode=timed');
      await _showQuestions(tester);
      for (final q in _heat.questions.take(6)) {
        await _answer(tester, q, correct: true);
      }
      final button = find.byKey(const ValueKey('navigatorButton'));
      final label = find.descendant(of: button, matching: find.text('6/10'));
      expect(label, findsOneWidget);
      expect(find.textContaining('answered'), findsNothing);
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
      );
      expect(_navigatorLabel('Questions: 6 of 10 answered'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('matching headings: chosen heading text and the headings '
        'sheet', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=learning');
      await _showQuestions(tester);
      final q = _heat.questionById('uhi-q6')! as HeadingQuestion;
      final chosen = find.byKey(ValueKey('chosen-${q.id}'));
      await tester.ensureVisible(chosen);
      expect(tester.widget<Text>(chosen).data, 'No heading chosen yet');

      await _tap(
        tester,
        find.descendant(of: _questionCard(q), matching: find.text('iv')),
      );
      expect(tester.widget<Text>(chosen).data, 'iv. ${q.options[3]}');

      await _tap(
        tester,
        find.descendant(
          of: _questionCard(q),
          matching: find.text('View headings'),
        ),
      );
      expect(find.text('Choose the heading for Paragraph B.'), findsOneWidget);
      for (var i = 0; i < q.options.length; i++) {
        expect(find.byKey(ValueKey('sheet-heading-$i')), findsOneWidget);
      }
      await _tap(tester, find.byKey(const ValueKey('sheet-heading-1')));
      expect(find.byKey(const ValueKey('sheet-heading-1')), findsNothing);
      expect(tester.widget<Text>(chosen).data, 'ii. ${q.options[1]}');
      expect(q.correctIndex, 1);
    });

    testWidgets('Not Given feedback says the information is not in the '
        'passage', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=learning');
      await _showQuestions(tester);
      Future<void> check(ReadingQuestion q) async {
        await _answer(tester, q, correct: true);
        await _tap(
          tester,
          find.descendant(
            of: _questionCard(q),
            matching: find.widgetWithText(AppButton, 'Check'),
          ),
        );
      }

      final notGiven = _heat.questionById('uhi-q3')!;
      final trueQ = _heat.questionById('uhi-q1')!;
      expect(notGiven.isNotGiven, isTrue);
      expect(trueQ.isNotGiven, isFalse);
      await check(notGiven);
      await check(trueQ);
      Finder inCard(ReadingQuestion q, String text) =>
          find.descendant(of: _questionCard(q), matching: find.text(text));
      expect(inCard(notGiven, 'Show related part'), findsOneWidget);
      expect(inCard(notGiven, 'Show in passage'), findsNothing);
      expect(
        inCard(notGiven, "This information isn't in the passage."),
        findsOneWidget,
      );
      expect(inCard(trueQ, 'Show in passage'), findsOneWidget);
      expect(
        inCard(trueQ, "This information isn't in the passage."),
        findsNothing,
      );

      // The related part is still shown.
      await _tap(tester, inCard(notGiven, 'Show related part'));
      final para = tester.widget<PassageParagraph>(
        find.byWidgetPredicate((w) => w is PassageParagraph && w.index == 5),
      );
      expect(para.evidenceSentence, notGiven.evidence.sentence);
    });

    testWidgets('learning results show the elapsed time', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=learning');
      _now = _now.add(const Duration(minutes: 24, seconds: 5));
      await _submit(tester, label: 'Finish');
      expect(_labelled('Time: 24:05 elapsed'), findsOneWidget);
      expect(find.textContaining('Accuracy:'), findsNothing);
    });

    testWidgets('timed mode shows no feedback before submit', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/time?mode=timed');
      expect(find.text('20:00'), findsOneWidget);
      await _showQuestions(tester);
      for (final q in _time.questions) {
        await _answer(tester, q, correct: q.id != 'time-q2');
        expect(find.widgetWithText(AppButton, 'Check'), findsNothing);
        expect(find.text('Correct'), findsNothing);
        expect(find.text('Not quite'), findsNothing);
        expect(find.text('Show in passage'), findsNothing);
        expect(find.text(q.explanation), findsNothing);
      }
      expect(find.widgetWithText(AppButton, '10/10'), findsOneWidget);
      await _submit(tester);
      expect(find.text('Your results'), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      // 9 correct × 2 + 10 for the timed passage.
      expect(find.text('+28'), findsOneWidget);
      expect(_labelled('Time: 00:00 of 20:00'), findsOneWidget);
      // Results: Not Given questions link to the related part.
      for (final q in _time.questions) {
        final card = find.byKey(ValueKey('result-${q.id}'));
        expect(
          find.descendant(
            of: card,
            matching: find.text(
              q.isNotGiven ? 'Show related part' : 'Show in passage',
            ),
          ),
          findsOneWidget,
          reason: q.id,
        );
        expect(
          find.descendant(
            of: card,
            matching: find.text("This information isn't in the passage."),
          ),
          q.isNotGiven ? findsOneWidget : findsNothing,
        );
      }
      // The one wrong answer is saved for review.
      expect((await _savedProgress()).mistakes.map((m) => m.itemId), [
        'time-q2',
      ]);
      _expectNoBands(tester);
    });

    testWidgets('submit asks first and lists unanswered questions', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=timed');
      await _showQuestions(tester);
      await _answer(tester, _heat.questions[0], correct: true);
      await _answer(tester, _heat.questions[3], correct: true);
      await _tap(tester, find.widgetWithText(AppButton, 'Submit'));
      expect(find.text('Submit your answers?'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('unanswered'))).data,
        startsWith('Unanswered: 2, 3, 5, 6, 7, 8, 9, 10.'),
      );
      await _tap(tester, find.text('Keep working'));
      expect(find.text('Your results'), findsNothing);
    });

    testWidgets('leaving mid-session asks first and saves nothing', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=timed');
      await _tap(tester, find.byTooltip('Close practice'));
      expect(find.text('Leave practice?'), findsOneWidget);
      await _tap(tester, find.text('Keep practising'));
      expect(find.byType(ReadingSessionScreen), findsOneWidget);
      await _tap(tester, find.byTooltip('Close practice'));
      await _tap(tester, find.text('Leave'));
      expect(find.byType(ReadingSessionScreen), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString('progress.v1'),
        isNull,
      );
    });

    testWidgets('timer: warning at 5:00, auto-submit at 0:00', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=timed');
      await _showQuestions(tester);
      await _answer(tester, _heat.questions[0], correct: true);

      _now = _now.add(const Duration(minutes: 14, seconds: 59));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('05:01'), findsOneWidget);
      expect(find.textContaining('About 5 minutes left'), findsNothing);

      _now = _now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('05:00'), findsOneWidget);
      expect(find.textContaining('About 5 minutes left'), findsOneWidget);

      _now = _now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text("Time's up"), findsOneWidget);
      expect(find.text('Your results'), findsOneWidget);
      expect(find.text('1/10'), findsOneWidget);
      // Auto-submitted at the limit: all 20 minutes used.
      expect(_labelled('Time: 20:00 of 20:00'), findsOneWidget);
      final saved = await _savedProgress();
      expect(saved.readingAttempts.single.correct, 1);
      expect(saved.readingAttempts.single.timed, isTrue);
      // Nine unanswered questions are scored wrong but not reviewed.
      expect(saved.mistakes, isEmpty);
    });

    testWidgets('timer stays right after background and resume', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=timed');
      expect(find.text('20:00'), findsOneWidget);

      // The app is in the background for 7 minutes: no timer ticks.
      _background(tester);
      _now = _now.add(const Duration(minutes: 7));
      _resume(tester);
      await tester.pump();
      expect(find.text('13:00'), findsOneWidget);

      // Back after the time ran out: submitted on resume.
      _background(tester);
      _now = _now.add(const Duration(minutes: 30));
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text("Time's up"), findsOneWidget);
      expect(find.byKey(const ValueKey('timer')), findsNothing);
    });

    testWidgets('navigator shows answered and flagged; tapping jumps', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=timed');
      await _showQuestions(tester);
      await _answer(tester, _heat.questions[0], correct: true);
      await _tap(tester, find.byTooltip('Flag question 2'));
      expect(find.byTooltip('Remove flag from question 2'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('navigatorButton')));
      expect(find.text('1 of 10 answered'), findsOneWidget);
      Finder tile(String label) => _labelled(label);
      expect(tile('Question 1, answered'), findsOneWidget);
      expect(tile('Question 2, not answered, flagged'), findsOneWidget);
      expect(tile('Question 9, not answered'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('nav-9')));
      expect(find.text('1 of 10 answered'), findsNothing);
      final card = tester.getRect(_questionCard(_heat.questions[8]));
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.top, lessThan(1000));
    });

    testWidgets('long-press highlight, then clear all', (tester) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=learning');
      final para = find.byWidgetPredicate(
        (w) => w is PassageParagraph && w.index == 0,
      );
      await tester.longPress(
        find.descendant(of: para, matching: find.byType(EditableText)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Highlight'));
      await tester.pumpAndSettle();
      expect(tester.widget<PassageParagraph>(para).highlights, isNotEmpty);
      await _tap(tester, find.text('Clear highlights'));
      expect(tester.widget<PassageParagraph>(para).highlights, isEmpty);
      expect(find.text('Clear highlights'), findsNothing);
    });
  });

  group('results', () {
    testWidgets('"Show in passage" scrolls to and marks the evidence '
        'sentence', (tester) async {
      await _launchApp(tester, size: const Size(390, 700));
      await _go(tester, '/reading/time?mode=timed');
      _now = _now.add(const Duration(minutes: 14, seconds: 32));
      await tester.pump(const Duration(seconds: 1));
      await _submit(tester);
      expect(find.byType(ResultsPane), findsOneWidget);
      expect(_labelled('Time: 14:32 of 20:00'), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);

      // Question 10: paragraph E, sentence 4.
      final q = _time.questions.last;
      final button = find.descendant(
        of: find.byKey(ValueKey('result-${q.id}')),
        matching: find.text('Show in passage'),
      );
      await _tap(tester, button);

      final para = tester.widget<PassageParagraph>(
        find.byWidgetPredicate((w) => w is PassageParagraph && w.index == 4),
      );
      expect(para.evidenceSentence, q.evidence.sentence);
      final others = tester.widgetList<PassageParagraph>(
        find.byWidgetPredicate(
          (w) => w is PassageParagraph && w.evidenceSentence != null,
        ),
      );
      expect(others, hasLength(1));

      final sentence = _sentenceOnScreen(tester, 4, q.evidence.sentence);
      final viewport = tester.getRect(
        find.byKey(const PageStorageKey('passage')),
      );
      expect(viewport.top, lessThanOrEqualTo(sentence.top));
      expect(viewport.bottom, greaterThanOrEqualTo(sentence.bottom));
    });

    testWidgets('mistakes reach review; Home shows Reading accuracy', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, '/reading/uhi?mode=timed');
      await _showQuestions(tester);
      for (final q in _heat.questions) {
        await _answer(tester, q, correct: q is! CompletionQuestion);
      }
      await _submit(tester);
      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('Accuracy by question type'), findsOneWidget);
      expect(_labelled('Sentence completion: 0 of 2 correct'), findsOneWidget);

      final saved = await _savedProgress();
      expect(saved.mistakes.map((m) => m.itemId), ['uhi-q9', 'uhi-q10']);
      expect(saved.mistakes.first.yourAnswer, 'wrong');

      await _tap(tester, find.widgetWithText(AppButton, 'Back to Reading'));
      expect(find.byType(ReadingHubScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Recent attempts'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(
        _labelled(RegExp(r'Why cities run hot, Timed.*8/10')),
        findsOneWidget,
      );

      await _tapTab(tester, 'Home');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('2 saved mistakes'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('80% accuracy'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('80% accuracy'), findsOneWidget);

      await _go(tester, '/review');
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(
        find.text('Saved mistake · Reading: Why cities run hot'),
        findsOneWidget,
      );
      expect(find.text('PARAGRAPH B'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'albedo');
      await _tap(tester, find.widgetWithText(AppButton, 'Check'));
      expect(find.widgetWithText(FeedbackPanel, 'Correct'), findsOneWidget);
    });
  });

  group('layout', () {
    Future<void> pump(
      WidgetTester tester,
      Widget screen, {
      required Size size,
      required bool rtl,
    }) async {
      _now = DateTime(2026, 10, 15, 9);
      SharedPreferences.setMockInitialValues({
        'onboarding.v1': jsonEncode(_onboarding.toJson()),
      });
      _setSize(tester, size);
      await tester.pumpWidget(
        _scope(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scrollThrough(WidgetTester tester, Finder list) async {
      for (var i = 0; i < 12; i++) {
        _expectNoBands(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(list, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
    }

    Finder list(String key) => find.byKey(PageStorageKey(key));

    const sizes = {
      'phone 320px': Size(320, 640),
      'tablet split': Size(1024, 768),
    };

    for (final MapEntry(key: label, value: size) in sizes.entries) {
      for (final rtl in [false, true]) {
        final dir = rtl ? 'RTL' : 'LTR';
        final tablet = size.width >= splitBreakpoint;

        testWidgets('session and results: no overflow, no bands '
            '($label, $dir)', (tester) async {
          await pump(
            tester,
            const ReadingSessionScreen(
              passageId: 'uhi',
              mode: ReadingMode.learning,
            ),
            size: size,
            rtl: rtl,
          );
          // Phones toggle between panes; tablets show both.
          expect(
            find.byKey(const ValueKey('pane-questions')),
            tablet ? findsNothing : findsOneWidget,
          );
          if (tablet) {
            expect(list('passage'), findsOneWidget);
            expect(list('questions'), findsOneWidget);
          }
          await scrollThrough(tester, list('passage'));

          await _showQuestions(tester);
          for (final q in _heat.questions) {
            await _answer(tester, q, correct: q.id != 'uhi-q3');
            final check = find.descendant(
              of: _questionCard(q),
              matching: find.widgetWithText(AppButton, 'Check'),
            );
            await _tap(tester, check);
            expect(tester.takeException(), isNull);
          }
          await scrollThrough(tester, list('questions'));

          await _tap(tester, find.byKey(const ValueKey('navigatorButton')));
          expect(tester.takeException(), isNull);
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();

          await _submit(tester, label: 'Finish');
          expect(find.text('9/10'), findsOneWidget);
          await scrollThrough(tester, list('results'));
          await _showPassage(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final rtl in [false, true]) {
      testWidgets('Practice tab and hub: no overflow at 320px '
          '(${rtl ? 'RTL' : 'LTR'})', (tester) async {
        await pump(
          tester,
          const PracticeScreen(),
          size: const Size(320, 640),
          rtl: rtl,
        );
        expect(tester.takeException(), isNull);
        await pump(
          tester,
          const ReadingHubScreen(),
          size: const Size(320, 640),
          rtl: rtl,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();
        _expectNoBands(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
