import 'package:flutter/foundation.dart';

import '../../../core/utils/dates.dart';

/// How well the learner remembered a review item.
enum ReviewRating {
  /// Forgotten: shown again in the same session.
  again('Again'),
  hard('Hard'),
  good('Good'),
  easy('Easy');

  const ReviewRating(this.label);

  final String label;

  /// Good and Easy mean the item is remembered.
  bool get isRemembered => this == good || this == easy;
}

/// When a review item is next due. Simple spaced repetition:
/// Again → today, Hard → 1 day, Good → 3 days, Easy → 7 days. After an
/// earlier Good or Easy, Good and Easy double the previous interval instead
/// (never going below their base interval).
@immutable
class ReviewSchedule {
  const ReviewSchedule({
    required this.dueOn,
    required this.intervalDays,
    required this.lastRating,
  });

  static const hardDays = 1;
  static const goodDays = 3;
  static const easyDays = 7;

  /// Local, date-only.
  final DateTime dueOn;
  final int intervalDays;
  final ReviewRating lastRating;

  /// The schedule after rating an item [rating] on [today]. [previous] is
  /// null for an item that hasn't been reviewed yet.
  static ReviewSchedule next(
    ReviewSchedule? previous,
    ReviewRating rating,
    DateTime today,
  ) {
    final growing = previous != null && previous.lastRating.isRemembered;
    int grow(int base) => growing && previous.intervalDays * 2 > base
        ? previous.intervalDays * 2
        : base;
    final days = switch (rating) {
      ReviewRating.again => 0,
      ReviewRating.hard => hardDays,
      ReviewRating.good => grow(goodDays),
      ReviewRating.easy => grow(easyDays),
    };
    return ReviewSchedule(
      dueOn: addDays(today, days),
      intervalDays: days,
      lastRating: rating,
    );
  }

  Map<String, dynamic> toJson() => {
    'dueOn': formatIsoDay(dueOn),
    'intervalDays': intervalDays,
    'lastRating': lastRating.name,
  };

  static ReviewSchedule fromJson(Map<String, dynamic> json) => ReviewSchedule(
    dueOn: parseIsoDay(json['dueOn'] as String),
    intervalDays: json['intervalDays'] as int,
    lastRating: ReviewRating.values.byName(json['lastRating'] as String),
  );
}
