import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/home/presentation/home_screen.dart';
import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/learn/domain/course.dart';
import 'package:bandwise/features/learn/domain/learning_path.dart';
import 'package:bandwise/features/lesson/presentation/widgets/exercise_views.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/progress/data/prefs_progress_repository.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/progress/domain/review_schedule.dart';
import 'package:bandwise/features/review/domain/option_shuffle.dart';
import 'package:bandwise/features/review/domain/review_planner.dart';
import 'package:bandwise/features/review/presentation/review_providers.dart';
import 'package:bandwise/features/review/presentation/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 15);
DateTime _day(int offset) => DateTime(2026, 10, 15 + offset);

/// Finished onboarding; intermediate, so Unit 2 is the starting point and
/// Unit 1 stays open.
const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  placementSkipped: true,
);

Lesson _lesson(String id) => course.lessonById(id)!;

/// The flashcard "clause" in Unit 2 Lesson 1.
const _clause = 'u2-l1-e1';

QuestionExercise _question(String lessonId, int index) =>
    _lesson(lessonId).exercises[index] as QuestionExercise;

/// The mistake saved when exercise [index] of [lessonId] is answered wrongly.
SavedMistake _mistake(String lessonId, int index) {
  final q = _question(lessonId, index);
  return SavedMistake(
    sourceId: lessonId,
    itemId: q.id,
    prompt: q.savedPrompt,
    yourAnswer: q.options[(q.correctIndex + 1) % q.options.length],
    correctAnswer: q.correctAnswer,
    explanation: q.explanation,
  );
}

LessonCompletion _completion(
  String lessonId,
  DateTime date, {
  List<int> wrongAt = const [],
}) {
  final lesson = _lesson(lessonId);
  return LessonCompletion(
    lessonId: lessonId,
    date: date,
    correctFirstTry: lesson.questionCount - wrongAt.length,
    questionCount: lesson.questionCount,
    minutes: 8,
    mistakes: [for (final i in wrongAt) _mistake(lessonId, i)],
  );
}

/// Unit 2 Lesson 1 done yesterday with a mistake on exercise 1 (a multiple
/// choice question). Due today: that mistake and the word "clause".
final _yesterdayWithMistake = const ProgressState().withCompletedLesson(
  _completion('u2-l1', _day(-1), wrongAt: [1]),
);

ReviewPlanner _planner(ProgressState progress) =>
    ReviewPlanner(course: course, progress: progress);

void _savePrefs({ProgressState? progress}) {
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(_onboarding.toJson()),
    if (progress != null) 'progress.v1': jsonEncode(progress.toJson()),
  });
}

Future<ProgressState> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return ProgressState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

const _seed = 7;

Future<void> _launchApp(WidgetTester tester, {ProgressState? progress}) async {
  _savePrefs(progress: progress);
  _setSize(tester, const Size(390, 1000));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(_today),
        reviewShuffleSeedProvider.overrideWithValue(() => _seed),
      ],
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

Finder _rating(String label) => _labelled(RegExp('^$label, next review'));

/// Answers the question on screen, correctly or not, and checks it.
Future<void> _answer(WidgetTester tester, {required bool correct}) async {
  final q = tester.widget<QuestionView>(find.byType(QuestionView)).exercise;
  final pick = correct
      ? q.correctIndex
      : (q.correctIndex + 1) % q.options.length;
  await _tap(tester, find.widgetWithText(SelectionCard, q.options[pick]));
  await _tap(tester, find.widgetWithText(AppButton, 'Check'));
}

void main() {
  group('scheduling', () {
    ReviewSchedule rate(List<ReviewRating> ratings) {
      ReviewSchedule? s;
      for (final r in ratings) {
        s = ReviewSchedule.next(s, r, _today);
      }
      return s!;
    }

    int days(List<ReviewRating> ratings) => rate(ratings).intervalDays;

    const again = ReviewRating.again;
    const hard = ReviewRating.hard;
    const good = ReviewRating.good;
    const easy = ReviewRating.easy;

    test('first review: Again today, Hard 1, Good 3, Easy 7 days', () {
      expect(rate([again]).dueOn, _today);
      expect(rate([hard]).dueOn, _day(1));
      expect(rate([good]).dueOn, _day(3));
      expect(rate([easy]).dueOn, _day(7));
    });

    test('later Good/Easy double the interval', () {
      expect(days([good, good]), 6);
      expect(days([good, good, good]), 12);
      expect(days([easy, easy]), 14);
      expect(days([easy, good]), 14);
      // Doubling never goes below the rating's base interval.
      expect(days([good, easy]), 7);
    });

    test('Again and Hard reset the doubling', () {
      expect(days([good, good, again, good]), 3);
      expect(days([easy, hard, easy]), 7);
      expect(days([good, hard]), 1);
    });

    test('due dates cross month ends by calendar day', () {
      final s = ReviewSchedule.next(null, easy, DateTime(2026, 10, 28));
      expect(s.dueOn, DateTime(2026, 11, 4));
    });
  });

  group('queue', () {
    test('mistakes are due the day they were made, words the day after', () {
      final today = _planner(
        const ProgressState().withCompletedLesson(
          _completion('u2-l1', _today, wrongAt: [1]),
        ),
      );
      expect(today.dueOn(_today), hasLength(1));
      expect(today.dueOn(_today).single, isA<MistakeReviewItem>());
      expect(today.dueOn(_day(1)), hasLength(2));
      expect(today.nextReviewAfter(_today), _day(1));
    });

    test('most overdue first, then mistakes before words, then path '
        'order', () {
      final progress = const ProgressState()
          .withCompletedLesson(_completion('u2-l1', _day(-3), wrongAt: [2, 1]))
          .withCompletedLesson(_completion('u1-l1', _day(-1), wrongAt: [3]));
      final due = _planner(progress).dueOn(_today);
      String describe(ReviewItem i) => switch (i) {
        MistakeReviewItem(:final lesson, :final exercise) =>
          'mistake ${lesson.id} ${lesson.exercises.indexOf(exercise)}',
        WordReviewItem(:final lesson, :final card) =>
          'word ${lesson.id} ${card.word}',
        ReadingMistakeReviewItem(:final question) => 'reading ${question.id}',
      };
      expect(due.map(describe), [
        // Due Oct 12: u2-l1 mistakes in exercise order.
        'mistake u2-l1 1',
        'mistake u2-l1 2',
        // Due Oct 13.
        'word u2-l1 clause',
        // Due Oct 14: the u1-l1 mistake. Unit 1 comes before Unit 2 on
        // the path, but it is less overdue.
        'mistake u1-l1 3',
        // Due today.
        'word u1-l1 fluctuate',
        'word u1-l1 considerable',
      ]);

      // Same day: all mistakes first, then words, each in path order.
      final sameDay = const ProgressState()
          .withCompletedLesson(_completion('u2-l1', _day(-1), wrongAt: [1]))
          .withCompletedLesson(_completion('u1-l1', _day(-1), wrongAt: [3]));
      expect(_planner(sameDay).dueOn(_day(1)).map(describe), [
        'mistake u1-l1 3',
        'mistake u2-l1 1',
        'word u1-l1 fluctuate',
        'word u1-l1 considerable',
        'word u2-l1 clause',
      ]);
    });

    test('reviewed items follow their schedule', () {
      final mistake = _mistake('u2-l1', 1);
      final progress = _yesterdayWithMistake
          .withReview(
            ReviewCompletion(
              key: mistake.reviewKey,
              rating: ReviewRating.good,
              date: _today,
            ),
          )
          .withReview(
            ReviewCompletion(
              key: wordReviewKey(_clause),
              rating: ReviewRating.hard,
              date: _today,
            ),
          );
      final planner = _planner(progress);
      expect(planner.dueOn(_today), isEmpty);
      expect(planner.nextReviewAfter(_today), _day(1));
      expect(planner.dueOn(_day(1)).single, isA<WordReviewItem>());
      expect(planner.dueOn(_day(3)), hasLength(2));
    });

    test('Again keeps an item due today', () {
      final key = _mistake('u2-l1', 1).reviewKey;
      final progress = _yesterdayWithMistake.withReview(
        ReviewCompletion(key: key, rating: ReviewRating.again, date: _today),
      );
      expect(_planner(progress).dueOn(_today).map((i) => i.key), contains(key));
    });

    test('replaying a lesson restarts its mistakes; words keep their '
        'schedule', () {
      final word = wordReviewKey(_clause);
      final mistake = _mistake('u2-l1', 1).reviewKey;
      final reviewed = _yesterdayWithMistake
          .withReview(
            ReviewCompletion(
              key: mistake,
              rating: ReviewRating.good,
              date: _today,
            ),
          )
          .withReview(
            ReviewCompletion(
              key: word,
              rating: ReviewRating.good,
              date: _today,
            ),
          );
      final replayed = reviewed.withCompletedLesson(
        _completion('u2-l1', _today, wrongAt: [1]),
      );
      expect(replayed.reviews.containsKey(mistake), isFalse);
      expect(replayed.reviews[word]!.dueOn, _day(3));
      expect(replayed.openMistakesFor('u2-l1'), hasLength(1));
    });
  });

  group('XP', () {
    ProgressState reviewMany(ProgressState p, int count, DateTime day) {
      for (var i = 0; i < count; i++) {
        p = p.withReview(
          ReviewCompletion(
            key: 'word:test:$i',
            rating: ReviewRating.good,
            date: day,
          ),
        );
      }
      return p;
    }

    test('1 XP per item, at most 10 a day from reviews', () {
      final start = _yesterdayWithMistake;
      final lessonXp = start.totalXp;
      final p = reviewMany(start, 12, _today);
      expect(p.reviewXpOn(_today), XpRules.maxReviewPerDay);
      expect(p.totalXp, lessonXp + XpRules.maxReviewPerDay);
      expect(p.reviewXpFor(ReviewRating.easy, _today), 0);
      // The limit is per day.
      final tomorrow = reviewMany(p, 3, _day(1));
      expect(tomorrow.reviewXpOn(_day(1)), 3);
    });

    test('Again earns nothing', () {
      final p = _yesterdayWithMistake.withReview(
        ReviewCompletion(
          key: _mistake('u2-l1', 1).reviewKey,
          rating: ReviewRating.again,
          date: _today,
        ),
      );
      expect(p.reviewXpOn(_today), 0);
      // It still counts as activity for the streak.
      expect(p.streak(_today), 2);
    });

    test('review minutes count toward the day', () {
      final p = _yesterdayWithMistake.withReview(
        ReviewCompletion(
          key: 'word:test:0',
          rating: ReviewRating.good,
          date: _today,
          minutes: 2,
        ),
      );
      expect(p.minutesOn(_today), 2);
      expect(p.activeDays, contains(_today));
    });

    test('reviews survive a JSON round trip', () {
      final p = _yesterdayWithMistake.withReview(
        ReviewCompletion(
          key: wordReviewKey(_clause),
          rating: ReviewRating.easy,
          date: _today,
        ),
      );
      final restored = ProgressState.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      final s = restored.reviews[wordReviewKey(_clause)]!;
      expect(s.dueOn, _day(7));
      expect(s.lastRating, ReviewRating.easy);
      expect(restored.reviewXpOn(_today), 1);
    });
  });

  group('needs review', () {
    LearningPath path(ProgressState p) =>
        LearningPath(course: course, progress: p, startUnit: 2);

    ProgressState rateMistake(ProgressState p, ReviewRating r) => p.withReview(
      ReviewCompletion(
        key: _mistake('u2-l1', 1).reviewKey,
        rating: r,
        date: _today,
      ),
    );

    test('a lesson leaves "Needs review" once every mistake is Good or '
        'Easy', () {
      final lesson = _lesson('u2-l1');
      final start = const ProgressState().withCompletedLesson(
        _completion('u2-l1', _day(-1), wrongAt: [1, 2]),
      );
      expect(path(start).nodeFor(lesson).status, LessonStatus.reviewNeeded);

      final hard = rateMistake(start, ReviewRating.hard);
      expect(path(hard).nodeFor(lesson).status, LessonStatus.reviewNeeded);
      expect(path(hard).nodeFor(lesson).mistakeCount, 2);

      final oneGood = rateMistake(start, ReviewRating.good);
      expect(path(oneGood).nodeFor(lesson).status, LessonStatus.reviewNeeded);
      expect(path(oneGood).nodeFor(lesson).mistakeCount, 1);

      final bothDone = oneGood.withReview(
        ReviewCompletion(
          key: _mistake('u2-l1', 2).reviewKey,
          rating: ReviewRating.easy,
          date: _today,
        ),
      );
      expect(path(bothDone).nodeFor(lesson).status, LessonStatus.completed);
    });
  });

  group('screen', () {
    testWidgets('empty: nothing due shows "Nothing to review right now"', (
      tester,
    ) async {
      await _launchApp(tester);
      await _push(tester, '/review');
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
      expect(find.text('Nothing to review right now'), findsOneWidget);
      await _tap(tester, find.widgetWithText(AppButton, 'Back to Home'));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('empty state names the next review day', (tester) async {
      await _launchApp(
        tester,
        progress: const ProgressState().withCompletedLesson(
          _completion('u2-l1', _today),
        ),
      );
      await _push(tester, '/review');
      expect(find.text('Nothing to review right now'), findsOneWidget);
      expect(find.text('Your next review is tomorrow.'), findsOneWidget);
    });

    testWidgets('full session updates Home and Learn', (tester) async {
      await _launchApp(tester, progress: _yesterdayWithMistake);
      final lessonXp = _yesterdayWithMistake.totalXp;
      expect(find.text('1 mistake · 1 word'), findsOneWidget);
      await _tapTab(tester, 'Learn');
      expect(find.text('Needs review'), findsOneWidget);
      await _tapTab(tester, 'Home');

      await _tap(tester, find.text('1 mistake · 1 word'));
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      // 1. The mistake (more overdue) comes first. Wrong again → Again.
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.textContaining('Saved mistake'), findsOneWidget);
      expect(find.text(_question('u2-l1', 1).prompt), findsOneWidget);
      // The explanation only shows after answering.
      expect(find.text(_question('u2-l1', 1).explanation), findsNothing);
      await _answer(tester, correct: false);
      expect(find.widgetWithText(FeedbackPanel, 'Not quite'), findsOneWidget);
      expect(find.text(_question('u2-l1', 1).explanation), findsOneWidget);
      expect(_rating('Good'), findsNothing);
      await _tap(tester, find.widgetWithText(AppButton, 'Continue'));

      // 2. The word: front, reveal, then rate.
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('clause'), findsOneWidget);
      expect(_rating('Good'), findsNothing);
      await _tap(tester, find.widgetWithText(AppButton, 'Reveal meaning'));
      await _tap(tester, _rating('Good'));

      // 3. The mistake again, this time right.
      expect(find.text('2 of 2'), findsOneWidget);
      await _answer(tester, correct: true);
      expect(find.widgetWithText(FeedbackPanel, 'Correct'), findsOneWidget);
      expect(find.text(_question('u2-l1', 1).explanation), findsOneWidget);
      await _tap(tester, _rating('Good'));

      // All caught up.
      expect(find.text('All caught up'), findsOneWidget);
      expect(_labelled('Reviewed: 2 items'), findsOneWidget);
      expect(_labelled('XP earned: +2 XP'), findsOneWidget);
      expect(_labelled('Next review: Oct 18 in 3 days'), findsOneWidget);

      final saved = await _savedProgress();
      expect(saved.reviewXpOn(_today), 2);
      expect(saved.activeDays, contains(_today));
      expect(saved.minutesOn(_today), greaterThanOrEqualTo(1));

      await _tap(tester, find.widgetWithText(AppButton, 'Back to Home'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('UP NEXT FOR REVIEW'), findsNothing);
      await _scrollToTop(tester);
      expect(
        _labelled(RegExp('^Total XP: ${lessonXp + 2}\\. \\+2 today')),
        findsOneWidget,
      );
      expect(
        _labelled(RegExp(r'^Streak: 2 days\. Active today')),
        findsOneWidget,
      );
      expect(
        _labelled(RegExp(r'^Daily goal: 1 of 20 minutes')),
        findsOneWidget,
      );

      await _tapTab(tester, 'Learn');
      expect(find.text('Needs review'), findsNothing);
      expect(_labelled(RegExp(r'^Lesson 1: .*, completed')), findsOneWidget);
    });

    testWidgets('close saves what was rated, without asking', (tester) async {
      await _launchApp(tester, progress: _yesterdayWithMistake);
      await _push(tester, '/review');
      await _answer(tester, correct: true);
      await _tap(tester, _rating('Easy'));
      expect(find.text('2 of 2'), findsOneWidget);

      await _tap(tester, find.byTooltip('Close review'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ReviewScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      final saved = await _savedProgress();
      final mistake = saved.reviews[_mistake('u2-l1', 1).reviewKey]!;
      expect(mistake.lastRating, ReviewRating.easy);
      expect(mistake.dueOn, _day(7));
      expect(saved.reviews[wordReviewKey(_clause)], isNull);
      // Only the word is left.
      expect(find.text('1 vocabulary card due'), findsOneWidget);
    });

    testWidgets('no XP once the daily review limit is reached', (tester) async {
      final capped = ProgressState(
        results: _yesterdayWithMistake.results,
        xpLog: [
          ..._yesterdayWithMistake.xpLog,
          XpEntry(
            date: _today,
            amount: XpRules.maxReviewPerDay,
            source: XpEntry.reviewSource,
          ),
        ],
        activeDays: _yesterdayWithMistake.activeDays,
        mistakes: _yesterdayWithMistake.mistakes,
      );
      await _launchApp(tester, progress: capped);
      await _push(tester, '/review');
      await _answer(tester, correct: true);
      await _tap(tester, _rating('Good'));
      await _tap(tester, find.widgetWithText(AppButton, 'Reveal meaning'));
      await _tap(tester, _rating('Good'));
      expect(find.text('All caught up'), findsOneWidget);
      expect(_labelled('XP earned: +0 XP'), findsOneWidget);
      expect(find.text("Today's review XP is maxed out"), findsOneWidget);
      expect((await _savedProgress()).reviewXpOn(_today), 10);
    });

    testWidgets('the Learn "Needs review" node opens review', (tester) async {
      await _launchApp(tester, progress: _yesterdayWithMistake);
      await _tapTab(tester, 'Learn');
      await _tap(tester, find.byKey(const ValueKey('node-u2-l1')));
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
    });
  });

  group('stable ids', () {
    test('every exercise id is unique and names its lesson', () {
      final ids = [
        for (final lesson in course.lessons)
          for (final e in lesson.exercises) e.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
      for (final lesson in course.lessons) {
        for (final e in lesson.exercises) {
          expect(e.id, startsWith('${lesson.id}-e'));
        }
      }
    });

    test('editing a prompt keeps the mistake and its schedule', () {
      final original = _question('u2-l1', 1) as MultipleChoiceExercise;
      final progress = _yesterdayWithMistake.withReview(
        ReviewCompletion(
          key: _mistake('u2-l1', 1).reviewKey,
          rating: ReviewRating.hard,
          date: _today,
        ),
      );

      // The same exercise (same id) with reworded text.
      final edited = MultipleChoiceExercise(
        id: original.id,
        prompt: '${original.prompt} (reworded)',
        options: original.options,
        correctIndex: original.correctIndex,
        explanation: original.explanation,
        passage: original.passage,
      );
      final lesson = _lesson('u2-l1');
      final editedLesson = Lesson(
        unit: lesson.unit,
        number: lesson.number,
        title: lesson.title,
        objective: lesson.objective,
        learnItems: lesson.learnItems,
        estimatedMinutes: lesson.estimatedMinutes,
        exercises: [
          for (final e in lesson.exercises) e.id == original.id ? edited : e,
        ],
      );
      final editedCourse = Course([
        for (final unit in course.units)
          Unit(
            number: unit.number,
            title: unit.title,
            focus: unit.focus,
            lessons: [
              for (final l in unit.lessons)
                l.id == lesson.id ? editedLesson : l,
            ],
          ),
      ]);

      final planner = ReviewPlanner(course: editedCourse, progress: progress);
      final item = planner.items.whereType<MistakeReviewItem>().single;
      expect(item.exercise.prompt, edited.prompt);
      expect(item.schedule!.lastRating, ReviewRating.hard);
      expect(item.dueOn, _day(1));
      expect(
        LearningPath(
          course: editedCourse,
          progress: progress,
          startUnit: 2,
        ).nodeFor(editedLesson).mistakeCount,
        1,
      );
    });

    test('progress saved with prompt keys is migrated to ids', () async {
      final q = _question('u2-l1', 1);
      SharedPreferences.setMockInitialValues({
        'progress.v1': jsonEncode({
          'results': {
            'u2-l1': {
              'correct': 4,
              'total': 5,
              'xp': 18,
              'completedOn': '2026-10-14',
            },
          },
          'xpLog': [
            {'date': '2026-10-14', 'amount': 18, 'lessonId': 'u2-l1'},
          ],
          'minutesByDay': {'2026-10-14': 8},
          'activeDays': ['2026-10-14'],
          'mistakes': [
            {
              'lessonId': 'u2-l1',
              'prompt': q.savedPrompt,
              'yourAnswer': 'x',
              'correctAnswer': q.correctAnswer,
              'explanation': q.explanation,
            },
            // A question that no longer exists: dropped.
            {
              'lessonId': 'u2-l1',
              'prompt': 'Removed question',
              'yourAnswer': 'x',
              'correctAnswer': 'y',
              'explanation': 'z',
            },
          ],
          'reviews': {
            'mistake:u2-l1:${q.savedPrompt}': {
              'dueOn': '2026-10-18',
              'intervalDays': 3,
              'lastRating': 'good',
            },
            'word:u2-l1:clause': {
              'dueOn': '2026-10-22',
              'intervalDays': 7,
              'lastRating': 'easy',
            },
            'mistake:u2-l1:Removed question': {
              'dueOn': '2026-10-16',
              'intervalDays': 1,
              'lastRating': 'hard',
            },
          },
        }),
      });
      final repo = PrefsProgressRepository(loadCourse: () async => course);
      final loaded = await repo.load();

      expect(loaded.mistakes.single.itemId, q.id);
      expect(loaded.mistakes.single.sourceId, 'u2-l1');
      expect(loaded.reviews.keys, {
        mistakeReviewKey(q.id),
        wordReviewKey(_clause),
      });
      expect(loaded.reviews[mistakeReviewKey(q.id)]!.dueOn, _day(3));
      expect(loaded.totalXp, 18);
      expect(loaded.openMistakesFor('u2-l1'), isEmpty);

      // The migrated form is saved, so it only happens once.
      final saved = jsonDecode(
        (await SharedPreferences.getInstance()).getString('progress.v1')!,
      );
      expect(saved['version'], ProgressState.schemaVersion);
    });
  });

  group('option shuffle', () {
    test('a stable permutation per seed and item', () {
      final a = shuffledOptionOrder(4, seed: 1, key: 'mistake:u2-l1-e2');
      expect(a.toSet(), {0, 1, 2, 3});
      expect(shuffledOptionOrder(4, seed: 1, key: 'mistake:u2-l1-e2'), a);
      // Some seed reorders the options.
      expect(
        List.generate(
          10,
          (s) => shuffledOptionOrder(4, seed: s, key: 'k'),
        ).any((o) => o.join() != '0123'),
        isTrue,
      );
    });

    List<String> shownOptions(WidgetTester tester) => [
      for (final c in tester.widgetList<SelectionCard>(
        find.byType(SelectionCard),
      ))
        c.title,
    ];

    testWidgets('review shows the session order, kept after Again', (
      tester,
    ) async {
      await _launchApp(tester, progress: _yesterdayWithMistake);
      await _push(tester, '/review');
      final q = _question('u2-l1', 1);
      final expected = [
        for (final i in shuffledOptionOrder(
          q.options.length,
          seed: _seed,
          key: mistakeReviewKey(q.id),
        ))
          q.options[i],
      ];
      expect(expected, isNot(q.options), reason: 'pick a seed that shuffles');
      expect(shownOptions(tester), expected);

      await _answer(tester, correct: false);
      expect(shownOptions(tester), expected);
      await _tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await _tap(tester, find.widgetWithText(AppButton, 'Reveal meaning'));
      await _tap(tester, _rating('Good'));
      // The same question again, in the same order.
      expect(shownOptions(tester), expected);
    });

    testWidgets('lessons keep the original order', (tester) async {
      await _launchApp(tester);
      await _push(tester, '/lesson/u2-l1');
      await _tap(tester, find.widgetWithText(AppButton, 'Start'));
      await _tap(tester, find.widgetWithText(AppButton, 'Reveal meaning'));
      await _tap(tester, find.widgetWithText(AppButton, 'Continue'));
      expect(shownOptions(tester), _question('u2-l1', 1).options);
    });
  });

  testWidgets('rating tiles are white with a border on feedback panels', (
    tester,
  ) async {
    await _launchApp(tester, progress: _yesterdayWithMistake);
    await _push(tester, '/review');
    await _answer(tester, correct: true);
    final tiles = find.descendant(
      of: find.byType(FeedbackPanel),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Material &&
            w.shape is RoundedRectangleBorder &&
            (w.shape! as RoundedRectangleBorder).side.color == AppColors.border,
      ),
    );
    expect(tiles, findsNWidgets(4));
    for (final m in tester.widgetList<Material>(tiles)) {
      expect(m.color, AppColors.card);
    }
  });

  group('layout', () {
    // Mistakes with and without a passage, a fill-in-the-blank, and words.
    final seeded = const ProgressState()
        .withCompletedLesson(_completion('u1-l1', _day(-2), wrongAt: [3, 4]))
        .withCompletedLesson(_completion('u2-l1', _day(-1), wrongAt: [1]));

    for (final rtl in [false, true]) {
      final dir = rtl ? 'RTL' : 'LTR';

      Future<void> pump(WidgetTester tester, ProgressState? progress) async {
        _savePrefs(progress: progress);
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
              home: const ReviewScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('session: no overflow at 320px ($dir)', (tester) async {
        await pump(tester, seeded);
        final total = _planner(seeded).dueOn(_today).length;
        expect(find.text('1 of $total'), findsOneWidget);
        final answeredWrong = <String>{};
        for (var step = 0; step < 20; step++) {
          expect(tester.takeException(), isNull);
          if (find.text('All caught up').evaluate().isNotEmpty) break;
          if (find.byType(QuestionView).evaluate().isNotEmpty) {
            final q = tester
                .widget<QuestionView>(find.byType(QuestionView))
                .exercise;
            // Each mistake: wrong first, right when it comes back.
            final firstTime = answeredWrong.add(q.savedPrompt);
            await _answer(tester, correct: !firstTime);
            expect(tester.takeException(), isNull);
            if (firstTime) {
              await _tap(tester, find.widgetWithText(AppButton, 'Continue'));
            } else {
              await _tap(tester, _rating('Hard'));
            }
          } else {
            await _tap(
              tester,
              find.widgetWithText(AppButton, 'Reveal meaning'),
            );
            expect(tester.takeException(), isNull);
            await _tap(tester, _rating('Easy'));
          }
        }
        expect(find.text('All caught up'), findsOneWidget);
        expect(_labelled('Reviewed: $total items'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty state: no overflow at 320px ($dir)', (tester) async {
        await pump(tester, null);
        expect(find.text('Nothing to review right now'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
