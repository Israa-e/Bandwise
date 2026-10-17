import 'dart:async';
import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/models/skill.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/home/data/mock_home_repository.dart';
import 'package:bandwise/features/home/domain/home_repository.dart';
import 'package:bandwise/features/home/domain/home_summary.dart';
import 'package:bandwise/features/home/domain/weekly_activity.dart';
import 'package:bandwise/features/home/presentation/home_providers.dart';
import 'package:bandwise/features/home/presentation/home_screen.dart';
import 'package:bandwise/features/home/presentation/widgets/home_skeleton.dart';
import 'package:bandwise/features/lesson/presentation/lesson_screen.dart';
import 'package:bandwise/features/notifications/presentation/notifications_screen.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/practice/presentation/practice_screen.dart';
import 'package:bandwise/features/review/presentation/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Thursday: Mon-Wed are past, Fri-Sun are planned.
final _today = DateTime(2026, 10, 15);

/// Finished onboarding: target 7.0, 20 minutes a day, Writing and Speaking
/// as focus skills, placement skipped with an intermediate self-assessment
/// (recommends Unit 2).
const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  skills: {Skill.writing, Skill.speaking},
  placementSkipped: true,
);

void _savePrefs(OnboardingState state) =>
    SharedPreferences.setMockInitialValues({
      'onboarding.v1': jsonEncode(state.toJson()),
    });

MockHomeRepository _repo(HomeFixture fixture) =>
    MockHomeRepository(fixture: fixture, today: _today, delay: Duration.zero);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps Home alone (no router), optionally right-to-left.
Future<void> _pumpHome(
  WidgetTester tester, {
  required HomeRepository repository,
  OnboardingState onboarding = _onboarding,
  Size size = const Size(390, 2600),
  bool rtl = false,
}) async {
  _savePrefs(onboarding);
  _setSize(tester, size);
  await tester.pumpWidget(
    ProviderScope(
      // Fail fast instead of Riverpod's automatic retries.
      retry: (_, _) => null,
      overrides: [
        todayProvider.overrideWithValue(_today),
        homeRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps the whole app, which opens on Home after the splash.
Future<void> _launchApp(WidgetTester tester, HomeFixture fixture) async {
  _savePrefs(_onboarding);
  _setSize(tester, const Size(390, 844));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(_today),
        homeRepositoryProvider.overrideWithValue(_repo(fixture)),
      ],
      child: const BandwiseApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

/// All visible text, including spans.
List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
];

Finder _dayBar(int i) => find.byKey(ValueKey('dayBar$i'));

/// The label a day bar gives screen readers.
String _semanticsLabel(WidgetTester tester, Finder bar) => tester
    .widget<Semantics>(
      find.descendant(of: bar, matching: find.byType(Semantics)).first,
    )
    .properties
    .label!;

void main() {
  group('new user', () {
    testWidgets('no streak or XP history, no chart, starting unit shown', (
      tester,
    ) async {
      await _pumpHome(tester, repository: _repo(HomeFixture.newUser));

      expect(find.text('Hi, Sam'), findsOneWidget);
      expect(find.text('Start today'), findsOneWidget);
      expect(find.text('Earn XP in lessons'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing); // no "+N today"
      expect(find.text('Active today'), findsNothing);
      expect(find.text('20m left'), findsOneWidget);

      // Continue card: recommended unit, lesson 1.
      expect(find.text('Recommended start'), findsOneWidget);
      expect(
        find.text('Unit 2: Sentence structure for academic English'),
        findsOneWidget,
      );
      expect(find.text('Lesson 1 · Not started'), findsOneWidget);
      expect(find.text('Start lesson'), findsOneWidget);
      expect(find.text('50% of unit'), findsNothing);

      // No reviews due.
      expect(find.text('UP NEXT FOR REVIEW'), findsNothing);

      // Every skill says Start; focus skills from onboarding are tagged.
      expect(find.text('Start'), findsNWidgets(4));
      expect(find.text('Focus'), findsNWidgets(2));

      // Empty week instead of a chart.
      expect(find.text('Your week starts today'), findsOneWidget);
      expect(_dayBar(0), findsNothing);
      expect(find.byKey(const ValueKey('weeklyTotal')), findsNothing);
    });

    testWidgets('guest sees "Hi there" and a person avatar', (tester) async {
      await _pumpHome(
        tester,
        repository: _repo(HomeFixture.newUser),
        onboarding: _onboarding.copyWith(isGuest: true),
      );
      expect(find.text('Hi there'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('goal chip is hidden when the target is "Not sure"', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        repository: _repo(HomeFixture.newUser),
        onboarding: _onboarding.copyWith(targetBand: () => TargetBand.notSure),
      );
      expect(find.textContaining('Goal'), findsNothing);
    });
  });

  group('active user', () {
    testWidgets('stats, resume card, review card and skill badges', (
      tester,
    ) async {
      await _pumpHome(tester, repository: _repo(HomeFixture.activeUser));

      expect(find.text('Hi, Alex'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('Goal 7.0'), findsOneWidget);
      expect(find.text('+45 today'), findsOneWidget);
      expect(find.text('Active today'), findsOneWidget);
      expect(find.text('5m left'), findsOneWidget);
      expect(find.text('Building a clear main argument'), findsOneWidget);
      // The chip names the unit number only, not its title.
      expect(find.text('Unit 3'), findsOneWidget);
      expect(find.textContaining('Paraphrasing'), findsNothing);
      expect(find.text('50% of unit'), findsOneWidget);
      expect(find.text('12 saved mistakes'), findsOneWidget);

      expect(find.text('88% accuracy'), findsOneWidget);
      expect(find.text('74% accuracy'), findsOneWidget);
      expect(find.text('2 essays this week'), findsOneWidget);
      expect(find.text('Last session Oct 6'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('weekly total is the sum of the bars; future days are '
        'planned, not filled', (tester) async {
      await _pumpHome(tester, repository: _repo(HomeFixture.activeUser));

      var studied = 0;
      for (var i = 0; i < 7; i++) {
        final label = _semanticsLabel(tester, _dayBar(i));
        final filled = find.descendant(
          of: _dayBar(i),
          matching: find.byType(DecoratedBox),
        );
        final dashed = find.descendant(
          of: _dayBar(i),
          matching: find.byType(CustomPaint),
        );
        if (i <= 3) {
          // Mon-Wed past, Thu today.
          expect(label, isNot(contains('planned')), reason: label);
          expect(filled, findsOneWidget);
          expect(dashed, findsNothing);
          studied += int.parse(RegExp(r'(\d+) minutes').firstMatch(label)![1]!);
        } else {
          // Fri-Sun planned at the daily goal.
          expect(label, contains('planned 20 minutes'));
          expect(filled, findsNothing);
          expect(dashed, findsOneWidget);
        }
      }
      expect(_semanticsLabel(tester, _dayBar(3)), startsWith('Today'));

      // Mon 45 + Tue 50 + Wed 35 + today 15.
      expect(studied, 145);
      final total = tester.widget<Text>(
        find.byKey(const ValueKey('weeklyTotal')),
      );
      expect(total.data, formatStudyTime(studied));
      expect(total.data, '2h 25m');
    });
  });

  for (final fixture in HomeFixture.values) {
    testWidgets('no band numbers on Home except the goal chip '
        '(${fixture.label})', (tester) async {
      await _pumpHome(tester, repository: _repo(fixture));
      final decimal = RegExp(r'\d\.\d');
      final band = RegExp(r'\bband\b', caseSensitive: false);
      final offending = _allText(tester).where(
        (t) =>
            !t.startsWith('Goal ') && (decimal.hasMatch(t) || band.hasMatch(t)),
      );
      expect(offending, isEmpty);
      expect(find.text('Goal 7.0'), findsOneWidget);
    });

    for (final rtl in [false, true]) {
      testWidgets('no overflow at 320px (${fixture.label}, '
          '${rtl ? 'RTL' : 'LTR'})', (tester) async {
        await _pumpHome(
          tester,
          repository: _repo(fixture),
          size: const Size(320, 640),
          rtl: rtl,
        );
        await tester.scrollUntilVisible(
          find.text('Weekly activity'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('states', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      final pending = Completer<HomeSummary>();
      await _pumpHome(
        tester,
        repository: _FakeRepository(() => pending.future),
      );
      expect(find.byType(HomeSkeleton), findsOneWidget);
      final summary = await tester.runAsync(
        () => _repo(HomeFixture.newUser).fetchSummary(),
      );
      pending.complete(summary);
      await tester.pumpAndSettle();
      expect(find.byType(HomeSkeleton), findsNothing);
      expect(find.text('Hi, Sam'), findsOneWidget);
    });

    testWidgets('shows an error with Retry', (tester) async {
      var calls = 0;
      await _pumpHome(
        tester,
        repository: _FakeRepository(() async {
          if (calls++ == 0) throw Exception('offline');
          return _repo(HomeFixture.activeUser).fetchSummary();
        }),
      );
      expect(find.text("Couldn't load your dashboard"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load your dashboard"), findsNothing);
      expect(find.text('Hi, Alex'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('continue card opens the lesson without the bottom nav', (
      tester,
    ) async {
      await _launchApp(tester, HomeFixture.activeUser);
      await tester.tap(find.text('Start lesson'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      await tester.tap(find.byTooltip('Close lesson'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testWidgets('new user starts the recommended lesson', (tester) async {
      await _launchApp(tester, HomeFixture.newUser);
      await tester.tap(find.text('Start lesson'));
      await tester.pumpAndSettle();
      final lesson = tester.widget<LessonScreen>(find.byType(LessonScreen));
      expect(lesson.lessonId, 'u2-l1');
    });

    testWidgets('review card opens review', (tester) async {
      await _launchApp(tester, HomeFixture.activeUser);
      await tester.tap(find.text('12 saved mistakes'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
    });

    testWidgets('bell opens notifications', (tester) async {
      await _launchApp(tester, HomeFixture.newUser);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('skill card opens Practice with that skill selected', (
      tester,
    ) async {
      await _launchApp(tester, HomeFixture.activeUser);
      await tester.scrollUntilVisible(
        find.text('READING'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('READING'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('READING'));
      await tester.pumpAndSettle();

      final practice = tester.widget<PracticeScreen>(
        find.byType(PracticeScreen),
      );
      expect(practice.initialSkill, Skill.reading);
      expect(find.text('Reading practice'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
    });
  });

  testWidgets('gallery switch changes the Home fixture', (tester) async {
    final container = ProviderContainer(
      overrides: [todayProvider.overrideWithValue(_today)],
    );
    addTearDown(container.dispose);
    // Live progress by default.
    expect(container.read(homeFixtureProvider), isNull);
    container.read(homeFixtureProvider.notifier).select(HomeFixture.activeUser);
    final repo = container.read(homeRepositoryProvider) as MockHomeRepository;
    expect(repo.fixture, HomeFixture.activeUser);
  });

  group('WeeklyActivity', () {
    WeeklyActivity build(DateTime today) => WeeklyActivity.build(
      today: today,
      minutesToday: 10,
      minutesByDay: {DateTime(2026, 10, 12): 30, DateTime(2026, 10, 5): 99},
      dailyGoal: 20,
    );

    test('Monday: only today counts, six planned days', () {
      final week = build(DateTime(2026, 10, 12));
      expect(week.bars.first.kind, DayKind.today);
      expect(week.bars.where((b) => b.isPlanned), hasLength(6));
      expect(week.totalMinutes, 10);
    });

    test('Sunday: no planned days; last week is excluded', () {
      final week = build(DateTime(2026, 10, 18));
      expect(week.bars.map((b) => b.date.weekday), [1, 2, 3, 4, 5, 6, 7]);
      expect(week.bars.where((b) => b.isPlanned), isEmpty);
      expect(week.totalMinutes, 40);
      expect(week.goalDays, 1);
    });

    test('formats study time', () {
      expect(formatStudyTime(45), '45 min');
      expect(formatStudyTime(60), '1h');
      expect(formatStudyTime(246), '4h 6m');
    });
  });
}

class _FakeRepository implements HomeRepository {
  _FakeRepository(this._fetch);

  final Future<HomeSummary> Function() _fetch;

  @override
  Future<HomeSummary> fetchSummary() => _fetch();
}
