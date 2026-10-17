import 'dart:convert';

import 'package:bandwise/features/writing/data/mock_writing_feedback_service.dart';
import 'package:bandwise/features/writing/data/writing_content.dart';
import 'package:bandwise/features/writing/domain/essay_diff.dart';
import 'package:bandwise/features/writing/domain/writing.dart';
import 'package:bandwise/features/writing/domain/writing_feedback.dart';
import 'package:bandwise/features/writing/domain/writing_repository.dart';
import 'package:bandwise/features/writing/domain/writing_submission.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 15, 9);

WritingFeedback _sample(WritingTask task) =>
    buildSampleFeedback(task, sampleFeedback[task.id]!, task.sampleEssay, _now);

/// Task 1 sample feedback with [criteria] ranges and [overall].
WritingFeedback _withRanges(
  List<EstimateRange> criteria, {
  EstimateRange overall = const EstimateRange(6.0, 6.5),
  WritingTaskType type = WritingTaskType.task1,
}) {
  final base = _sample(cyclingTask);
  return WritingFeedback(
    taskType: type,
    overall: overall,
    criteria: [
      for (final (i, c) in base.criteria.indexed)
        CriterionFeedback(
          id: c.id,
          range: criteria[i],
          strength: c.strength,
          improvement: c.improvement,
          explanation: c.explanation,
        ),
    ],
    topImprovements: base.topImprovements,
    annotations: base.annotations,
    paragraphNotes: base.paragraphNotes,
    createdAt: base.createdAt,
  );
}

typedef _R = EstimateRange;

void main() {
  group('content', () {
    test('word counts are computed and near the targets', () {
      expect(countWords(cyclingTask.sampleEssay), inInclusiveRange(160, 180));
      expect(
        countWords(universitiesTask.sampleEssay),
        inInclusiveRange(270, 290),
      );
      expect(countWords("it's a well-known 12% rise"), 5);
      expect(countWords(''), 0);
      expect(countWords('  \n\n '), 0);
    });

    test('chart data is consistent', () {
      final chart = cyclingTask.chart!;
      expect(chart.series.map((s) => s.name), ['Arden', 'Belmont', 'Corvale']);
      for (final s in chart.series) {
        expect(s.values, hasLength(chart.xLabels.length));
        expect(s.values.every((v) => v >= 0 && v <= chart.yMax), isTrue);
      }
    });

    test('the Task 1 sample essay matches the chart', () {
      final chart = cyclingTask.chart!;
      List<num> city(String name) =>
          chart.series.firstWhere((s) => s.name == name).values;
      final arden = city('Arden'), belmont = city('Belmont');
      final corvale = city('Corvale');
      final essay = cyclingTask.sampleEssay;
      // Every percentage in the essay is a value on the chart.
      final all = {for (final s in chart.series) ...s.values};
      for (final m in RegExp(r'(\d+)%').allMatches(essay)) {
        expect(all, contains(int.parse(m[1]!)), reason: m[0]);
      }
      // "Belmont had the biggest proportion of cyclists, at 12%, compared
      // with only 4% in Arden and 3% in Corvale."
      expect([arden[0], belmont[0], corvale[0]], [4, 12, 3]);
      // "dropping to 10% in 2010, and it reached 7% in 2020"; "fell
      // steadily".
      expect([belmont[2], belmont[4]], [10, 7]);
      for (var i = 1; i < belmont.length; i++) {
        expect(belmont[i], lessThan(belmont[i - 1]));
      }
      // "rose to 9% in 2010 and overtook Belmont before 2015, finally
      // reaching 18% in 2020".
      expect([arden[2], arden[4]], [9, 18]);
      expect(arden[2], lessThan(belmont[2]));
      expect(arden[3], greaterThan(belmont[3]));
      // "staying between 3% and 5%" for the first fifteen years, then
      // "jumped to 9%", higher than Belmont "for the first time".
      expect(corvale.take(4).every((v) => v >= 3 && v <= 5), isTrue);
      expect(corvale[4], 9);
      for (var i = 0; i < 4; i++) {
        expect(corvale[i], lessThan(belmont[i]));
      }
      expect(corvale[4], greaterThan(belmont[4]));
      // "always lower than Arden"; Arden highest at the end.
      for (var i = 0; i < arden.length; i++) {
        expect(corvale[i], lessThan(arden[i]));
      }
      expect(arden[4], greaterThan(belmont[4]));
    });

    for (final task in writingTasks) {
      test('${task.type.label}: notes quote the essay exactly, once', () {
        final prepared = sampleFeedback[task.id]!;
        for (final n in prepared.notes) {
          expect(
            n.original.allMatches(task.sampleEssay).length,
            1,
            reason: n.id,
          );
        }
        final validation = validateFeedback(_sample(task), task.sampleEssay);
        expect(validation.errors, isEmpty);
        expect(validation.droppedAnnotations, isEmpty);
        expect(
          validation.feedback!.annotations,
          hasLength(prepared.notes.length),
        );
      });

      test('${task.type.label}: feedback quotes are from the essay', () {
        final f = _sample(task);
        final texts = [
          for (final c in f.criteria) ...[c.strength, c.improvement],
          for (final t in f.topImprovements) t.detail,
          for (final p in f.paragraphNotes) p.note,
        ];
        for (final text in texts) {
          for (final m in RegExp('‘([^’]+)’').allMatches(text)) {
            expect(task.sampleEssay, contains(m[1]), reason: text);
          }
        }
        final paragraphs = paragraphsOf(task.sampleEssay).length;
        for (final p in f.paragraphNotes) {
          expect(p.paragraph, lessThan(paragraphs));
        }
      });

      test('${task.type.label}: no extra numbers about quality', () {
        final f = _sample(task);
        final texts = [
          for (final c in f.criteria) ...[
            c.strength,
            c.improvement,
            c.explanation,
          ],
          for (final t in f.topImprovements) ...[t.title, t.detail],
          for (final a in f.annotations) ...[a.suggestion, a.why],
          for (final p in f.paragraphNotes) p.note,
        ];
        final banned = RegExp(
          r'\bband\b|projected|competent|\d\.\d',
          caseSensitive: false,
        );
        for (final text in texts) {
          // Quotes from the essay may contain its own figures.
          final unquoted = text.replaceAll(RegExp('‘[^’]*’'), '');
          expect(banned.hasMatch(unquoted), isFalse, reason: text);
          // The only percentages are the chart's, as used in the essay.
          for (final m in RegExp(r'\d+\s*%').allMatches(unquoted)) {
            expect(task.sampleEssay, contains(m[0]), reason: text);
          }
        }
      });
    }

    test('Task 1 uses Task Achievement, Task 2 Task Response', () {
      expect(
        _sample(cyclingTask).criteria.map((c) => c.id),
        WritingTaskType.task1.criteria.map((c) => c.id),
      );
      expect(
        _sample(universitiesTask).criteria.map((c) => c.id),
        WritingTaskType.task2.criteria.map((c) => c.id),
      );
      expect(
        WritingTaskType.task1.criteria,
        contains(WritingCriterion.taskAchievement),
      );
      expect(
        WritingTaskType.task2.criteria,
        isNot(contains(WritingCriterion.taskAchievement)),
      );
    });
  });

  group('validator', () {
    final essay = cyclingTask.sampleEssay;
    const ok = [_R(6.0, 6.5), _R(6.0, 6.5), _R(6.0, 6.5), _R(5.5, 6.0)];

    test('accepts the sample feedback', () {
      expect(validateFeedback(_withRanges(ok), essay).isValid, isTrue);
    });

    test('ranges must be within 1–9', () {
      final low = validateFeedback(
        _withRanges(const [
          _R(0.5, 1.0),
          _R(6.0, 6.5),
          _R(6.0, 6.5),
          _R(5.5, 6.0),
        ], overall: const _R(1.0, 1.5)),
        essay,
      );
      expect(low.isValid, isFalse);
      expect(low.feedback, isNull);
      final high = validateFeedback(
        _withRanges(const [
          _R(9.0, 9.5),
          _R(8.5, 9.0),
          _R(8.5, 9.0),
          _R(8.5, 9.0),
        ], overall: const _R(8.5, 9.0)),
        essay,
      );
      expect(high.errors, contains(startsWith('taskAchievement is outside')));
    });

    test('ranges must be in 0.5 steps and 0.5 wide', () {
      final steps = validateFeedback(
        _withRanges(const [
          _R(6.2, 6.7),
          _R(6.0, 6.5),
          _R(6.0, 6.5),
          _R(5.5, 6.0),
        ]),
        essay,
      );
      expect(steps.errors, contains('taskAchievement is not in 0.5 steps'));
      final wide = validateFeedback(
        _withRanges(ok, overall: const _R(5.5, 6.5)),
        essay,
      );
      expect(wide.errors, contains('overall is not 0.5 wide'));
      final point = validateFeedback(
        _withRanges(ok, overall: const _R(6.0, 6.0)),
        essay,
      );
      expect(point.isValid, isFalse);
    });

    test('criteria must match the task type', () {
      final wrongType = validateFeedback(
        _withRanges(ok, type: WritingTaskType.task2),
        essay,
      );
      expect(wrongType.errors.single, startsWith('criteria'));

      final base = _withRanges(ok);
      final missing = WritingFeedback(
        taskType: base.taskType,
        overall: base.overall,
        criteria: base.criteria.take(3).toList(),
        topImprovements: const [],
        annotations: const [],
        paragraphNotes: const [],
        createdAt: _now,
      );
      expect(validateFeedback(missing, essay).isValid, isFalse);
    });

    test('the overall range lies within the criteria span', () {
      expect(
        validateFeedback(
          _withRanges(ok, overall: const _R(5.5, 6.0)),
          essay,
        ).isValid,
        isTrue,
      );
      final above = validateFeedback(
        _withRanges(ok, overall: const _R(6.5, 7.0)),
        essay,
      );
      expect(above.errors.single, startsWith('overall is outside'));
      final below = validateFeedback(
        _withRanges(ok, overall: const _R(5.0, 5.5)),
        essay,
      );
      expect(below.isValid, isFalse);
    });

    test('annotations that do not quote the essay are dropped', () {
      final base = _withRanges(ok);
      final good = base.annotations.first;
      Annotation note(String id, int start, int end, String original) =>
          Annotation(
            id: id,
            type: AnnotationType.grammar,
            criterionId: good.criterionId,
            start: start,
            end: end,
            original: original,
            suggestion: 'x',
            why: 'y',
          );
      final result = validateFeedback(
        base.copyWith(
          annotations: [
            good,
            note('shifted', good.start + 1, good.end + 1, good.original),
            note('outside', essay.length - 2, essay.length + 5, 'zzz'),
            note('empty', 10, 10, ''),
            note('overlap', good.start, good.end, good.original),
            Annotation(
              id: 'criterion',
              type: AnnotationType.task,
              criterionId: 'taskResponse',
              start: good.start,
              end: good.end,
              original: good.original,
              suggestion: 'x',
              why: 'y',
            ),
          ],
        ),
        essay,
      );
      expect(result.isValid, isTrue);
      expect(result.feedback!.annotations.map((a) => a.id), [good.id]);
      expect(result.droppedAnnotations.toSet(), {
        'shifted',
        'outside',
        'empty',
        'overlap',
        'criterion',
      });
    });

    test('JSON round trip keeps the contract', () {
      final f = _sample(universitiesTask);
      final json = jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>;
      expect(json.keys.toSet(), {
        'taskType',
        'overall',
        'criteria',
        'topImprovements',
        'annotations',
        'paragraphNotes',
        'createdAt',
      });
      expect((json['criteria'] as List).first.keys.toSet(), {
        'id',
        'low',
        'high',
        'strength',
        'improvement',
        'explanation',
      });
      expect((json['annotations'] as List).first.keys.toSet(), {
        'id',
        'type',
        'criterionId',
        'start',
        'end',
        'original',
        'suggestion',
        'why',
      });
      final back = WritingFeedback.fromJson(json);
      expect(back.overall, f.overall);
      expect(back.annotations.length, f.annotations.length);
      expect(
        validateFeedback(back, universitiesTask.sampleEssay).isValid,
        isTrue,
      );
    });

    test('range labels', () {
      expect(const EstimateRange(6, 6.5).label, '6.0–6.5');
      expect(const EstimateRange(6, 6.5).spoken, '6.0 to 6.5');
    });
  });

  group('mock service', () {
    const service = MockWritingFeedbackService(
      delay: Duration.zero,
      now: _clock,
    );

    test('the sample essay gets full, validated feedback', () async {
      final result = await service.evaluate(
        task: cyclingTask,
        essay: '  ${cyclingTask.sampleEssay.replaceAll('\n\n', '\n')}\n',
      );
      expect(result, isA<AnalysedResult>());
      final f = (result as AnalysedResult).feedback;
      expect(result.sample, isTrue);
      expect(
        f.annotations,
        hasLength(sampleFeedback[cyclingTask.id]!.notes.length),
      );
    });

    test('any other essay gets demo feedback only', () async {
      final edited = cyclingTask.sampleEssay.replaceFirst(
        'who cycling',
        'who cycled',
      );
      expect(
        await service.evaluate(task: cyclingTask, essay: edited),
        isA<DemoResult>(),
      );
      expect(
        await service.evaluate(
          task: universitiesTask,
          essay: cyclingTask.sampleEssay,
        ),
        isA<DemoResult>(),
      );
    });

    test('the debug switch simulates an error', () {
      const failing = MockWritingFeedbackService(
        delay: Duration.zero,
        simulateError: true,
        now: _clock,
      );
      expect(
        failing.evaluate(task: cyclingTask, essay: cyclingTask.sampleEssay),
        throwsA(isA<WritingFeedbackException>()),
      );
    });

    test('general feedback covers the task type criteria', () {
      for (final type in WritingTaskType.values) {
        expect(generalFeedbackFor(type).criteriaTips.keys, type.criteria);
      }
    });
  });

  group('diff', () {
    test('counts added, removed and replaced words per paragraph', () {
      final diffs = diffEssays(
        'Cycling become more popular in Arden.\n\nIt rose quickly.',
        'Cycling became more popular in Arden and Corvale.\n\nIt rose.\n\n'
            'A new paragraph.',
      );
      expect(diffs, hasLength(3));
      final first = diffs[0];
      // "become" → "became"; "Arden." → "Arden and Corvale.".
      expect(first.counts.replaced, 2);
      expect(first.counts.added, 0);
      expect(first.segments.map((s) => (s.op, s.text)), [
        (DiffOp.same, 'Cycling'),
        (DiffOp.removed, 'become'),
        (DiffOp.added, 'became'),
        (DiffOp.same, 'more popular in'),
        (DiffOp.removed, 'Arden.'),
        (DiffOp.added, 'Arden and Corvale.'),
      ]);
      expect(diffs[1].counts.replaced, 1);
      expect(diffs[2].before, isNull);
      expect(diffs[2].counts.added, 3);
    });

    test('identical essays have no changes', () {
      final diffs = diffEssays(
        universitiesTask.sampleEssay,
        universitiesTask.sampleEssay,
      );
      expect(diffs.every((d) => !d.changed), isTrue);
      expect(
        diffs.fold(const ChangeCounts(), (sum, d) => sum + d.counts).total,
        0,
      );
    });

    test('a removed word', () {
      final d = diffEssays('a b c', 'a c').single;
      expect(d.counts.removed, 1);
      expect(d.counts.total, 1);
    });
  });

  test('submission JSON round trip', () {
    final s = WritingSubmission(
      id: 's1',
      taskId: cyclingTask.id,
      mode: WritingMode.timed,
      text: cyclingTask.sampleEssay,
      timeUsed: const Duration(minutes: 18, seconds: 3),
      submittedAt: _now,
      timeUp: true,
      result: AnalysedResult(_sample(cyclingTask), sample: true),
    );
    final back = WritingSubmission.fromJson(
      jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
    );
    expect(back.timeUsed, s.timeUsed);
    expect(back.timeUp, isTrue);
    expect(back.wordCount, countWords(cyclingTask.sampleEssay));
    expect((back.result! as AnalysedResult).sample, isTrue);
  });
}

DateTime _clock() => _now;
