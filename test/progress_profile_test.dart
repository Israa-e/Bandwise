import 'dart:convert';

import 'package:bandwise/core/models/skill.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/router/app_routes.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/utils/clock.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/home/domain/weekly_activity.dart';
import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/learn/domain/course.dart';
import 'package:bandwise/features/learn/domain/learning_path.dart';
import 'package:bandwise/features/learn/presentation/learn_screen.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/onboarding/presentation/welcome_screen.dart';
import 'package:bandwise/features/profile/presentation/data_controls.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/reading/domain/reading.dart';
import 'package:bandwise/features/reading/presentation/reading_hub_screen.dart';
import 'package:bandwise/features/review/presentation/review_providers.dart';
import 'package:bandwise/features/settings/presentation/settings_controller.dart';
import 'package:bandwise/features/writing/data/mock_writing_feedback_service.dart';
import 'package:bandwise/features/writing/data/writing_content.dart';
import 'package:bandwise/features/writing/domain/writing.dart';
import 'package:bandwise/features/writing/domain/writing_feedback.dart';
import 'package:bandwise/features/writing/domain/writing_submission.dart';
import 'package:bandwise/features/writing/presentation/widgets/feedback_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Thursday.
final _today = DateTime(2026, 10, 15);
DateTime _day(int offset) => DateTime(2026, 10, 15 + offset);

const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  skills: {Skill.writing},
  placementSkipped: true,
);

const _version = '0.1.0';

/// The sample Task 1 essay's prepared feedback.
final _task1Feedback = buildSampleFeedback(
  cyclingTask,
  sampleFeedback[cyclingTask.id]!,
  cyclingTask.sampleEssay,
  _day(0),
);

/// One lesson (yesterday), one full reading passage and two essays
/// (today): Task 1 with an estimate, Task 2 with demo feedback.
({ProgressState progress, List<WritingSubmission> essays}) _active() {
  final lesson = course.lessonById('u1-l1')!;
  final question = lesson.exercises.whereType<QuestionExercise>().first;
  final lessonMistake = SavedMistake(
    sourceId: lesson.id,
    itemId: question.id,
    prompt: question.savedPrompt,
    yourAnswer: question.options[(question.correctIndex + 1) % 2],
    correctAnswer: question.correctAnswer,
    explanation: question.explanation,
    savedOn: _day(-1),
  );
  const readingMistake = SavedMistake(
    source: MistakeSource.reading,
    sourceId: 'uhi',
    itemId: 'uhi-q1',
    prompt: 'Cities are warmer than the countryside at night.',
    yourAnswer: 'False',
    correctAnswer: 'True',
    explanation: 'Paragraph A says so.',
  );
  final essays = [
    WritingSubmission(
      id: 'ws-1',
      taskId: cyclingTask.id,
      mode: WritingMode.learning,
      text: cyclingTask.sampleEssay,
      timeUsed: const Duration(minutes: 18),
      submittedAt: DateTime(2026, 10, 15, 8),
      result: AnalysedResult(_task1Feedback, sample: true),
    ),
    WritingSubmission(
      id: 'ws-2',
      taskId: universitiesTask.id,
      mode: WritingMode.learning,
      text: 'My own short essay.',
      timeUsed: const Duration(minutes: 5),
      submittedAt: DateTime(2026, 10, 15, 8, 30),
      result: const DemoResult(),
    ),
  ];
  var progress = const ProgressState()
      .withCompletedLesson(
        LessonCompletion(
          lessonId: lesson.id,
          date: _day(-1),
          correctFirstTry: lesson.questionCount - 1,
          questionCount: lesson.questionCount,
          minutes: 9,
          mistakes: [lessonMistake],
        ),
      )
      .withReadingAttempt(
        ReadingCompletion(
          attempt: ReadingAttempt(
            passageId: 'uhi',
            timed: true,
            date: _day(0),
            correct: 7,
            total: 10,
            minutes: 20,
            xp: XpRules.forReading(correct: 7, timedPassage: true),
            byType: {
              ReadingQuestionType.trueFalseNotGiven.name: const TypeScore(
                correct: 1,
                total: 3,
              ),
              ReadingQuestionType.multipleChoice.name: const TypeScore(
                correct: 2,
                total: 3,
              ),
              ReadingQuestionType.matchingHeadings.name: const TypeScore(
                correct: 2,
                total: 2,
              ),
              ReadingQuestionType.sentenceCompletion.name: const TypeScore(
                correct: 2,
                total: 2,
              ),
            },
          ),
          questionIds: const ['uhi-q1'],
          mistakes: [
            SavedMistake(
              source: readingMistake.source,
              sourceId: readingMistake.sourceId,
              itemId: readingMistake.itemId,
              prompt: readingMistake.prompt,
              yourAnswer: readingMistake.yourAnswer,
              correctAnswer: readingMistake.correctAnswer,
              explanation: readingMistake.explanation,
              savedOn: _day(0),
            ),
          ],
        ),
      );
  for (final e in essays) {
    progress = progress.withWritingSubmission(
      date: _day(0),
      minutes: e.timeUsed.inMinutes,
      xp: XpRules.perNewEssay,
      submissionId: e.id,
    );
  }
  return (progress: progress, essays: essays);
}

void _seed({
  OnboardingState onboarding = _onboarding,
  ProgressState? progress,
  List<WritingSubmission> essays = const [],
  String? settings,
}) {
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(onboarding.toJson()),
    'progress.v1': ?(progress == null ? null : jsonEncode(progress.toJson())),
    if (essays.isNotEmpty)
      'writing.submissions.v1': jsonEncode([
        for (final e in essays) e.toJson(),
      ]),
    'settings.v1': ?settings,
  });
  PackageInfo.setMockInitialValues(
    appName: 'Bandwise',
    packageName: 'app.bandwise',
    version: _version,
    buildNumber: '1',
    buildSignature: '',
  );
}

void _seedActive({String? settings}) {
  final a = _active();
  _seed(progress: a.progress, essays: a.essays, settings: settings);
}

late ProviderContainer _container;

Future<void> _launch(
  WidgetTester tester, {
  Size size = const Size(390, 900),
  bool rtl = false,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  _container = ProviderContainer(
    overrides: [
      todayProvider.overrideWithValue(_today),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 15, 9)),
    ],
  );
  addTearDown(_container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: ref.watch(routerProvider),
          // As in BandwiseApp, plus the text direction.
          builder: (context, child) => Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: MotionScope(child: child!),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AppBottomNav), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String location) async {
  _container.read(routerProvider).push(location);
  await tester.pumpAndSettle();
}

/// Scrolls the page until [finder] is built, then fully into view.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final list = find.byType(Scrollable).first;
    try {
      await tester.scrollUntilVisible(finder, 300, scrollable: list);
    } on StateError {
      await tester.scrollUntilVisible(finder, -300, scrollable: list);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  // Clear of the bottom nav.
  final rect = tester.getRect(finder);
  final navTop = find.byType(AppBottomNav).evaluate().isEmpty
      ? double.infinity
      : tester.getTopLeft(find.byType(AppBottomNav)).dy;
  if (rect.bottom > navTop) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<Map<String, Object>> _prefs() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final k in prefs.getKeys()) k: prefs.get(k)!};
}

Future<ProgressState> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return raw == null
      ? const ProgressState()
      : ProgressState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<OnboardingState> _savedOnboarding() async {
  final raw = (await SharedPreferences.getInstance()).getString(
    'onboarding.v1',
  );
  return OnboardingState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
];

/// Scrolls the whole page from the top, collecting every text and checking
/// for layout errors on the way.
Future<Set<String>> _scrollPage(WidgetTester tester) async {
  final texts = <String>{..._allText(tester)};
  final lists = find.byType(Scrollable);
  if (lists.evaluate().isEmpty) return texts;
  for (var i = 0; i < 20; i++) {
    expect(tester.takeException(), isNull);
    await tester.drag(lists.first, const Offset(0, -350));
    await tester.pumpAndSettle();
    texts.addAll(_allText(tester));
  }
  expect(tester.takeException(), isNull);
  return texts;
}

final _range = RegExp(r'^\d\.\d–\d\.\d$');

/// No band text: decimals only in labelled ranges, the Goal chip and the
/// app version; no "band" anywhere.
void _expectNoBands(Iterable<String> texts) {
  final decimal = RegExp(r'\d\.\d');
  for (final t in texts) {
    expect(
      RegExp(r'\bband\b', caseSensitive: false).hasMatch(t),
      isFalse,
      reason: t,
    );
    if (!decimal.hasMatch(t)) continue;
    final allowed =
        _range.hasMatch(t) ||
        RegExp(r'^Goal \d\.\d\+?$').hasMatch(t) ||
        t.startsWith(_version);
    expect(allowed, isTrue, reason: t);
  }
}

String _statValue(WidgetTester tester, String key) =>
    tester.widget<StatTile>(find.byKey(ValueKey('summary-$key'))).value;

void main() {
  group('Progress', () {
    testWidgets('a new user gets empty states, not zeros', (tester) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Progress');

      expect(find.byKey(const ValueKey('progressEmpty')), findsOneWidget);
      expect(
        find.textContaining('Finish your first lesson to see your progress'),
        findsOneWidget,
      );
      expect(find.byType(StatTile), findsNothing);
      // No numbers on the page apart from the Goal chip.
      for (final t in _allText(tester)) {
        if (t.startsWith('Goal ')) continue;
        expect(RegExp(r'\d').hasMatch(t), isFalse, reason: t);
      }

      await _push(tester, AppRoutes.mistakeNotebook);
      expect(find.byKey(const ValueKey('mistakesEmpty')), findsOneWidget);
      await _push(tester, AppRoutes.vocabularyNotebook);
      expect(find.byKey(const ValueKey('wordsEmpty')), findsOneWidget);
      _container.read(routerProvider).pop();
      _container.read(routerProvider).pop();
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Start learning'));
      expect(find.byType(LearnScreen), findsOneWidget);
    });

    testWidgets('after a lesson, a reading passage and essays, every '
        'summary number matches the saved progress', (tester) async {
      _seedActive();
      await _launch(tester);
      await _tab(tester, 'Progress');

      final saved = await _savedProgress();
      expect(saved.results, hasLength(1));
      expect(saved.readingAttempts, hasLength(1));
      expect(_statValue(tester, 'streak'), '${saved.streak(_today)}');
      expect(_statValue(tester, 'streak'), '2');
      expect(
        tester
            .widget<StatTile>(find.byKey(const ValueKey('summary-streak')))
            .footer,
        'Longest: ${saved.longestStreak} days',
      );
      expect(_statValue(tester, 'xp'), '${saved.totalXp}');
      expect(saved.totalXp, greaterThan(0));
      expect(_statValue(tester, 'time'), formatStudyTime(saved.totalMinutes));
      expect(_statValue(tester, 'lessons'), '${saved.results.length}');

      // This week, with the goal line and the days it was met.
      final week = WeeklyActivity.build(
        today: _today,
        minutesToday: saved.minutesOn(_today),
        minutesByDay: saved.minutesByDay,
        dailyGoal: 20,
      );
      await _reveal(tester, find.byKey(const ValueKey('goalDays')));
      expect(
        find.text(
          'Goal met on ${week.goalDays} '
          '${week.goalDays == 1 ? 'day' : 'days'}',
        ),
        findsOneWidget,
      );
      expect(find.text('Daily goal: 20 min'), findsOneWidget);

      // The calendar: active days filled, the streak rule explained.
      await _reveal(tester, find.byKey(const ValueKey('calendarActiveCount')));
      expect(find.text('October 2026'), findsOneWidget);
      expect(
        find.text('${saved.activeDays.length} active days'),
        findsOneWidget,
      );
      final today = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('day-2026-10-15')),
          matching: find.byType(Container),
        ),
      );
      expect((today.decoration! as BoxDecoration).border, isNotNull);
      expect((today.decoration! as BoxDecoration).color, AppColors.primary);
      final inactive = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('day-2026-10-13')),
          matching: find.byType(Container),
        ),
      );
      expect((inactive.decoration! as BoxDecoration).color, isNull);
      expect(find.textContaining('at least one activity'), findsOneWidget);
      // Only months with activity: no earlier month.
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
            )
            .onPressed,
        isNull,
      );

      // Skills and lessons.
      await _reveal(tester, find.byKey(const ValueKey('readingCard')));
      expect(find.text('1 attempt'), findsOneWidget);
      expect(find.text('Multiple choice'), findsOneWidget);
      expect(find.text('2/3 · 67%'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('writingCard')));
      expect(find.text('2 essays'), findsOneWidget);
      final path = LearningPath(course: course, progress: saved, startUnit: 2);
      await _reveal(tester, find.byKey(const ValueKey('unit-1')));
      expect(
        find.text('${path.statsFor(course.unit(1)).percentComplete}% complete'),
        findsOneWidget,
      );
      await _reveal(tester, find.byKey(const ValueKey('skill-listening')));
      expect(find.text('Not started — coming soon'), findsNWidgets(2));
      await _reveal(tester, find.byKey(const ValueKey('mistakeNotebookEntry')));
      expect(
        find.textContaining('${saved.mistakes.length} saved mistakes'),
        findsOneWidget,
      );
    });

    testWidgets('a unit opens on Learn', (tester) async {
      _seedActive();
      await _launch(tester);
      await _tab(tester, 'Progress');
      await _tap(tester, find.byKey(const ValueKey('unit-3')));
      expect(find.byType(LearnScreen), findsOneWidget);
      expect(find.text(course.unit(3).fullTitle), findsOneWidget);
    });

    testWidgets('the weakest Reading type is recommended and opens the hub '
        'filtered to it', (tester) async {
      _seedActive();
      await _launch(tester);
      await _tab(tester, 'Progress');

      await _reveal(tester, find.byKey(const ValueKey('recommendation')));
      expect(find.text('Based on your recent answers'), findsOneWidget);
      const tfng = ReadingQuestionType.trueFalseNotGiven;
      expect(
        find.text('${tfng.label} is your weakest question type lately.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Practise ${tfng.label}'));

      expect(find.byType(ReadingHubScreen), findsOneWidget);
      await _reveal(tester, find.widgetWithText(SelectionCard, 'Learning'));
      expect(
        tester
            .widget<SelectionCard>(
              find.widgetWithText(SelectionCard, 'Learning'),
            )
            .state,
        SelectionCardState.selected,
      );
      await _reveal(tester, find.widgetWithText(AppFilterChip, tfng.label));
      expect(
        tester
            .widget<AppFilterChip>(
              find.widgetWithText(AppFilterChip, tfng.label),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<AppFilterChip>(
              find.widgetWithText(AppFilterChip, 'All types'),
            )
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<SelectionCard>(
              find.widgetWithText(SelectionCard, 'Learning'),
            )
            .state,
        SelectionCardState.selected,
      );
    });

    testWidgets('Writing shows estimate ranges with the label, and "No '
        'estimate yet" for demo feedback', (tester) async {
      _seedActive();
      await _launch(tester);
      await _tab(tester, 'Progress');
      await _reveal(tester, find.byKey(const ValueKey('writing-task2')));

      final range = find.descendant(
        of: find.byKey(const ValueKey('writing-task1')),
        matching: find.byType(EstimateRangeText),
      );
      expect(range, findsOneWidget);
      expect(
        tester.widget<EstimateRangeText>(range).range,
        _task1Feedback.overall,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('writing-task1')),
          matching: find.text(estimateLabel),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('noEstimate-task2')), findsOneWidget);
      expect(find.text('No estimate yet'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('writing-task2')),
          matching: find.byType(EstimateRangeText),
        ),
        findsNothing,
      );
      expect(
        find.textContaining('Most of your notes are about'),
        findsOneWidget,
      );
    });

    testWidgets('removing a word takes it out of the review queue but keeps '
        'it listed', (tester) async {
      _seedActive();
      await _launch(tester);
      final word = course
          .lessonById('u1-l1')!
          .exercises
          .whereType<FlashcardExercise>()
          .first;
      final key = wordReviewKey(word.id);
      Future<List<String>> due() async => [
        for (final i in (await _container.read(
          reviewPlannerProvider.future,
        )).dueOn(_today))
          i.key,
      ];
      expect(await due(), contains(key));

      await _push(tester, AppRoutes.vocabularyNotebook);
      expect(find.text(word.word), findsOneWidget);
      expect(find.text('Next review: today'), findsWidgets);
      await _tap(tester, find.byKey(ValueKey('removeWord-${word.id}')));

      expect(await due(), isNot(contains(key)));
      expect((await _savedProgress()).removedFromReview, {key});
      expect(find.text(word.word), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(ValueKey('wordReview-${word.id}'))).data,
        'Not in your reviews',
      );

      // Search narrows the list; removed words still match.
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('wordSearch')),
          matching: find.byType(EditableText),
        ),
        word.word,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('word-${word.id}')), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('wordSearch')),
          matching: find.byType(EditableText),
        ),
        'zzzz',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No words match'), findsOneWidget);
    });

    testWidgets('the mistake notebook groups by source, filters by skill and '
        'opens the review', (tester) async {
      _seedActive();
      await _launch(tester);
      await _push(tester, AppRoutes.mistakeNotebook);

      final lesson = course.lessonById('u1-l1')!;
      expect(
        find.text('Unit 1 · ${lesson.label}: ${lesson.title}'),
        findsOneWidget,
      );
      await _reveal(tester, find.byKey(const ValueKey('mistake-uhi-q1')));
      expect(
        _allText(tester).where((t) => t == 'Your answer: False'),
        isNotEmpty,
      );
      expect(_allText(tester), contains('Correct answer: True'));
      expect(find.text('Next review: today'), findsWidgets);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      await _tap(tester, find.widgetWithText(AppFilterChip, 'Reading'));
      expect(find.byKey(const ValueKey('mistake-uhi-q1')), findsOneWidget);
      expect(
        find.text('Unit 1 · ${lesson.label}: ${lesson.title}'),
        findsNothing,
      );

      await _tap(tester, find.widgetWithText(AppButton, 'Review now'));
      expect(find.byType(AppBottomNav), findsNothing);
    });

    testWidgets('no band text outside labelled ranges and the Goal chip', (
      tester,
    ) async {
      _seedActive();
      await _launch(tester);
      await _tab(tester, 'Progress');
      final progressTexts = await _scrollPage(tester);
      _expectNoBands(progressTexts);
      // Every range on the page has its label.
      expect(progressTexts.where(_range.hasMatch), isNotEmpty);
      expect(progressTexts, contains(estimateLabel));

      await _tab(tester, 'Profile');
      _expectNoBands(await _scrollPage(tester));
    });
  });

  group('Profile', () {
    testWidgets('header: Guest, Goal, exam countdown, daily goal, level', (
      tester,
    ) async {
      _seed(
        onboarding: _onboarding.copyWith(
          examDate: () => DateTime(2026, 12, 10),
        ),
      );
      await _launch(tester);
      await _tab(tester, 'Profile');
      expect(find.text('Guest'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profileHeader')),
          matching: find.byType(GoalChip),
        ),
        findsOneWidget,
      );
      expect(find.text('Exam in 8 weeks · Dec 10, 2026'), findsWidgets);
      expect(find.text('Daily goal: 20 min a day'), findsOneWidget);
      expect(find.text('Level: Intermediate (self-assessed)'), findsOneWidget);
    });

    testWidgets('no exam date set', (tester) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('examLine'))).data,
        'No exam date set',
      );
    });

    testWidgets('Edit plan saves, and Home, the plan and Practice update', (
      tester,
    ) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');

      await _tap(tester, find.byKey(const ValueKey('editDailyTime')));
      expect(find.text('Edit plan'), findsOneWidget);
      expect(find.textContaining('Step'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.byType(AppBottomNav), findsNothing);
      await _tap(tester, find.text('30 min / day'));
      await _tap(tester, find.widgetWithText(AppButton, 'Save'));

      expect((await _savedOnboarding()).dailyMinutes, 30);
      await _reveal(tester, find.byKey(const ValueKey('dailyGoalLine')));
      expect(find.text('Daily goal: 30 min a day'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('editSkills')));
      await _tap(tester, find.text('Reading'));
      await _tap(tester, find.widgetWithText(AppButton, 'Save'));
      expect((await _savedOnboarding()).skills, {Skill.writing, Skill.reading});
      expect(find.text('Reading, Writing'), findsOneWidget);

      await _tab(tester, 'Home');
      expect(_allText(tester), contains('0/30m'));
      await _tab(tester, 'Practice');
      for (final skill in Skill.values) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('practice-${skill.name}')),
            matching: find.byKey(const ValueKey('focusTag')),
          ),
          skill == Skill.reading || skill == Skill.writing
              ? findsOneWidget
              : findsNothing,
          reason: skill.name,
        );
      }
    });

    testWidgets('Cancel changes nothing', (tester) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');
      final before = jsonEncode((await _savedOnboarding()).toJson());

      await _tap(tester, find.byKey(const ValueKey('editTarget')));
      await _tap(tester, find.text(TargetBand.band8plus.descriptor));
      await _tap(tester, find.widgetWithText(AppButton, 'Cancel'));
      expect(jsonEncode((await _savedOnboarding()).toJson()), before);
      expect(find.text('Goal 7.0'), findsWidgets);

      // Back is a cancel too, and a reopened editor starts from the plan.
      await _tap(tester, find.byKey(const ValueKey('editExamDate')));
      await _tap(tester, find.text("I haven't booked my exam yet"));
      _container.read(routerProvider).pop();
      await tester.pumpAndSettle();
      expect(jsonEncode((await _savedOnboarding()).toJson()), before);
      await _tap(tester, find.byKey(const ValueKey('editExamDate')));
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('achievements show what is earned, with the date', (
      tester,
    ) async {
      _seedActive();
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _reveal(tester, find.byKey(const ValueKey('badge-firstRevision')));
      String status(String kind) =>
          tester.widget<Text>(find.byKey(ValueKey('badgeStatus-$kind'))).data!;
      expect(status('firstLesson'), 'Earned Oct 14, 2026');
      expect(status('firstReading'), 'Earned Oct 15, 2026');
      expect(status('firstEssay'), 'Earned Oct 15, 2026');
      expect(
        status('perfectPassage'),
        'Answer every question on a full '
        'passage correctly.',
      );
      expect(status('firstRevision'), 'Revise an essay and resubmit it.');
      expect(status('streak3'), 'Study three days in a row.');
      expect(find.textContaining('3 of 8 earned'), findsOneWidget);
    });

    testWidgets('reminder: toggle and time are stored, with the note', (
      tester,
    ) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('reminderSwitch')));
      expect((await _savedOnboarding()).reminderEnabled, isTrue);
      expect(
        (await _savedOnboarding()).reminderTime,
        OnboardingState.defaultReminderTime,
      );
      expect(
        find.text(
          'Reminders will start in a future update. Your time is '
          'saved.',
        ),
        findsOneWidget,
      );
      expect(find.text('Dark: coming soon'), findsOneWidget);
      expect(find.text('Arabic: coming soon'), findsOneWidget);
    });

    testWidgets('Reset progress keeps the plan and settings', (tester) async {
      _seedActive(settings: '{"motion":"reduced"}');
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('resetProgress')));
      for (final item in resetProgressItems) {
        expect(find.text(item), findsOneWidget);
      }
      for (final item in deleteAllExtraItems) {
        expect(find.text(item), findsNothing);
      }
      await tester.tap(find.widgetWithText(TextButton, 'Reset progress'));
      await tester.pumpAndSettle();

      final prefs = await _prefs();
      expect(prefs.keys, isNot(contains('progress.v1')));
      expect(prefs.keys, isNot(contains('writing.submissions.v1')));
      expect(prefs.keys, isNot(contains('writing.drafts.v1')));
      expect(prefs['settings.v1'], '{"motion":"reduced"}');
      final onboarding = await _savedOnboarding();
      expect(jsonEncode(onboarding.toJson()), jsonEncode(_onboarding.toJson()));

      await _tab(tester, 'Progress');
      expect(find.byKey(const ValueKey('progressEmpty')), findsOneWidget);
    });

    testWidgets('Delete all data clears everything and returns to Welcome', (
      tester,
    ) async {
      _seedActive(settings: '{"motion":"reduced"}');
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('deleteAllData')));
      for (final item in [...resetProgressItems, ...deleteAllExtraItems]) {
        expect(find.text(item), findsOneWidget);
      }
      // Cancel first: nothing changes.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect((await _prefs()).keys, contains('progress.v1'));

      await _tap(tester, find.byKey(const ValueKey('deleteAllData')));
      await tester.tap(find.widgetWithText(TextButton, 'Delete all data'));
      await tester.pumpAndSettle();
      expect((await _prefs()).keys, isEmpty);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Privacy and AI, and About', (tester) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _reveal(tester, find.byKey(const ValueKey('disclaimer')));
      expect(find.textContaining('not affiliated with'), findsOneWidget);
      for (final name in ['IELTS', 'British Council', 'IDP', 'Cambridge']) {
        expect(find.textContaining(name), findsOneWidget);
      }
      expect(find.text('$_version (1)'), findsOneWidget);
      expect(find.byKey(const ValueKey('componentGallery')), findsOneWidget);
      expect(find.text('Open-source licences'), findsOneWidget);

      await _tap(tester, find.text('Privacy and AI'));
      await _reveal(tester, find.textContaining("AI review isn't connected"));
      await _reveal(tester, find.text('Planned policy'));
      expect(
        find.textContaining(
          'never be used to train AI models without your '
          'consent',
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Privacy Policy'));
      expect(find.byType(ComingSoonScaffold), findsOneWidget);
    });

    testWidgets('the account card opens account creation', (tester) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');
      await _reveal(
        tester,
        find.text('Create an account to back up your progress'),
      );
      await _tap(tester, find.widgetWithText(AppButton, 'Create account'));
      expect(find.text('Create your account'), findsOneWidget);
    });
  });

  group('reduce motion', () {
    Future<void> pumpBadge(
      WidgetTester tester, {
      String? settings,
      bool deviceReduces = false,
    }) async {
      _seed(settings: settings);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: deviceReduces);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        ProviderScope(
          // A fresh scope each time, so saved settings are read again.
          key: UniqueKey(),
          child: MaterialApp(
            builder: (context, child) => MotionScope(child: child!),
            home: const Scaffold(body: Center(child: SuccessBadge())),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final animated = find.byType(TweenAnimationBuilder<double>);

    testWidgets('follows the device by default', (tester) async {
      await pumpBadge(tester);
      expect(animated, findsOneWidget);
      await pumpBadge(tester, deviceReduces: true);
      expect(animated, findsNothing);
    });

    testWidgets('the in-app override wins either way', (tester) async {
      await pumpBadge(tester, settings: '{"motion":"reduced"}');
      expect(animated, findsNothing);
      await pumpBadge(
        tester,
        settings: '{"motion":"full"}',
        deviceReduces: true,
      );
      expect(animated, findsOneWidget);
    });

    testWidgets('set from Profile, it applies across the app', (tester) async {
      _seed();
      await _launch(tester);
      await _tab(tester, 'Profile');
      bool disabled() => MediaQuery.disableAnimationsOf(
        tester.element(find.byKey(const ValueKey('profileHeader'))),
      );
      expect(disabled(), isFalse);
      await _tap(tester, find.byKey(const ValueKey('motion-reduced')));
      expect(
        (await SharedPreferences.getInstance()).getString('settings.v1'),
        '{"motion":"reduced"}',
      );
      await _reveal(tester, find.byKey(const ValueKey('profileHeader')));
      expect(disabled(), isTrue);
      // Page transitions are off too.
      final theme = Theme.of(
        tester.element(find.byKey(const ValueKey('profileHeader'))),
      );
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isNot(isA<ZoomPageTransitionsBuilder>()),
      );
    });
  });

  group('layout', () {
    for (final rtl in [false, true]) {
      final dir = rtl ? 'RTL' : 'LTR';
      testWidgets('Progress, notebooks, Profile and Edit plan at 320px: no '
          'overflow ($dir)', (tester) async {
        _seedActive();
        await _launch(tester, size: const Size(320, 640), rtl: rtl);
        await _tab(tester, 'Progress');
        await _scrollPage(tester);
        for (final route in [
          AppRoutes.mistakeNotebook,
          AppRoutes.vocabularyNotebook,
          AppRoutes.privacy,
          AppRoutes.editTarget,
          AppRoutes.editExamDate,
          AppRoutes.editDailyTime,
          AppRoutes.editSkills,
        ]) {
          await _push(tester, route);
          await _scrollPage(tester);
          _container.read(routerProvider).pop();
          await tester.pumpAndSettle();
        }
        await _tab(tester, 'Profile');
        await _scrollPage(tester);
        await _tap(tester, find.byKey(const ValueKey('deleteAllData')));
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
      });

      testWidgets('new user Progress at 320px: no overflow ($dir)', (
        tester,
      ) async {
        _seed();
        await _launch(tester, size: const Size(320, 640), rtl: rtl);
        await _tab(tester, 'Progress');
        await _scrollPage(tester);
      });
    }
  });
}
