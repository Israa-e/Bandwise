import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/speaking.dart';
import '../domain/speaking_repository.dart';

/// Reads assets/speaking/content.json.
class AssetSpeakingContentRepository implements SpeakingContentRepository {
  const AssetSpeakingContentRepository({this.bundle});

  /// Defaults to [rootBundle].
  final AssetBundle? bundle;

  /// Not cached: a cached load can outlive the zone it started in (as in
  /// tests).
  @override
  Future<SpeakingContent> fetchContent() async => parseSpeakingContent(
    jsonDecode(
          await (bundle ?? rootBundle).loadString(
            'assets/speaking/content.json',
            cache: false,
          ),
        )
        as Map<String, dynamic>,
  );
}

SpeakingContent parseSpeakingContent(Map<String, dynamic> json) {
  ExaminerLine line(Object? v) {
    final m = v as Map<String, dynamic>;
    return ExaminerLine(id: m['id'] as String, text: m['text'] as String);
  }

  List<SpeakingQuestion> questions(Object? v, SpeakingPart part) => [
    for (final q in (v as List).cast<Map<String, dynamic>>())
      SpeakingQuestion(
        id: q['id'] as String,
        text: q['text'] as String,
        part: part,
      ),
  ];

  return SpeakingContent(
    examiner: {
      for (final l in json['examiner'] as List)
        (l as Map<String, dynamic>)['id'] as String: line(l),
    },
    part1: [
      for (final t in (json['part1'] as List).cast<Map<String, dynamic>>())
        Part1Topic(
          id: t['id'] as String,
          title: t['title'] as String,
          intro: line(t['intro']),
          questions: questions(t['questions'], SpeakingPart.part1),
        ),
    ],
    cueCards: [
      for (final c in (json['part2'] as List).cast<Map<String, dynamic>>())
        CueCard(
          id: c['id'] as String,
          title: c['title'] as String,
          topic: line(c['topic']),
          prompt: c['prompt'] as String,
          bullets: (c['bullets'] as List).cast<String>(),
          explain: c['explain'] as String,
          roundingOff: questions([c['roundingOff']], SpeakingPart.part2).single,
          part3Title: (c['part3'] as Map<String, dynamic>)['title'] as String,
          part3Intro: line((c['part3'] as Map<String, dynamic>)['intro']),
          part3Questions: questions(
            (c['part3'] as Map<String, dynamic>)['questions'],
            SpeakingPart.part3,
          ),
        ),
    ],
  );
}
