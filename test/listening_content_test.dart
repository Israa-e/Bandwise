import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _root = 'assets/listening';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) =>
    (json[key] as List).cast<Map<String, dynamic>>();

/// Lowercases, joins spelled-out letters ("H-A-L" → "hal") and digit groups
/// ("07723 418590" → "07723418590"), so an answer can be found in a line the
/// way a listener would hear it.
String _normalise(String text) => text
    .toLowerCase()
    .replaceAllMapped(
      RegExp(r'\b[a-z](?:-[a-z])+\b'),
      (m) => m[0]!.replaceAll('-', ''),
    )
    .replaceAllMapped(RegExp(r'(\d) (?=\d)'), (m) => m[1]!);

bool _containsAnswer(String line, String answer) {
  final pattern = RegExp(
    '(?<![a-z0-9])${RegExp.escape(_normalise(answer))}(?![a-z0-9])',
  );
  return pattern.hasMatch(_normalise(line));
}

/// Counts words and numbers as IELTS does: a run of digit groups such as a
/// phone number, or "6th", is one number.
({int words, int numbers}) _countWords(String answer) {
  final numberToken = RegExp(r'^[£$]?\d[\d,.:/]*(st|nd|rd|th)?$');
  var words = 0;
  var numbers = 0;
  var previousWasNumber = false;
  for (final token in answer.trim().split(RegExp(r'\s+'))) {
    final isNumber = numberToken.hasMatch(token);
    if (isNumber && !previousWasNumber) numbers++;
    if (!isNumber) words++;
    previousWasNumber = isNumber;
  }
  return (words: words, numbers: numbers);
}

void main() {
  final sets =
      Directory(_root)
          .listSync()
          .whereType<Directory>()
          .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toList()
        ..sort();

  test('there are listening sets', () {
    expect(sets, containsAll(['set_a', 'set_b']));
  });

  test('word counting follows IELTS rules', () {
    expect(_countWords('07723 418590'), (words: 0, numbers: 1));
    expect(_countWords('6th'), (words: 0, numbers: 1));
    expect(_countWords('Thursday'), (words: 1, numbers: 0));
    expect(_countWords('6th November'), (words: 1, numbers: 1));
    expect(_containsAnswer('So, H-A-L-L-O-R-A-N.', 'Halloran'), isTrue);
    expect(_containsAnswer('the 16th of May', '6th'), isFalse);
  });

  for (final setId in sets) {
    group(setId, () {
      final dir = '$_root/$setId';
      final script = _json('$dir/script.json');
      final questionsDoc = _json('$dir/questions.json');
      final lines = _list(script, 'lines');
      final speakers = _list(script, 'speakers');
      final questions = _list(questionsDoc, 'questions');
      final lineIndex = {
        for (final (i, line) in lines.indexed) line['id'] as String: i,
      };
      String lineText(String id) => lines[lineIndex[id]!]['text'] as String;

      test('set ids match the folder', () {
        expect(script['setId'], setId);
        expect(questionsDoc['setId'], setId);
        expect(questionsDoc['part'], script['part']);
      });

      test('speakers are complete and every line has a known speaker', () {
        final ids = speakers.map((s) => s['id']).toSet();
        expect(ids.length, speakers.length, reason: 'duplicate speaker id');
        for (final s in speakers) {
          for (final key in ['id', 'name', 'role', 'accent']) {
            expect(
              s[key],
              isA<String>().having((v) => v.trim(), key, isNotEmpty),
            );
          }
          final notes = s['voiceNotes'] as Map<String, dynamic>;
          expect(notes['age'], isNotEmpty);
          expect(notes['tone'], isNotEmpty);
        }
        for (final line in lines) {
          expect(ids, contains(line['speaker']), reason: '${line['id']}');
        }
      });

      test('no line is empty, ids are unique, pauses are valid', () {
        expect(lines, isNotEmpty);
        expect(lineIndex.length, lines.length, reason: 'duplicate line id');
        for (final line in lines) {
          expect(
            line['id'],
            matches(RegExp(r'^[a-z0-9_]+$')),
            reason: 'line ids are used as file names',
          );
          expect(
            (line['text'] as String).trim(),
            isNotEmpty,
            reason: '${line['id']}',
          );
          expect(
            line['pauseAfterMs'],
            isA<int>().having((p) => p, 'pause', greaterThanOrEqualTo(0)),
          );
        }
      });

      test('there are 10 questions numbered in order', () {
        expect(questions, hasLength(10));
        final numbers = questions.map((q) => q['number'] as int).toList();
        expect(numbers, List.generate(10, (i) => numbers.first + i));
        expect(questions.map((q) => q['id']).toSet(), hasLength(10));
        final groups = _list(questionsDoc, 'groups');
        final covered = [
          for (final g in groups)
            for (var n = g['from'] as int; n <= (g['to'] as int); n++) n,
        ];
        expect(covered, numbers);
      });

      test('every group has reading time, announced before its answers', () {
        final groups = _list(questionsDoc, 'groups');
        var previousEvidence = -1;
        for (final g in groups) {
          final marker = g['readingTimeAfterLineId'] as String;
          expect(lineIndex, contains(marker), reason: 'group ${g['from']}');
          expect(
            lineText(marker),
            contains('look at questions ${g['from']} to ${g['to']}'),
          );
          expect(g['readingTimeMs'], isA<int>().having((t) => t, 'ms', 30000));
          final evidence = [
            for (final q in questions)
              if ((q['number'] as int) >= (g['from'] as int) &&
                  (q['number'] as int) <= (g['to'] as int))
                lineIndex[q['evidenceLineId']]!,
          ];
          expect(lineIndex[marker]!, greaterThan(previousEvidence));
          expect(lineIndex[marker]!, lessThan(evidence.first));
          previousEvidence = evidence.last;
        }
        // The app gives the reading time; the recording only pauses briefly.
        expect(
          lines.map((l) => l['pauseAfterMs'] as int),
          everyElement(lessThanOrEqualTo(2000)),
        );
      });

      test('every evidence line exists', () {
        for (final q in questions) {
          expect(
            lineIndex,
            contains(q['evidenceLineId']),
            reason: '${q['id']}',
          );
        }
      });

      test('question order matches script order', () {
        final positions = [
          for (final q in questions) lineIndex[q['evidenceLineId']]!,
        ];
        for (var i = 1; i < positions.length; i++) {
          expect(
            positions[i],
            greaterThanOrEqualTo(positions[i - 1]),
            reason:
                '${questions[i]['id']} comes before ${questions[i - 1]['id']} in the audio',
          );
        }
      });

      test('every answer appears in its evidence line', () {
        for (final q in questions) {
          final text = lineText(q['evidenceLineId'] as String);
          expect(
            text,
            contains(q['evidence']),
            reason: '${q['id']} evidence quote',
          );
          expect((q['explanation'] as String).trim(), isNotEmpty);

          switch (q['type']) {
            case 'formCompletion':
              final answer = q['answer'] as String;
              expect(
                _containsAnswer(text, answer),
                isTrue,
                reason: '${q['id']}: "$answer" not in "$text"',
              );
              final limit = q['wordLimit'] as Map<String, dynamic>;
              for (final a in [
                answer,
                ...(q['acceptedVariants'] as List).cast<String>(),
              ]) {
                final count = _countWords(a);
                expect(
                  count.words,
                  lessThanOrEqualTo(limit['maxWords'] as int),
                  reason: '${q['id']}: "$a"',
                );
                expect(
                  count.numbers,
                  lessThanOrEqualTo(limit['maxNumbers'] as int),
                  reason: '${q['id']}: "$a"',
                );
              }
            case 'multipleChoice' || 'matching':
              final keys = _list(q, 'options').map((o) => o['key']).toList();
              expect(keys.length, greaterThanOrEqualTo(3));
              expect(keys, contains(q['answer']), reason: '${q['id']}');
              expect(q['wordLimit'], isNull);
            default:
              fail('${q['id']}: unknown type ${q['type']}');
          }
        }
      });

      test('content never shows a band', () {
        final text = '${jsonEncode(script)} ${jsonEncode(questionsDoc)}';
        expect(text.toLowerCase(), isNot(contains('band')));
      });

      test('README lists every line id in script order', () {
        final readme = File('$dir/README.md').readAsStringSync();
        var from = 0;
        for (final line in lines) {
          final at = readme.indexOf('audio/${line['id']}.wav', from);
          expect(
            at,
            greaterThanOrEqualTo(0),
            reason: '${line['id']} missing or out of order',
          );
          from = at;
        }
        for (final s in speakers) {
          expect(readme, contains('`${s['id']}`'));
        }
      });

      final timestamps = File('$dir/timestamps.json');
      test(
        'timestamps match the script',
        skip: timestamps.existsSync() ? false : 'audio not built yet',
        () {
          final stamps = _list(_json(timestamps.path), 'lines');
          expect(stamps.map((s) => s['id']), lines.map((l) => l['id']));
          var previousEnd = 0;
          for (final s in stamps) {
            expect(s['startMs'] as int, greaterThanOrEqualTo(previousEnd));
            expect(s['endMs'] as int, greaterThan(s['startMs'] as int));
            previousEnd = s['endMs'] as int;
          }
        },
      );
    });
  }
}
