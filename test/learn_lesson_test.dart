import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/home/presentation/home_screen.dart';
import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/learn/domain/course.dart';
import 'package:bandwise/features/learn/domain/learning_path.dart';
import 'package:bandwise/features/learn/presentation/learn_screen.dart';
import 'package:bandwise/features/lesson/presentation/lesson_screen.dart';
import 'package:bandwise/features/lesson/presentation/widgets/exercise_views.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 15);

/// Finished onboarding; an intermediate self-assessment recommends Unit 2.
OnboardingState _onboarding({EnglishLevel level = EnglishLevel.intermediate}) =>
    OnboardingState(
      step: OnboardingStep.plan,
      completed: true,
      targetBand: TargetBand.band7,
      level: level,
      dailyMinutes: 20,
      placementSkipped: true,
    );

void _savePrefs(OnboardingState onboarding, {ProgressState? progress}) {
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(onboarding.toJson()),
    if (progress != null) 'progress.v1': jsonEncode(progress.toJson()),
  });
}

Future<ProgressState?> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return raw == null
      ? null
      : ProgressState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _launchApp(
  WidgetTester tester, {
  EnglishLevel level = EnglishLevel.intermediate,
  ProgressState? progress,
}) async {
  _savePrefs(_onboarding(level: level), progress: progress);
  _setSize(tester, const Size(390, 1000));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [todayProvider.overrideWithValue(_today)],
      child: const BandwiseApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String location) async {
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

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// A [Semantics] widget whose own label matches [pattern].
Finder _labelled(Pattern pattern) => find.byWidgetPredicate((w) {
  final label = w is Semantics ? w.properties.label : null;
  return label != null && pattern.allMatches(label).isNotEmpty;
});

/// Every piece of text on screen.
List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
];

final _decimal = RegExp(r'\d\.\d');
final _band = RegExp(r'\bband\b', caseSensitive: false);

void _expectNoBands(WidgetTester tester) {
  final offending = _allText(
    tester,
  ).where((t) => _decimal.hasMatch(t) || _band.hasMatch(t));
  expect(offending, isEmpty);
}

Lesson _lesson(String id) => course.lessonById(id)!;

/// Plays [lesson] from its intro to the results screen, answering wrongly
/// at the exercise indexes in [wrongAt]. Runs [onStep] on every screen.
Future<void> _play(
  WidgetTester tester,
  Lesson lesson, {
  Set<int> wrongAt = const {},
  void Function()? onStep,
}) async {
  onStep?.call();
  await _tap(tester, find.widgetWithText(AppButton, 'Start'));
  for (var i = 0; i < lesson.exercises.length; i++) {
    onStep?.call();
    switch (lesson.exercises[i]) {
      case FlashcardExercise():
        await _tap(tester, find.widgetWithText(AppButton, 'Reveal meaning'));
        onStep?.call();
      case final QuestionExercise q:
        final pick = wrongAt.contains(i)
            ? (q.correctIndex + 1) % q.options.length
            : q.correctIndex;
        await _tap(tester, find.widgetWithText(SelectionCard, q.options[pick]));
        await _tap(tester, find.widgetWithText(AppButton, 'Check'));
        onStep?.call();
        expect(
          find.widgetWithText(
            FeedbackPanel,
            wrongAt.contains(i) ? 'Not quite' : 'Correct',
          ),
          findsOneWidget,
        );
    }
    await _tap(tester, find.widgetWithText(AppButton, 'Continue'));
  }
  expect(
    find.text(lesson.isCheckpoint ? 'Checkpoint complete' : 'Lesson complete'),
    findsOneWidget,
  );
  onStep?.call();
}

void main() {
  group('lessons', () {
    for (final unit in course.units) {
      testWidgets('Unit ${unit.number} Lesson 1 is playable end to end', (
        tester,
      ) async {
        // Advanced: Unit 3 is recommended, so Units 1 and 2 stay open too.
        await _launchApp(tester, level: EnglishLevel.advanced);
        final lesson = unit.lessons.first;
        expect(lesson.isPlayable, isTrue);
        expect(lesson.exercises.length, inInclusiveRange(5, 6));

        await _push(tester, '/lesson/${lesson.id}');
        expect(find.text(lesson.title), findsOneWidget);
        expect(find.text('You will learn'), findsOneWidget);
        for (final item in lesson.learnItems) {
          expect(find.text(item), findsOneWidget);
        }

        await _play(tester, lesson);
        final q = lesson.questionCount;
        final score = tester.widget<Semantics>(
          find
              .descendant(
                of: find.byKey(const ValueKey('score')),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(score.properties.label, 'Score: $q/$q correct');
        expect(find.text('+${XpRules.forLesson(q)}'), findsOneWidget);
        expect(find.text('No mistakes this time'), findsOneWidget);

        final saved = (await _savedProgress())!;
        expect(saved.isCompleted(lesson.id), isTrue);
        expect(saved.totalXp, XpRules.forLesson(q));
      });
    }

    for (final lesson in course.lessons) {
      testWidgets('${lesson.id} plays end to end', (tester) async {
        expect(lesson.isPlayable, isTrue);
        // Everything else is done, so nothing is locked.
        var progress = const ProgressState();
        for (final other in course.lessons) {
          if (other.id == lesson.id) continue;
          progress = progress.withCompletedLesson(
            LessonCompletion(
              lessonId: other.id,
              date: _today,
              correctFirstTry: other.questionCount,
              questionCount: other.questionCount,
              minutes: 5,
              mistakes: const [],
            ),
          );
        }
        await _launchApp(
          tester,
          level: EnglishLevel.advanced,
          progress: progress,
        );
        await _push(tester, '/lesson/${lesson.id}');
        expect(find.text(lesson.title), findsOneWidget);
        await _play(tester, lesson);
        final q = lesson.questionCount;
        expect(find.text('+${XpRules.forLesson(q)}'), findsOneWidget);
        expect(find.text('No mistakes this time'), findsOneWidget);
        expect(
          find.text(
            lesson.isCheckpoint ? 'Checkpoint complete' : 'Lesson complete',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('checkpoints', () {
    ProgressState allDoneExceptCheckpoint(int unit) {
      var progress = const ProgressState();
      for (final lesson in course.unit(unit).lessons) {
        if (lesson.isCheckpoint) continue;
        progress = progress.withCompletedLesson(
          LessonCompletion(
            lessonId: lesson.id,
            date: _today,
            correctFirstTry: lesson.questionCount,
            questionCount: lesson.questionCount,
            minutes: 5,
            mistakes: const [],
          ),
        );
      }
      return progress;
    }

    testWidgets('a checkpoint is locked until Lesson 5 is done', (
      tester,
    ) async {
      await _launchApp(tester, level: EnglishLevel.beginner);
      await _push(tester, '/lesson/u1-checkpoint');
      expect(find.text('This lesson is locked'), findsOneWidget);
      expect(find.text('Unlocks after Lesson 5.'), findsOneWidget);
    });

    for (final (wrong, mastered) in [
      (const <int>{}, true),
      // 8/10 is the mastery line.
      (const {0, 9}, true),
      // Mistakes from Lesson 1 (twice) and Lesson 3.
      (const {0, 1, 4}, false),
    ]) {
      testWidgets(
        '${10 - wrong.length}/10 ${mastered ? 'masters' : 'does not master'} '
        'the unit',
        (tester) async {
          await _launchApp(
            tester,
            level: EnglishLevel.advanced,
            progress: allDoneExceptCheckpoint(1),
          );
          final checkpoint = _lesson('u1-checkpoint');
          expect(checkpoint.questionCount, 10);
          await _push(tester, '/lesson/u1-checkpoint');
          await _play(tester, checkpoint, wrongAt: wrong);
          final correct = 10 - wrong.length;

          expect(find.text('Checkpoint complete'), findsOneWidget);
          expect(find.text('+${10 + 2 * correct}'), findsOneWidget);
          _expectNoBands(tester);
          final saved = (await _savedProgress())!;
          expect(saved.results['u1-checkpoint']!.correct, correct);
          expect(saved.mistakesFor('u1-checkpoint'), hasLength(wrong.length));

          if (mastered) {
            expect(find.byKey(const ValueKey('mastered')), findsOneWidget);
            expect(find.text('Review these lessons'), findsNothing);
          } else {
            expect(find.byKey(const ValueKey('mastered')), findsNothing);
            expect(find.text('Review these lessons'), findsOneWidget);
            expect(find.byKey(const ValueKey('review-u1-l1')), findsOneWidget);
            expect(find.byKey(const ValueKey('review-u1-l3')), findsOneWidget);
            expect(find.byKey(const ValueKey('review-u1-l2')), findsNothing);

            // The link opens the lesson.
            await _tap(tester, find.byKey(const ValueKey('review-u1-l3')));
            expect(find.text('Nouns for ideas and evidence'), findsOneWidget);
            expect(find.widgetWithText(AppButton, 'Start'), findsOneWidget);
          }

          final path = LearningPath(
            course: course,
            progress: saved,
            startUnit: 1,
          );
          expect(path.isMastered(course.unit(1)), mastered);
          expect(path.statsFor(course.unit(1)).mastered, mastered);
        },
      );
    }

    testWidgets('Learn and Progress show a mastered unit', (tester) async {
      final progress = allDoneExceptCheckpoint(1).withCompletedLesson(
        LessonCompletion(
          lessonId: 'u1-checkpoint',
          date: _today,
          correctFirstTry: 9,
          questionCount: 10,
          minutes: 8,
          mistakes: [],
        ),
      );
      await _launchApp(
        tester,
        level: EnglishLevel.beginner,
        progress: progress,
      );
      await _tapTab(tester, 'Learn');
      expect(find.byKey(const ValueKey('unitMastered')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('node-u1-checkpoint')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mastered'), findsWidgets);
      _expectNoBands(tester);

      await _tapTab(tester, 'Progress');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('unit-1-mastered')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('unit-1-mastered')), findsOneWidget);
      expect(find.byKey(const ValueKey('unit-2-mastered')), findsNothing);
    });

    test('mastery needs the latest checkpoint result to reach 8', () {
      LessonCompletion result(int correct) => LessonCompletion(
        lessonId: 'u2-checkpoint',
        date: _today,
        correctFirstTry: correct,
        questionCount: 10,
        minutes: 8,
        mistakes: const [],
      );
      LearningPath on(ProgressState p) =>
          LearningPath(course: course, progress: p, startUnit: 2);
      final unit = course.unit(2);
      expect(on(const ProgressState()).isMastered(unit), isFalse);
      expect(
        on(
          const ProgressState().withCompletedLesson(result(7)),
        ).isMastered(unit),
        isFalse,
      );
      expect(
        on(
          const ProgressState().withCompletedLesson(result(8)),
        ).isMastered(unit),
        isTrue,
      );
    });

    test(
      'every checkpoint question maps back to one of its unit\'s lessons',
      () {
        for (final unit in course.units) {
          final checkpoint = unit.lessons.last;
          for (final q in checkpoint.exercises) {
            final source = course.sourceLessonOf(q.id);
            expect(source, isNotNull, reason: q.id);
            expect(source!.unit, unit.number);
            expect(source.isCheckpoint, isFalse);
          }
        }
        expect(course.sourceLessonOf('u1-l2-e1'), isNull);
      },
    );
  });

  group('progress', () {
    testWidgets('completing a lesson updates Home live', (tester) async {
      await _launchApp(tester);
      expect(_labelled(RegExp(r'^Streak: 0 days')), findsOneWidget);

      await _tap(tester, find.widgetWithText(AppButton, 'Start lesson'));
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      final lesson = _lesson('u2-l1');
      await _play(tester, lesson);
      await _tap(tester, find.widgetWithText(AppButton, 'Back to Home'));

      final xp = XpRules.forLesson(lesson.questionCount);
      expect(find.byType(HomeScreen), findsOneWidget);
      await _scrollToTop(tester);
      expect(
        _labelled(RegExp('^Total XP: $xp\\. \\+$xp today')),
        findsOneWidget,
      );
      expect(
        _labelled(RegExp(r'^Streak: 1 day\. Active today')),
        findsOneWidget,
      );
      expect(
        _labelled(RegExp(r'^Daily goal: 1 of 20 minutes')),
        findsOneWidget,
      );
      // The weekly chart replaces the empty week.
      await tester.scrollUntilVisible(
        find.text('Weekly activity'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Your week starts today'), findsNothing);
      expect(find.byKey(const ValueKey('weeklyTotal')), findsOneWidget);
      // Home now points to the next lesson.
      await tester.scrollUntilVisible(
        find.text('Relative clauses'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Relative clauses'), findsOneWidget);
    });

    testWidgets('a wrong answer is saved and Home shows the review card', (
      tester,
    ) async {
      await _launchApp(tester);
      expect(find.text('UP NEXT FOR REVIEW'), findsNothing);

      await _tap(tester, find.widgetWithText(AppButton, 'Start lesson'));
      final lesson = _lesson('u2-l1');
      // Exercise 1 is the first question.
      await _play(tester, lesson, wrongAt: {1});
      final q = lesson.questionCount;
      expect(find.text('+${XpRules.forLesson(q - 1)}'), findsOneWidget);
      expect(find.text('Saved for review'), findsOneWidget);

      final saved = (await _savedProgress())!;
      expect(saved.mistakes, hasLength(1));
      expect(
        saved.mistakes.single.correctAnswer,
        (lesson.exercises[1] as QuestionExercise).correctAnswer,
      );

      await _tap(tester, find.widgetWithText(AppButton, 'Back to Home'));
      expect(find.text('UP NEXT FOR REVIEW'), findsOneWidget);
      expect(find.text('1 saved mistake'), findsOneWidget);

      await _tapTab(tester, 'Learn');
      expect(find.text('Needs review'), findsOneWidget);
    });

    testWidgets('locked lessons cannot open; the next unlocks after '
        'completion', (tester) async {
      await _launchApp(tester);
      await _tapTab(tester, 'Learn');
      expect(
        find.text('Unit 2: Sentence structure for academic English'),
        findsOneWidget,
      );

      // Lesson 2 is locked until Lesson 1 is done.
      final l2 = find.byKey(const ValueKey('node-u2-l2'));
      expect(find.text('Unlocks after Lesson 1'), findsOneWidget);
      await _tap(tester, l2);
      expect(find.byType(LessonScreen), findsNothing);
      expect(find.text('Unlocks after Lesson 1.'), findsOneWidget);

      // Opening it by URL shows the locked state instead of the lesson.
      await _push(tester, '/lesson/u2-l2');
      expect(find.text('This lesson is locked'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Start'), findsNothing);
      await _tap(tester, find.widgetWithText(AppButton, 'Go back'));

      // Complete Lesson 1 from its node.
      await _tap(tester, find.byKey(const ValueKey('node-u2-l1')));
      await _play(tester, _lesson('u2-l1'));

      // Continue goes to Lesson 2, which is open now.
      await _tap(tester, find.widgetWithText(AppButton, 'Continue'));
      expect(find.text('Relative clauses'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Start'), findsOneWidget);
      await _tap(tester, find.byTooltip('Close lesson'));

      expect(find.byType(LearnScreen), findsOneWidget);
      expect(find.text('Unlocks after Lesson 1'), findsNothing);
      expect(
        _labelled(RegExp(r'^Lesson 2: Relative clauses, up next')),
        findsOneWidget,
      );
      expect(find.text('Unlocks after Lesson 2'), findsOneWidget);
    });

    testWidgets('leaving mid-lesson asks first and saves nothing', (
      tester,
    ) async {
      await _launchApp(tester);
      await _tap(tester, find.widgetWithText(AppButton, 'Start lesson'));
      await _tap(tester, find.widgetWithText(AppButton, 'Start'));
      await _tap(tester, find.widgetWithText(AppButton, 'Reveal meaning'));
      await _tap(tester, find.widgetWithText(AppButton, 'Continue'));
      final q = _lesson('u2-l1').exercises[1] as QuestionExercise;
      await _tap(tester, find.widgetWithText(SelectionCard, q.options[0]));
      await _tap(tester, find.widgetWithText(AppButton, 'Check'));

      await _tap(tester, find.byTooltip('Close lesson'));
      expect(find.text('Leave lesson?'), findsOneWidget);
      expect(
        find.text("Your progress in this lesson won't be saved."),
        findsOneWidget,
      );
      await _tap(tester, find.text('Keep learning'));
      expect(find.byType(LessonScreen), findsOneWidget);

      await _tap(tester, find.byTooltip('Close lesson'));
      await _tap(tester, find.text('Leave'));
      expect(find.byType(LessonScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(await _savedProgress(), isNull);
      await _scrollToTop(tester);
      expect(_labelled(RegExp(r'^Streak: 0 days')), findsOneWidget);
    });
  });

  group('layout', () {
    // Unit 2 L1 done with a mistake, so the path shows review, current,
    // locked and checkpoint nodes.
    final seeded = const ProgressState().withCompletedLesson(
      LessonCompletion(
        lessonId: 'u2-l1',
        date: DateTime(2026, 10, 14),
        correctFirstTry: 4,
        questionCount: 5,
        minutes: 9,
        mistakes: const [
          SavedMistake(
            sourceId: 'u2-l1',
            itemId: 'u2-l1-e2',
            prompt: 'Which sentence is punctuated correctly?',
            yourAnswer: 'Prices rose, demand fell.',
            correctAnswer: 'Prices rose; demand fell.',
            explanation: 'A comma alone cannot join two clauses.',
          ),
        ],
      ),
    );

    Future<void> pumpAlone(
      WidgetTester tester,
      Widget screen, {
      required bool rtl,
    }) async {
      _savePrefs(_onboarding(), progress: seeded);
      _setSize(tester, const Size(320, 640));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todayProvider.overrideWithValue(_today)],
          child: MaterialApp(
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

    for (final rtl in [false, true]) {
      final dir = rtl ? 'RTL' : 'LTR';

      testWidgets('Learn: no overflow at 320px, no bands ($dir)', (
        tester,
      ) async {
        await pumpAlone(tester, const LearnScreen(), rtl: rtl);
        expect(find.text('Needs review'), findsOneWidget);
        for (var i = 0; i < 6; i++) {
          _expectNoBands(tester);
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(find.text('Unit 2 checkpoint'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      for (final unit in course.units) {
        final lesson = unit.lessons.first;
        testWidgets('${lesson.id}: no overflow at 320px, no bands ($dir)', (
          tester,
        ) async {
          await pumpAlone(tester, LessonScreen(lessonId: lesson.id), rtl: rtl);
          // Unit 3 is locked for this learner; open Unit 1/2 lessons, and
          // check the locked screen for Unit 3.
          if (unit.number == 3) {
            expect(find.text('This lesson is locked'), findsOneWidget);
            _expectNoBands(tester);
            expect(tester.takeException(), isNull);
            return;
          }
          await _play(
            tester,
            lesson,
            wrongAt: {for (var i = 0; i < 6; i++) i},
            onStep: () => _expectNoBands(tester),
          );
          await tester.drag(find.byType(ListView), const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('rules', () {
    LearningPath path(ProgressState progress, {int startUnit = 2}) =>
        LearningPath(course: course, progress: progress, startUnit: startUnit);

    LessonCompletion done(String id, {int correct = 3}) => LessonCompletion(
      lessonId: id,
      date: _today,
      correctFirstTry: correct,
      questionCount: 4,
      minutes: 5,
      mistakes: const [],
    );

    test('earlier units are open, later units locked, order within unit', () {
      final p = path(const ProgressState());
      expect(p.isUnlocked(_lesson('u1-l4')), isTrue);
      expect(p.isUnlocked(_lesson('u1-checkpoint')), isTrue);
      expect(p.isUnlocked(_lesson('u2-l1')), isTrue);
      expect(p.isUnlocked(_lesson('u2-l2')), isFalse);
      expect(p.isUnlocked(_lesson('u3-l1')), isFalse);
      expect(p.nextLesson!.id, 'u2-l1');
      expect(
        p.nodeFor(_lesson('u3-l1')).lockedReason,
        'Unlocks after the Unit 2 checkpoint',
      );
      expect(
        p.nodeFor(_lesson('u2-checkpoint')).lockedReason,
        'Unlocks after Lesson 5',
      );

      final after = path(
        const ProgressState().withCompletedLesson(done('u2-l1')),
      );
      expect(after.isUnlocked(_lesson('u2-l2')), isTrue);
      expect(after.nextLesson!.id, 'u2-l2');
      expect(after.nodeFor(_lesson('u2-l2')).status, LessonStatus.current);
    });

    test('XP is 10 per lesson plus 2 per first-try correct answer', () {
      final s = const ProgressState()
          .withCompletedLesson(done('u2-l1', correct: 3))
          .withCompletedLesson(done('u1-l1', correct: 4));
      expect(s.totalXp, (10 + 6) + (10 + 8));
      expect(s.xpOn(_today), 34);
    });

    test('minutes are real time rounded up, capped at twice the estimate', () {
      expect(LessonCompletion.minutesFor(const Duration(seconds: 5), 8), 1);
      expect(LessonCompletion.minutesFor(const Duration(seconds: 61), 8), 2);
      expect(LessonCompletion.minutesFor(const Duration(minutes: 30), 8), 16);
    });

    test('a streak day is any day with a completed activity', () {
      ProgressState on(List<int> daysAgo) => ProgressState(
        activeDays: {
          for (final d in daysAgo)
            DateTime(_today.year, _today.month, _today.day - d),
        },
      );
      expect(on([]).streak(_today), 0);
      expect(on([0]).streak(_today), 1);
      // Not studied yet today: yesterday's streak is still alive.
      expect(on([1, 2]).streak(_today), 2);
      expect(on([0, 1, 3]).streak(_today), 2);
    });

    test('progress survives a JSON round trip', () {
      final s = const ProgressState().withCompletedLesson(done('u2-l1'));
      final back = ProgressState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(back.totalXp, s.totalXp);
      expect(back.streak(_today), 1);
      expect(back.minutesOn(_today), 5);
      expect(back.isCompleted('u2-l1'), isTrue);
    });

    test('lesson content has no band numbers', () {
      final texts = [
        for (final unit in course.units) ...[
          unit.title,
          for (final l in unit.lessons) ...[
            l.title,
            l.objective,
            ...l.learnItems,
            for (final e in l.exercises)
              ...switch (e) {
                FlashcardExercise() => [
                  e.word,
                  e.meaning,
                  e.example,
                  e.explanation,
                ],
                MultipleChoiceExercise() => [
                  e.prompt,
                  ?e.passage,
                  ...e.options,
                  e.explanation,
                ],
                FillBlankExercise() => [
                  e.prompt,
                  e.sentence,
                  ...e.options,
                  e.explanation,
                ],
              },
          ],
        ],
      ];
      expect(
        texts.where((t) => _decimal.hasMatch(t) || _band.hasMatch(t)),
        isEmpty,
      );
    });
  });
}
