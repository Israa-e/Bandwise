import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/learn/domain/course.dart';
import 'package:bandwise/features/profile/domain/achievements.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/progress/domain/review_schedule.dart';
import 'package:bandwise/features/progress/domain/skill_insights.dart';
import 'package:bandwise/features/reading/data/reading_content.dart';
import 'package:bandwise/features/reading/domain/reading.dart';
import 'package:bandwise/features/review/domain/review_planner.dart';
import 'package:bandwise/features/writing/data/mock_writing_feedback_service.dart';
import 'package:bandwise/features/writing/data/writing_content.dart';
import 'package:bandwise/features/writing/domain/writing.dart';
import 'package:bandwise/features/writing/domain/writing_feedback.dart';
import 'package:bandwise/features/writing/domain/writing_submission.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _day(int offset) => DateTime(2026, 10, 15 + offset);

LessonCompletion _lesson(String id, DateTime date) {
  final lesson = course.lessonById(id)!;
  return LessonCompletion(
    lessonId: id,
    date: date,
    correctFirstTry: lesson.questionCount,
    questionCount: lesson.questionCount,
    minutes: 5,
    mistakes: const [],
  );
}

ReadingCompletion _reading(
  DateTime date, {
  required Map<ReadingQuestionType, (int, int)> byType,
  String? questionType,
  String passageId = 'uhi',
}) {
  final correct = byType.values.fold(0, (s, v) => s + v.$1);
  final total = byType.values.fold(0, (s, v) => s + v.$2);
  return ReadingCompletion(
    attempt: ReadingAttempt(
      passageId: passageId,
      timed: questionType == null,
      date: date,
      correct: correct,
      total: total,
      minutes: 10,
      xp: XpRules.forReading(correct: correct, timedPassage: false),
      questionType: questionType,
      byType: {
        for (final e in byType.entries)
          e.key.name: TypeScore(correct: e.value.$1, total: e.value.$2),
      },
    ),
    questionIds: const [],
    mistakes: const [],
  );
}

WritingSubmission _essay(
  String id,
  WritingTask task,
  DateTime at, {
  String? revisionOf,
  WritingResult? result,
}) => WritingSubmission(
  id: id,
  taskId: task.id,
  mode: WritingMode.learning,
  text: task.sampleEssay,
  timeUsed: const Duration(minutes: 20),
  submittedAt: at,
  revisionOf: revisionOf,
  result: result,
);

DateTime? _earned(
  AchievementKind kind,
  ProgressState progress, [
  List<WritingSubmission> essays = const [],
]) => achievementsFor(
  progress,
  essays,
).firstWhere((a) => a.kind == kind).earnedOn;

ProgressState _review(ProgressState s, DateTime day, int times) {
  for (var i = 0; i < times; i++) {
    s = s.withReview(
      ReviewCompletion(
        key: wordReviewKey('word-${day.day}-$i'),
        rating: ReviewRating.good,
        date: day,
      ),
    );
  }
  return s;
}

void main() {
  group('achievements', () {
    test('a new learner has none', () {
      final badges = achievementsFor(const ProgressState(), const []);
      expect(badges, hasLength(8));
      expect(badges.where((b) => b.unlocked), isEmpty);
    });

    test('First lesson: the day the first lesson was finished, even after '
        'a replay', () {
      var p = const ProgressState();
      expect(_earned(AchievementKind.firstLesson, p), isNull);
      p = p.withCompletedLesson(_lesson('u1-l1', _day(0)));
      expect(_earned(AchievementKind.firstLesson, p), _day(0));
      // Replaying replaces the result's date; the badge keeps the first.
      p = p.withCompletedLesson(_lesson('u1-l1', _day(3)));
      expect(_earned(AchievementKind.firstLesson, p), _day(0));
    });

    test('3- and 7-day streaks unlock on the day the run reaches them', () {
      var p = const ProgressState();
      for (final d in [0, 1]) {
        p = p.withWritingSubmission(
          date: _day(d),
          minutes: 1,
          xp: 0,
          submissionId: 's$d',
        );
      }
      expect(_earned(AchievementKind.streak3, p), isNull);
      // A gap restarts the run.
      p = p.withWritingSubmission(
        date: _day(3),
        minutes: 1,
        xp: 0,
        submissionId: 's3',
      );
      expect(_earned(AchievementKind.streak3, p), isNull);
      for (final d in [4, 5]) {
        p = p.withWritingSubmission(
          date: _day(d),
          minutes: 1,
          xp: 0,
          submissionId: 's$d',
        );
      }
      expect(_earned(AchievementKind.streak3, p), _day(5));
      expect(_earned(AchievementKind.streak7, p), isNull);
      for (final d in [6, 7, 8, 9]) {
        p = p.withWritingSubmission(
          date: _day(d),
          minutes: 1,
          xp: 0,
          submissionId: 's$d',
        );
      }
      expect(_earned(AchievementKind.streak7, p), _day(9));
      expect(p.longestStreak, 7);
    });

    test('50 reviews: locked at 49, earned on the day of the 50th', () {
      var p = _review(const ProgressState(), _day(0), 30);
      p = _review(p, _day(1), 19);
      expect(p.reviewCount, 49);
      expect(_earned(AchievementKind.reviews50, p), isNull);
      p = _review(p, _day(2), 1);
      expect(_earned(AchievementKind.reviews50, p), _day(2));
    });

    test('reading badges: any attempt, then a full passage all correct', () {
      var p = const ProgressState().withReadingAttempt(
        _reading(
          _day(0),
          byType: {ReadingQuestionType.trueFalseNotGiven: (3, 3)},
          questionType: ReadingQuestionType.trueFalseNotGiven.name,
        ),
      );
      expect(_earned(AchievementKind.firstReading, p), _day(0));
      // All correct, but only one question type: not a full passage.
      expect(_earned(AchievementKind.perfectPassage, p), isNull);
      p = p.withReadingAttempt(
        _reading(
          _day(1),
          byType: {
            ReadingQuestionType.trueFalseNotGiven: (4, 4),
            ReadingQuestionType.multipleChoice: (5, 6),
          },
        ),
      );
      expect(_earned(AchievementKind.perfectPassage, p), isNull);
      p = p.withReadingAttempt(
        _reading(
          _day(2),
          byType: {
            ReadingQuestionType.trueFalseNotGiven: (4, 4),
            ReadingQuestionType.multipleChoice: (6, 6),
          },
        ),
      );
      expect(_earned(AchievementKind.perfectPassage, p), _day(2));
    });

    test('essay badges: first new essay, then first revision', () {
      const p = ProgressState();
      final first = _essay(
        'a',
        cyclingTask,
        _day(0).add(const Duration(hours: 9)),
      );
      expect(_earned(AchievementKind.firstEssay, p, [first]), _day(0));
      expect(_earned(AchievementKind.firstRevision, p, [first]), isNull);
      final revision = _essay('b', cyclingTask, _day(2), revisionOf: 'a');
      expect(
        _earned(AchievementKind.firstRevision, p, [first, revision]),
        _day(2),
      );
    });

    test('badges give no XP', () {
      final p = const ProgressState().withCompletedLesson(
        _lesson('u1-l1', _day(0)),
      );
      final before = p.totalXp;
      achievementsFor(p, const []);
      expect(p.totalXp, before);
    });
  });

  group('reading insights', () {
    test('accuracy by type, the last 5 attempts, and the weakest type', () {
      var p = const ProgressState();
      // An old attempt with weak multiple choice: outside the last five.
      p = p.withReadingAttempt(
        _reading(_day(0), byType: {ReadingQuestionType.multipleChoice: (0, 4)}),
      );
      for (var i = 1; i <= 5; i++) {
        p = p.withReadingAttempt(
          _reading(
            _day(i),
            byType: {
              ReadingQuestionType.trueFalseNotGiven: (1, 3),
              ReadingQuestionType.multipleChoice: (3, 3),
            },
          ),
        );
      }
      final insights = ReadingInsights.from(p.readingAttempts);
      expect(insights.attempts, 6);
      expect(insights.recent, hasLength(5));
      expect(insights.recent.first.date, _day(1));
      expect(insights.recent.map((r) => r.percent).toSet(), {67});
      expect(insights.byType[ReadingQuestionType.multipleChoice]!.correct, 15);
      expect(insights.byType[ReadingQuestionType.multipleChoice]!.total, 19);
      // Recent answers decide: TFNG at 33%, multiple choice perfect.
      expect(insights.weakestType, ReadingQuestionType.trueFalseNotGiven);
    });

    test('no weakest type when everything recent is correct', () {
      final p = const ProgressState().withReadingAttempt(
        _reading(
          _day(0),
          byType: {ReadingQuestionType.matchingHeadings: (5, 5)},
        ),
      );
      expect(ReadingInsights.from(p.readingAttempts).weakestType, isNull);
    });
  });

  group('writing insights', () {
    test('estimates per task, "no estimate" for demo, the top note type', () {
      final feedback = buildSampleFeedback(
        cyclingTask,
        sampleFeedback[cyclingTask.id]!,
        cyclingTask.sampleEssay,
        _day(0),
      );
      final insights = WritingInsights.from([
        _essay('a', cyclingTask, _day(0), result: AnalysedResult(feedback)),
        _essay(
          'b',
          cyclingTask,
          _day(1),
          revisionOf: 'a',
          result: const DemoResult(),
        ),
        _essay('c', universitiesTask, _day(1), result: const DemoResult()),
      ], writingTasks);
      final task1 = insights.byType[WritingTaskType.task1]!;
      expect(task1.essays, 1);
      expect(task1.revisions, 1);
      // The revision got demo feedback, so the latest estimate is the
      // earlier one.
      expect(task1.latestEstimate, feedback.overall);
      expect(task1.latestEstimateOn, _day(0));
      final task2 = insights.byType[WritingTaskType.task2]!;
      expect(task2.essays, 1);
      expect(task2.latestEstimate, isNull);

      final counts = <AnnotationType, int>{};
      for (final a in feedback.annotations) {
        counts[a.type] = (counts[a.type] ?? 0) + 1;
      }
      final most = counts.values.reduce((a, b) => a > b ? a : b);
      expect(counts[insights.topNoteType], most);
    });
  });

  group('review queue', () {
    test('a removed word leaves the queue but stays in the items', () {
      final lesson = course.lessonById('u1-l1')!;
      final word = lesson.exercises.whereType<FlashcardExercise>().first;
      final key = wordReviewKey(word.id);
      var p = const ProgressState().withCompletedLesson(
        _lesson('u1-l1', _day(-1)),
      );
      ReviewPlanner planner(ProgressState p) =>
          ReviewPlanner(course: course, progress: p, passages: readingPassages);
      expect(planner(p).dueOn(_day(0)).map((i) => i.key), contains(key));

      p = p.withReviewRemoved(key, removed: true);
      expect(planner(p).dueOn(_day(0)).map((i) => i.key), isNot(contains(key)));
      expect(planner(p).items.map((i) => i.key), contains(key));
      expect(ProgressState.fromJson(p.toJson()).removedFromReview, {key});

      p = p.withReviewRemoved(key, removed: false);
      expect(planner(p).dueOn(_day(0)).map((i) => i.key), contains(key));
    });

    test('review counts and removals survive saving', () {
      var p = _review(const ProgressState(), _day(0), 3);
      p = p.withReviewRemoved('word:x', removed: true);
      final back = ProgressState.fromJson(p.toJson());
      expect(back.reviewCount, 3);
      expect(back.reviewsByDay[_day(0)], 3);
      expect(back.removedFromReview, {'word:x'});
    });
  });
}
