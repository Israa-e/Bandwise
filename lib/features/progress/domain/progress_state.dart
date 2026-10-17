import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';
import 'review_schedule.dart';

/// XP rules.
abstract final class XpRules {
  static const perLesson = 10;
  static const perFirstTryCorrect = 2;

  /// Per reviewed item, up to [maxReviewPerDay] a day, so reviews can't be
  /// farmed for XP.
  static const perReview = 1;
  static const maxReviewPerDay = 10;

  /// Reading practice: per correct answer, plus a bonus for finishing a
  /// full passage in timed mode.
  static const perReadingCorrect = 2;
  static const timedPassageBonus = 10;

  static int forLesson(int correctFirstTry) =>
      perLesson + perFirstTryCorrect * correctFirstTry;

  static int forReading({required int correct, required bool timedPassage}) =>
      perReadingCorrect * correct + (timedPassage ? timedPassageBonus : 0);
}

/// The learner's saved history. Dates are local, date-only.
@immutable
class ProgressState {
  const ProgressState({
    this.results = const {},
    this.xpLog = const [],
    this.minutesByDay = const {},
    this.activeDays = const {},
    this.mistakes = const [],
    this.reviews = const {},
    this.readingAttempts = const [],
  });

  /// Latest result per completed lesson id.
  final Map<String, LessonResult> results;
  final List<XpEntry> xpLog;
  final Map<DateTime, int> minutesByDay;

  /// Days with at least one completed activity (streak days).
  final Set<DateTime> activeDays;

  /// Wrong answers saved for review.
  final List<SavedMistake> mistakes;

  /// Spaced-repetition schedule per reviewed item, by review key (see
  /// [SavedMistake.reviewKey] and [wordReviewKey]). Items not reviewed yet
  /// have no entry.
  final Map<String, ReviewSchedule> reviews;

  /// Finished reading practice, oldest first.
  final List<ReadingAttempt> readingAttempts;

  ProgressState _copyWith({
    Map<String, LessonResult>? results,
    List<XpEntry>? xpLog,
    Map<DateTime, int>? minutesByDay,
    Set<DateTime>? activeDays,
    List<SavedMistake>? mistakes,
    Map<String, ReviewSchedule>? reviews,
    List<ReadingAttempt>? readingAttempts,
  }) => ProgressState(
    results: results ?? this.results,
    xpLog: xpLog ?? this.xpLog,
    minutesByDay: minutesByDay ?? this.minutesByDay,
    activeDays: activeDays ?? this.activeDays,
    mistakes: mistakes ?? this.mistakes,
    reviews: reviews ?? this.reviews,
    readingAttempts: readingAttempts ?? this.readingAttempts,
  );

  bool isCompleted(String lessonId) => results.containsKey(lessonId);

  int get totalXp => xpLog.fold(0, (sum, e) => sum + e.amount);

  int xpOn(DateTime day) => xpLog
      .where((e) => e.date == dateOnly(day))
      .fold(0, (sum, e) => sum + e.amount);

  int minutesOn(DateTime day) => minutesByDay[dateOnly(day)] ?? 0;

  /// Mistakes saved from lesson [lessonId].
  List<SavedMistake> mistakesFor(String lessonId) => [
    for (final m in mistakes)
      if (m.source == MistakeSource.lesson && m.sourceId == lessonId) m,
  ];

  /// [lessonId]'s mistakes not yet rated Good or Easy in a review. The lesson
  /// needs review while this isn't empty.
  List<SavedMistake> openMistakesFor(String lessonId) => [
    for (final m in mistakesFor(lessonId))
      if (!(reviews[m.reviewKey]?.lastRating.isRemembered ?? false)) m,
  ];

  /// XP earned from reviews on [day].
  int reviewXpOn(DateTime day) => xpLog
      .where((e) => e.source == XpEntry.reviewSource && e.date == dateOnly(day))
      .fold(0, (sum, e) => sum + e.amount);

  /// XP a review rated [rating] on [day] would earn: [XpRules.perReview]
  /// unless the item must be seen again, or the daily cap is reached.
  int reviewXpFor(ReviewRating rating, DateTime day) {
    if (rating == ReviewRating.again) return 0;
    final left = XpRules.maxReviewPerDay - reviewXpOn(day);
    return left <= 0 ? 0 : XpRules.perReview.clamp(0, left);
  }

  /// Consecutive active days ending today, or yesterday if today has no
  /// activity yet (the streak is still alive until today ends).
  int streak(DateTime today) {
    final day = dateOnly(today);
    var cursor = activeDays.contains(day)
        ? day
        : DateTime(day.year, day.month, day.day - 1);
    var count = 0;
    while (activeDays.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// Records a finished lesson. Replaying a lesson replaces its result and
  /// its saved mistakes, and earns XP again.
  ProgressState withCompletedLesson(LessonCompletion c) {
    final day = dateOnly(c.date);
    final oldMistakeKeys = {
      for (final m in mistakesFor(c.lessonId)) m.reviewKey,
    };
    return ProgressState(
      results: {
        ...results,
        c.lessonId: LessonResult(
          correct: c.correctFirstTry,
          total: c.questionCount,
          xp: c.xp,
          completedOn: day,
        ),
      },
      xpLog: [
        ...xpLog,
        XpEntry(date: day, amount: c.xp, source: c.lessonId),
      ],
      minutesByDay: {...minutesByDay, day: minutesOn(day) + c.minutes},
      activeDays: {...activeDays, day},
      mistakes: [
        ...mistakes.where((m) => !oldMistakeKeys.contains(m.reviewKey)),
        ...c.mistakes,
      ],
      // The new mistakes start their reviews from scratch.
      reviews: {
        for (final e in reviews.entries)
          if (!oldMistakeKeys.contains(e.key)) e.key: e.value,
      },
      readingAttempts: readingAttempts,
    );
  }

  /// Records finished reading practice: the attempt, XP, minutes, a streak
  /// day, and the wrong answers as mistakes to review. Mistakes saved
  /// earlier for the questions practised are replaced, and start their
  /// reviews from scratch.
  ProgressState withReadingAttempt(ReadingCompletion c) {
    final day = dateOnly(c.attempt.date);
    final replaced = {for (final id in c.questionIds) mistakeReviewKey(id)};
    return _copyWith(
      readingAttempts: [...readingAttempts, c.attempt],
      xpLog: c.attempt.xp == 0
          ? null
          : [
              ...xpLog,
              XpEntry(
                date: day,
                amount: c.attempt.xp,
                source: 'reading:${c.attempt.passageId}',
              ),
            ],
      minutesByDay: {...minutesByDay, day: minutesOn(day) + c.attempt.minutes},
      activeDays: {...activeDays, day},
      mistakes: [
        ...mistakes.where((m) => !replaced.contains(m.reviewKey)),
        ...c.mistakes,
      ],
      reviews: {
        for (final e in reviews.entries)
          if (!replaced.contains(e.key)) e.key: e.value,
      },
    );
  }

  /// Records one reviewed item: its next due date, XP (capped per day),
  /// study minutes and a streak day.
  ProgressState withReview(ReviewCompletion r) {
    final day = dateOnly(r.date);
    final xp = reviewXpFor(r.rating, day);
    return _copyWith(
      reviews: {
        ...reviews,
        r.key: ReviewSchedule.next(reviews[r.key], r.rating, day),
      },
      xpLog: xp == 0
          ? null
          : [
              ...xpLog,
              XpEntry(date: day, amount: xp, source: XpEntry.reviewSource),
            ],
      minutesByDay: r.minutes == 0
          ? null
          : {...minutesByDay, day: minutesOn(day) + r.minutes},
      activeDays: {...activeDays, day},
    );
  }

  /// Bumped when the saved format changes; see the progress migration.
  static const schemaVersion = 2;

  Map<String, dynamic> toJson() => {
    'version': schemaVersion,
    'results': {for (final e in results.entries) e.key: e.value.toJson()},
    'xpLog': [for (final e in xpLog) e.toJson()],
    'minutesByDay': {
      for (final e in minutesByDay.entries) formatIsoDay(e.key): e.value,
    },
    'activeDays': [for (final d in activeDays) formatIsoDay(d)],
    'mistakes': [for (final m in mistakes) m.toJson()],
    'reviews': {for (final e in reviews.entries) e.key: e.value.toJson()},
    'readingAttempts': [for (final a in readingAttempts) a.toJson()],
  };

  static ProgressState fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>? ?? {};
    final minutes = json['minutesByDay'] as Map<String, dynamic>? ?? {};
    final reviews = json['reviews'] as Map<String, dynamic>? ?? {};
    return ProgressState(
      results: {
        for (final e in results.entries)
          e.key: LessonResult.fromJson(e.value as Map<String, dynamic>),
      },
      xpLog: [
        for (final e in json['xpLog'] as List? ?? const [])
          XpEntry.fromJson(e as Map<String, dynamic>),
      ],
      minutesByDay: {
        for (final e in minutes.entries) parseIsoDay(e.key): e.value as int,
      },
      activeDays: {
        for (final d in json['activeDays'] as List? ?? const [])
          parseIsoDay(d as String),
      },
      mistakes: [
        for (final m in json['mistakes'] as List? ?? const [])
          SavedMistake.fromJson(m as Map<String, dynamic>),
      ],
      reviews: {
        for (final e in reviews.entries)
          e.key: ReviewSchedule.fromJson(e.value as Map<String, dynamic>),
      },
      readingAttempts: [
        for (final a in json['readingAttempts'] as List? ?? const [])
          ReadingAttempt.fromJson(a as Map<String, dynamic>),
      ],
    );
  }
}

@immutable
class LessonResult {
  const LessonResult({
    required this.correct,
    required this.total,
    required this.xp,
    required this.completedOn,
  });

  /// Questions answered correctly on the first try.
  final int correct;
  final int total;
  final int xp;
  final DateTime completedOn;

  Map<String, dynamic> toJson() => {
    'correct': correct,
    'total': total,
    'xp': xp,
    'completedOn': formatIsoDay(completedOn),
  };

  static LessonResult fromJson(Map<String, dynamic> json) => LessonResult(
    correct: json['correct'] as int,
    total: json['total'] as int,
    xp: json['xp'] as int,
    completedOn: parseIsoDay(json['completedOn'] as String),
  );
}

@immutable
class XpEntry {
  const XpEntry({
    required this.date,
    required this.amount,
    required this.source,
  });

  /// [source] for XP earned in reviews.
  static const reviewSource = 'review';

  final DateTime date;
  final int amount;

  /// The lesson id, or [reviewSource].
  final String source;

  Map<String, dynamic> toJson() => {
    'date': formatIsoDay(date),
    'amount': amount,
    'source': source,
  };

  static XpEntry fromJson(Map<String, dynamic> json) => XpEntry(
    date: parseIsoDay(json['date'] as String),
    amount: json['amount'] as int,
    source: json['source'] as String,
  );
}

/// Where a saved mistake was made.
enum MistakeSource { lesson, reading }

/// A wrong answer kept for later review.
@immutable
class SavedMistake {
  const SavedMistake({
    this.source = MistakeSource.lesson,
    required this.sourceId,
    required this.itemId,
    required this.prompt,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.explanation,
    this.savedOn,
  });

  final MistakeSource source;

  /// The lesson or reading passage id.
  final String sourceId;

  /// The exercise or reading question id. Unique across the app.
  final String itemId;

  /// The question as it was asked, with its sentence or passage if it has
  /// one. Shown in results; reviews ask the current version by [itemId].
  final String prompt;
  final String yourAnswer;
  final String correctAnswer;
  final String explanation;

  /// The day the mistake was made; null for lesson mistakes saved before
  /// this was recorded (the lesson's completion day is used instead).
  final DateTime? savedOn;

  /// Identifies this mistake's schedule in [ProgressState.reviews].
  String get reviewKey => mistakeReviewKey(itemId);

  Map<String, dynamic> toJson() => {
    'source': source.name,
    'sourceId': sourceId,
    'itemId': itemId,
    if (savedOn case final d?) 'savedOn': formatIsoDay(d),
    'prompt': prompt,
    'yourAnswer': yourAnswer,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
  };

  static SavedMistake fromJson(Map<String, dynamic> json) => SavedMistake(
    source: MistakeSource.values.byName(json['source'] as String),
    sourceId: json['sourceId'] as String,
    itemId: json['itemId'] as String,
    savedOn: switch (json['savedOn']) {
      final String d => parseIsoDay(d),
      _ => null,
    },
    prompt: json['prompt'] as String,
    yourAnswer: json['yourAnswer'] as String,
    correctAnswer: json['correctAnswer'] as String,
    explanation: json['explanation'] as String,
  );
}

/// Everything recorded when a lesson is finished.
@immutable
class LessonCompletion {
  const LessonCompletion({
    required this.lessonId,
    required this.date,
    required this.correctFirstTry,
    required this.questionCount,
    required this.minutes,
    required this.mistakes,
  });

  final String lessonId;
  final DateTime date;
  final int correctFirstTry;
  final int questionCount;
  final int minutes;
  final List<SavedMistake> mistakes;

  int get xp => XpRules.forLesson(correctFirstTry);

  /// Whole minutes for [elapsed], rounded up (at least 1) and capped at
  /// twice the lesson's estimate.
  static int minutesFor(Duration elapsed, int estimatedMinutes) {
    final minutes = (elapsed.inSeconds / 60).ceil();
    return minutes.clamp(1, estimatedMinutes * 2);
  }
}

/// Identifies a saved mistake's schedule in [ProgressState.reviews].
String mistakeReviewKey(String itemId) => 'mistake:$itemId';

/// Identifies a flashcard word's schedule in [ProgressState.reviews].
String wordReviewKey(String exerciseId) => 'word:$exerciseId';

/// One item rated in a review session.
@immutable
class ReviewCompletion {
  const ReviewCompletion({
    required this.key,
    required this.rating,
    required this.date,
    this.minutes = 0,
  });

  final String key;
  final ReviewRating rating;
  final DateTime date;

  /// Study minutes to add for the time spent since the last recorded item.
  final int minutes;
}

/// Correct answers out of questions for one question type.
@immutable
class TypeScore {
  const TypeScore({required this.correct, required this.total});

  final int correct;
  final int total;

  Map<String, dynamic> toJson() => {'correct': correct, 'total': total};

  static TypeScore fromJson(Map<String, dynamic> json) =>
      TypeScore(correct: json['correct'] as int, total: json['total'] as int);
}

/// One finished reading practice. Raw scores only, never a band.
@immutable
class ReadingAttempt {
  const ReadingAttempt({
    required this.passageId,
    required this.timed,
    required this.date,
    required this.correct,
    required this.total,
    required this.minutes,
    required this.xp,
    this.questionType,
    this.byType = const {},
  });

  final String passageId;

  /// Timed mode (the full passage) rather than learning mode.
  final bool timed;
  final DateTime date;
  final int correct;
  final int total;
  final int minutes;
  final int xp;

  /// The one question type practised, by name; null for all types.
  final String? questionType;

  /// Scores by question type name.
  final Map<String, TypeScore> byType;

  Map<String, dynamic> toJson() => {
    'passageId': passageId,
    'timed': timed,
    'date': formatIsoDay(date),
    'correct': correct,
    'total': total,
    'minutes': minutes,
    'xp': xp,
    'questionType': ?questionType,
    'byType': {for (final e in byType.entries) e.key: e.value.toJson()},
  };

  static ReadingAttempt fromJson(Map<String, dynamic> json) => ReadingAttempt(
    passageId: json['passageId'] as String,
    timed: json['timed'] as bool,
    date: parseIsoDay(json['date'] as String),
    correct: json['correct'] as int,
    total: json['total'] as int,
    minutes: json['minutes'] as int,
    xp: json['xp'] as int,
    questionType: json['questionType'] as String?,
    byType: {
      for (final e in (json['byType'] as Map<String, dynamic>? ?? {}).entries)
        e.key: TypeScore.fromJson(e.value as Map<String, dynamic>),
    },
  );
}

/// Everything recorded when reading practice is submitted.
@immutable
class ReadingCompletion {
  const ReadingCompletion({
    required this.attempt,
    required this.questionIds,
    required this.mistakes,
  });

  final ReadingAttempt attempt;

  /// Every question practised, answered or not.
  final List<String> questionIds;

  /// Wrong or unanswered questions, saved for review.
  final List<SavedMistake> mistakes;
}
