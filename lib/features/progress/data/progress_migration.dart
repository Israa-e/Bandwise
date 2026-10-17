import '../../learn/domain/course.dart';
import '../domain/progress_state.dart';

/// Brings saved progress JSON up to [ProgressState.schemaVersion].
///
/// Version 1 (no `version` field) keyed mistakes and review schedules by
/// the question's prompt or the flashcard's word. Version 2 keys them by
/// the exercise's stable id. Mistakes and schedules whose exercise can't be
/// found any more are dropped, since they can't be reviewed.
Map<String, dynamic> migrateProgressJson(
  Map<String, dynamic> json,
  Course course,
) {
  final version = json['version'] as int? ?? 1;
  if (version >= ProgressState.schemaVersion) return json;
  return _v1ToV2(json, course);
}

Map<String, dynamic> _v1ToV2(Map<String, dynamic> json, Course course) {
  String? questionId(String lessonId, String prompt) => course
      .lessonById(lessonId)
      ?.exercises
      .whereType<QuestionExercise>()
      .where((q) => q.savedPrompt == prompt)
      .firstOrNull
      ?.id;

  String? flashcardId(String lessonId, String word) => course
      .lessonById(lessonId)
      ?.exercises
      .whereType<FlashcardExercise>()
      .where((f) => f.word == word)
      .firstOrNull
      ?.id;

  final mistakes = [
    for (final raw in json['mistakes'] as List? ?? const [])
      if (raw case {
        'lessonId': final String lessonId,
        'prompt': final String prompt,
      })
        if (questionId(lessonId, prompt) case final id?)
          {
            ...(raw as Map<String, dynamic>),
            'source': MistakeSource.lesson.name,
            'sourceId': lessonId,
            'itemId': id,
          }..remove('lessonId'),
  ];

  final reviews = <String, dynamic>{};
  for (final MapEntry(:key, :value)
      in (json['reviews'] as Map<String, dynamic>? ?? const {}).entries) {
    // "mistake:<lessonId>:<prompt>" or "word:<lessonId>:<word>". Lesson ids
    // have no colons; prompts may.
    final parts = key.split(':');
    if (parts.length < 3) continue;
    final lessonId = parts[1];
    final rest = parts.sublist(2).join(':');
    final newKey = switch (parts.first) {
      'mistake' => switch (questionId(lessonId, rest)) {
        final id? => mistakeReviewKey(id),
        null => null,
      },
      'word' => switch (flashcardId(lessonId, rest)) {
        final id? => wordReviewKey(id),
        null => null,
      },
      _ => null,
    };
    if (newKey != null) reviews[newKey] = value;
  }

  final xpLog = [
    for (final raw in json['xpLog'] as List? ?? const [])
      if (raw case {'lessonId': final String lessonId})
        {...(raw as Map<String, dynamic>), 'source': lessonId}
          ..remove('lessonId')
      else
        raw,
  ];

  return {
    ...json,
    'version': 2,
    'mistakes': mistakes,
    'reviews': reviews,
    'xpLog': xpLog,
  };
}
