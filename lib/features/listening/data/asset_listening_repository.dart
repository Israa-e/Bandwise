import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/listening.dart';
import '../domain/listening_repository.dart';

/// Reads the sets bundled in `assets/listening/<id>/`: script.json,
/// questions.json, and timestamps.json once the audio is built (see
/// tool/build_listening_audio.dart).
class AssetListeningRepository implements ListeningRepository {
  const AssetListeningRepository({this.bundle, this.setIds = ids});

  static const ids = ['set_a', 'set_b'];

  /// Defaults to [rootBundle].
  final AssetBundle? bundle;
  final List<String> setIds;

  @override
  Future<List<ListeningSet>> fetchSets() =>
      Future.wait([for (final id in setIds) _load(id)]);

  Future<ListeningSet> _load(String id) async {
    final dir = 'assets/listening/$id';
    final script = await _json('$dir/script.json');
    final questions = await _json('$dir/questions.json');
    Map<String, dynamic>? timestamps;
    try {
      timestamps = await _json('$dir/timestamps.json');
    } on FlutterError {
      // Not built yet: the set is listed without audio.
    }
    return parseListeningSet(
      script: script,
      questions: questions,
      timestamps: timestamps,
      audioAsset: '$dir/listening.mp3',
    );
  }

  /// Not cached: the files are small and read once per app run, and a
  /// cached load can outlive the zone it started in (as in tests).
  Future<Map<String, dynamic>> _json(String path) async =>
      jsonDecode(await (bundle ?? rootBundle).loadString(path, cache: false))
          as Map<String, dynamic>;
}

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) =>
    (json[key] as List? ?? const []).cast<Map<String, dynamic>>();

/// Builds a set from its JSON files. Question ids are prefixed with the set
/// id so they are unique across the app.
ListeningSet parseListeningSet({
  required Map<String, dynamic> script,
  required Map<String, dynamic> questions,
  Map<String, dynamic>? timestamps,
  required String audioAsset,
}) {
  final setId = script['setId'] as String;
  return ListeningSet(
    id: setId,
    title: script['title'] as String,
    part: script['part'] as int,
    context: script['context'] as String,
    audioAsset: audioAsset,
    speakers: [
      for (final s in _list(script, 'speakers'))
        ListeningSpeaker(
          id: s['id'] as String,
          name: s['name'] as String,
          role: s['role'] as String,
        ),
    ],
    lines: [
      for (final l in _list(script, 'lines'))
        TranscriptLine(
          id: l['id'] as String,
          speakerId: l['speaker'] as String,
          text: l['text'] as String,
        ),
    ],
    groups: [
      for (final g in _list(questions, 'groups'))
        QuestionGroup(
          first: g['from'] as int,
          last: g['to'] as int,
          instructions: g['instructions'] as String,
          heading: g['heading'] as String,
          readingTimeAfterLineId: g['readingTimeAfterLineId'] as String,
          readingTime: Duration(milliseconds: g['readingTimeMs'] as int),
        ),
    ],
    questions: [
      for (final q in _list(questions, 'questions'))
        ListeningQuestion(
          id: '$setId:${q['id']}',
          number: q['number'] as int,
          type: ListeningQuestionType.values.byName(q['type'] as String),
          prompt: q['prompt'] as String,
          options: [
            for (final o in _list(q, 'options'))
              ListeningOption(o['key'] as String, o['text'] as String),
          ],
          answer: q['answer'] as String,
          variants: (q['acceptedVariants'] as List? ?? const []).cast<String>(),
          wordLimit: switch (q['wordLimit']) {
            final Map<String, dynamic> w => WordLimit(
              maxWords: w['maxWords'] as int,
              maxNumbers: w['maxNumbers'] as int,
              label: w['label'] as String,
            ),
            _ => null,
          },
          explanation: q['explanation'] as String,
          evidence: q['evidence'] as String,
          evidenceLineId: q['evidenceLineId'] as String,
        ),
    ],
    timings: {
      if (timestamps != null)
        for (final t in _list(timestamps, 'lines'))
          t['id'] as String: LineTiming(
            Duration(milliseconds: t['startMs'] as int),
            Duration(milliseconds: t['endMs'] as int),
          ),
    },
  );
}
