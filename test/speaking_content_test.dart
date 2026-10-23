import 'dart:io';

import 'package:bandwise/features/speaking/domain/speaking.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_speaking.dart';

void main() {
  final content = loadSpeakingContent();
  final lines = content.allLines;

  test('Part 1: 3 topics of 4 questions', () {
    expect(content.part1, hasLength(3));
    for (final t in content.part1) {
      expect(t.questions, hasLength(4), reason: t.id);
      expect(t.questions.every((q) => q.part == SpeakingPart.part1), isTrue);
    }
  });

  test('Part 2: 2 cue cards with 3 points, "and explain…", a rounding-off '
      'question and 4–5 linked Part 3 questions', () {
    expect(content.cueCards, hasLength(2));
    for (final c in content.cueCards) {
      expect(c.prompt, startsWith('Describe a'));
      expect(c.bullets, hasLength(3));
      expect(c.explain, startsWith('and explain'));
      expect(c.roundingOff.text, endsWith('?'));
      expect(c.part3Questions.length, inInclusiveRange(4, 5));
      expect(
        c.part3Questions.every((q) => q.part == SpeakingPart.part3),
        isTrue,
      );
    }
  });

  test('every line has a stable, unique id and text', () {
    final ids = [for (final l in lines) l.id];
    expect(ids.toSet(), hasLength(ids.length));
    for (final l in lines) {
      expect(l.id, matches(RegExp(r'^[a-z0-9_]+$')));
      expect(l.text.trim(), isNotEmpty, reason: l.id);
    }
    for (final id in [
      'ex_intro',
      'ex_part2_intro',
      'ex_part2_start',
      'ex_part2_stop',
      'ex_end',
    ]) {
      expect(content.examiner, contains(id));
    }
  });

  test('every line has its examiner recording', () {
    for (final l in lines) {
      expect(File(l.audioAsset).existsSync(), isTrue, reason: l.audioAsset);
    }
  });

  test('the README lists every line', () {
    final readme = File('assets/speaking/README.md').readAsStringSync();
    for (final l in lines) {
      expect(readme, contains('`${l.id}`'));
    }
    expect(readme, contains('Apache-2.0'));
    expect(readme, contains('bm_george'));
  });

  test('no band anywhere in the content', () {
    final text = File('assets/speaking/content.json').readAsStringSync();
    expect(text.toLowerCase(), isNot(contains('band')));
  });
}
