import '../../../core/models/skill.dart';
import '../../../core/utils/dates.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Sample learners for the mock repository. Debug-only overrides of the
/// live progress (see the component gallery).
enum HomeFixture {
  /// Day 1: no streak, no XP, no activity, no reviews due.
  newUser('New user'),

  /// A few weeks in, with a 14-day streak and practice in every skill.
  activeUser('Active user');

  const HomeFixture(this.label);

  final String label;
}

/// In-memory Home data. History is generated relative to [today], so the
/// streak and weekly chart always line up with the current date.
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository({
    required this.fixture,
    required this.today,
    this.delay = const Duration(milliseconds: 400),
  });

  final HomeFixture fixture;
  final DateTime today;

  /// Simulated network latency.
  final Duration delay;

  @override
  Future<HomeSummary> fetchSummary() async {
    await Future<void>.delayed(delay);
    return switch (fixture) {
      HomeFixture.newUser => _newUser,
      HomeFixture.activeUser => _activeUser(dateOnly(today)),
    };
  }
}

const _newUser = HomeSummary(
  displayName: 'Sam Carter',
  streakDays: 0,
  totalXp: 0,
  xpToday: 0,
  minutesToday: 0,
  hasCompletedLessons: false,
  nextLesson: null,
  reviewsDue: 0,
  skills: {},
  minutesByDay: {},
);

/// Minutes studied on the days before today, most recent first. Every day of
/// the streak has some study time.
const _recentMinutes = [35, 50, 45, 60, 25, 40, 30, 20, 45, 35, 25, 30, 40];

HomeSummary _activeUser(DateTime today) {
  DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
  return HomeSummary(
    displayName: 'Alex Morgan',
    // The days above plus today.
    streakDays: _recentMinutes.length + 1,
    totalXp: 1240,
    xpToday: 45,
    minutesToday: 15,
    hasCompletedLessons: true,
    nextLesson: const NextLesson(
      id: 'u3-l4',
      unit: 3,
      unitTitle: 'Paraphrasing and argument structure',
      label: 'Lesson 4',
      title: 'Building a clear main argument',
      unitProgress: 0.5,
      estimatedMinutes: 10,
    ),
    reviewsDue: 12,
    skills: {
      Skill.listening: SkillActivity(
        attempts: 12,
        correctAnswers: 88,
        totalAnswers: 100,
        thisWeek: 3,
        lastPracticed: daysAgo(1),
      ),
      Skill.reading: SkillActivity(
        attempts: 9,
        correctAnswers: 74,
        totalAnswers: 100,
        thisWeek: 2,
        lastPracticed: daysAgo(2),
      ),
      Skill.writing: SkillActivity(
        attempts: 5,
        thisWeek: 2,
        lastPracticed: daysAgo(1),
      ),
      Skill.speaking: SkillActivity(attempts: 3, lastPracticed: daysAgo(9)),
    },
    minutesByDay: {
      for (var i = 0; i < _recentMinutes.length; i++)
        daysAgo(i + 1): _recentMinutes[i],
    },
  );
}
