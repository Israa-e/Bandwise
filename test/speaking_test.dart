import 'dart:convert';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/router/app_routes.dart';
import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/core/utils/clock.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/speaking/data/prefs_speaking_attempt_repository.dart';
import 'package:bandwise/features/speaking/domain/speaking.dart';
import 'package:bandwise/features/speaking/domain/speaking_attempt.dart';
import 'package:bandwise/features/speaking/domain/speaking_devices.dart';
import 'package:bandwise/features/speaking/domain/speaking_feedback.dart';
import 'package:bandwise/features/speaking/presentation/speaking_hub_screen.dart';
import 'package:bandwise/features/speaking/presentation/speaking_practice_screen.dart';
import 'package:bandwise/features/speaking/presentation/speaking_providers.dart';
import 'package:bandwise/features/speaking/presentation/speaking_review_screen.dart';
import 'package:bandwise/features/speaking/presentation/speaking_test_screen.dart';
import 'package:bandwise/features/speaking/presentation/widgets/speaking_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_speaking.dart';

final _today = DateTime(2026, 10, 15);
final _content = loadSpeakingContent();

const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  placementSkipped: true,
);

/// The fake time screens read. Tests move it forward.
late DateTime _now;
late FakeRecordingStore _store;

List<Override> _overrides({
  MicPermission permission = MicPermission.granted,
  MicPermission? afterRequest,
}) => [
  todayProvider.overrideWithValue(_today),
  clockProvider.overrideWithValue(() => _now),
  speakingContentRepositoryProvider.overrideWithValue(
    FakeSpeakingContentRepository(_content),
  ),
  speakingRecorderFactoryProvider.overrideWithValue(
    () => FakeRecorder(status: permission, afterRequest: afterRequest),
  ),
  speakingAudioFactoryProvider.overrideWithValue(FakeSpeakingAudio.new),
  recordingStoreProvider.overrideWithValue(_store),
  speechTranscriberFactoryProvider.overrideWithValue(FakeTranscriber.new),
];

void _reset({ProgressState? progress, List<SpeakingAttempt>? attempts}) {
  _now = DateTime(2026, 10, 15, 9);
  _store = FakeRecordingStore();
  FakeRecorder.instances.clear();
  FakeSpeakingAudio.instances.clear();
  FakeTranscriber.instances.clear();
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(_onboarding.toJson()),
    'progress.v1': ?switch (progress) {
      final p? => jsonEncode(p.toJson()),
      null => null,
    },
    PrefsSpeakingAttemptRepository.key: ?switch (attempts) {
      final a? => jsonEncode([for (final x in a) x.toJson()]),
      null => null,
    },
  });
}

Future<void> _launchApp(
  WidgetTester tester, {
  MicPermission permission = MicPermission.granted,
  MicPermission? afterRequest,
  ProgressState? progress,
  List<SpeakingAttempt>? attempts,
}) async {
  _reset(progress: progress, attempts: attempts);
  tester.view.physicalSize = const Size(390, 1000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(permission: permission, afterRequest: afterRequest),
      child: const BandwiseApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String location) async {
  ProviderScope.containerOf(
    tester.element(find.byType(BandwiseApp)),
  ).read(routerProvider).push(location);
  await tester.pumpAndSettle();
}

/// Taps without waiting to settle: recording screens tick.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}

/// Moves the fake clock on and lets the screen tick.
Future<void> _wait(WidgetTester tester, Duration d) async {
  _now = _now.add(d);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<ProgressState> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return ProgressState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

Future<List<SpeakingAttempt>> _savedAttempts() =>
    const PrefsSpeakingAttemptRepository().loadAttempts();

FakeRecorder get _recorder => FakeRecorder.instances.last;

/// The examiner's player in a session (the first one it made).
FakeSpeakingAudio _examinerAudio() => FakeSpeakingAudio.instances.first;

String _asset(String id) => 'assets/speaking/mp3/$id.mp3';

void _background(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Every piece of text on screen.
List<String> _allText(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
  for (final t in tester.widgetList<EditableText>(find.byType(EditableText)))
    t.controller.text,
];

void _expectNoBands(WidgetTester tester) {
  final band = RegExp(r'\bband\b', caseSensitive: false);
  expect(_allText(tester).where(band.hasMatch), isEmpty);
}

RecordedAnswer _answer(
  String id,
  SpeakingPart part,
  int seconds, {
  bool longTurn = false,
  List<SilenceSpan> silences = const [],
  CutShort? cutShort,
  String? transcript,
}) => RecordedAnswer(
  questionId: id,
  part: part,
  path: 'mem/$id.m4a',
  duration: Duration(seconds: seconds),
  isLongTurn: longTurn,
  silences: silences,
  cutShort: cutShort,
  transcript: transcript,
);

SpeakingAttempt _attempt({
  String id = 'a1',
  SpeakingMode mode = SpeakingMode.practice,
  List<RecordedAnswer>? answers,
}) => SpeakingAttempt(
  id: id,
  mode: mode,
  startedAt: DateTime(2026, 10, 15, 9),
  finishedAt: DateTime(2026, 10, 15, 9, 6),
  answers:
      answers ??
      [
        _answer('p1_home_q1', SpeakingPart.part1, 22),
        _answer(
          'p2_skill',
          SpeakingPart.part2,
          48,
          longTurn: true,
          silences: const [
            SilenceSpan(Duration(seconds: 12), Duration(seconds: 16)),
          ],
        ),
        _answer(
          'p3_skill_q1',
          SpeakingPart.part3,
          90,
          cutShort: CutShort.timeLimit,
        ),
      ],
);

void main() {
  group('domain', () {
    test('silence detection finds pauses over 3 seconds, with times', () {
      final d = SilenceDetector();
      // 200 ms samples: talk to 2 s, quiet 2–6 s, talk, a 1 s gap, then
      // quiet from 9 s to the end at 13 s.
      for (var ms = 0; ms <= 13000; ms += 200) {
        final quiet =
            (ms >= 2000 && ms < 6000) ||
            (ms >= 7000 && ms < 8000) ||
            ms >= 9000;
        d.add(Duration(milliseconds: ms), quiet ? -60 : -20);
      }
      expect(d.finish(const Duration(seconds: 13)), const [
        SilenceSpan(Duration(seconds: 2), Duration(seconds: 6)),
        SilenceSpan(Duration(seconds: 9), Duration(seconds: 13)),
      ]);
    });

    test('automatic checks: usual lengths per part, a short long turn', () {
      AnswerCheck check(SpeakingPart part, int s, {bool longTurn = false}) =>
          AnswerCheck(_answer('q', part, s, longTurn: longTurn));
      expect(check(SpeakingPart.part1, 20).fit, LengthFit.usual);
      expect(check(SpeakingPart.part1, 8).fit, LengthFit.short);
      expect(check(SpeakingPart.part1, 50).fit, LengthFit.long);
      final longTurn = check(SpeakingPart.part2, 50, longTurn: true);
      expect(longTurn.targetLabel, 'Aim for 1:30–2:00');
      expect(longTurn.longTurnUnderAMinute, isTrue);
      expect(
        check(SpeakingPart.part2, 120, longTurn: true).fit,
        LengthFit.usual,
      );
    });

    test('XP: 5 per question the first time each day, 20 for a Timed test, '
        'Confidence included', () {
      var p = const ProgressState();
      int xp(String mode, List<String> ids, {DateTime? on}) =>
          p.speakingXpFor(mode: mode, date: on ?? _today, questionIds: ids);
      expect(xp('practice', ['q1', 'q2', 'q2']), 10);
      expect(xp('confidence', ['q1']), 5);
      expect(xp('timed', ['q1', 'q2']), XpRules.completedSpeakingTest);

      p = p.withSpeakingSession(
        SpeakingSession(
          id: 's1',
          mode: 'practice',
          date: _today,
          minutes: 4,
          xp: 10,
          answers: const [
            SpeakingAnswerSummary(
              questionId: 'q1',
              part: 1,
              duration: Duration(seconds: 20),
            ),
            SpeakingAnswerSummary(
              questionId: 'q2',
              part: 1,
              duration: Duration(seconds: 25),
            ),
          ],
        ),
      );
      expect(p.totalXp, 10);
      expect(p.minutesOn(_today), 4);
      expect(p.streak(_today), 1);
      // Answered today already: nothing more, in either mode.
      expect(xp('practice', ['q1', 'q2']), 0);
      expect(xp('confidence', ['q2', 'q3']), 5);
      // A new day counts again.
      expect(
        xp('practice', ['q1'], on: _today.add(const Duration(days: 1))),
        5,
      );
    });

    test('sessions survive a save and load', () {
      final p = const ProgressState().withSpeakingSession(
        SpeakingSession(
          id: 's1',
          mode: 'timed',
          date: _today,
          minutes: 13,
          xp: 20,
          answers: [
            const SpeakingAnswerSummary(
              questionId: 'p2_skill',
              part: 2,
              duration: Duration(seconds: 104),
              isLongTurn: true,
              longSilences: 2,
              cutShort: true,
            ),
          ],
        ),
      );
      final loaded = ProgressState.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      final a = loaded.speakingSessions.single.answers.single;
      expect(a.isLongTurn && a.cutShort, isTrue);
      expect(a.longSilences, 2);
    });

    group('feedback validator', () {
      SpeakingFeedback feedback({
        List<SpeakingCriterionFeedback>? criteria,
        List<SpeakingNote> notes = const [],
        List<SpeakingPart> parts = const [SpeakingPart.part1],
      }) => SpeakingFeedback(
        parts: parts,
        criteria:
            criteria ??
            [
              for (final c in SpeakingCriterion.values)
                SpeakingCriterionFeedback(
                  criterion: c,
                  range: const EstimateRange(6.0, 6.5),
                  strength: 's',
                  improvement: 'i',
                ),
            ],
        strengths: const ['Clear answers'],
        improvements: const ['Add examples'],
        notes: notes,
        createdAt: DateTime(2026, 10, 15),
      );

      SpeakingNote note(String id, String q, int start, int end) =>
          SpeakingNote(
            id: id,
            questionId: q,
            start: Duration(seconds: start),
            end: Duration(seconds: end),
            criterion: SpeakingCriterion.fluencyCoherence,
            note: 'Long pause',
          );

      test('accepts good feedback and drops notes that don\'t fit', () {
        final v = validateSpeakingFeedback(
          feedback(
            notes: [
              note('ok', 'p1_home_q1', 2, 5),
              note('past-end', 'p1_home_q1', 20, 30),
              note('unknown', 'p1_free_q4', 1, 2),
              note('other-part', 'p2_skill', 1, 2),
            ],
          ),
          _attempt(),
        );
        expect(v.isValid, isTrue);
        expect(v.feedback!.notes.map((n) => n.id), ['ok']);
        expect(v.droppedNotes, ['past-end', 'unknown', 'other-part']);
      });

      test(
        'rejects bad ranges, missing criteria and parts with no answers',
        () {
          final bad = validateSpeakingFeedback(
            feedback(
              criteria: [
                const SpeakingCriterionFeedback(
                  criterion: SpeakingCriterion.fluencyCoherence,
                  range: EstimateRange(6.2, 7.0),
                  strength: 's',
                  improvement: 'i',
                ),
              ],
            ),
            _attempt(),
          );
          expect(bad.isValid, isFalse);
          expect(bad.feedback, isNull);
          expect(bad.errors.join(' '), contains('0.5 steps'));
          expect(bad.errors.join(' '), contains('four speaking criteria'));
          final noAnswers = validateSpeakingFeedback(
            feedback(parts: const [SpeakingPart.part1]),
            _attempt(answers: [_answer('p3_skill_q1', SpeakingPart.part3, 40)]),
          );
          expect(noAnswers.errors.single, contains('part1 has no answers'));
        },
      );

      test('round-trips through JSON', () {
        final f = feedback(notes: [note('n', 'p1_home_q1', 1, 4)]);
        final back = SpeakingFeedback.fromJson(
          jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>,
        );
        expect(back.criteria.map((c) => c.criterion), SpeakingCriterion.values);
        expect(back.notes.single.end, const Duration(seconds: 4));
      });
    });
  });

  group('microphone permission', () {
    testWidgets('explains before the system prompt, then records', (
      tester,
    ) async {
      await _launchApp(tester, permission: MicPermission.canAsk);
      await _go(
        tester,
        AppRoutes.speakingPractice(mode: 'practice', part: 1, setId: 'p1_home'),
      );
      expect(find.byKey(const ValueKey('micExplain')), findsOneWidget);
      expect(find.text('Allow the microphone'), findsOneWidget);
      expect(_recorder.requests, 0, reason: 'no system prompt yet');
      expect(FakeSpeakingAudio.instances.first.loaded, isEmpty);

      await tester.tap(find.byKey(const ValueKey('micAction')));
      await tester.pumpAndSettle();
      expect(_recorder.requests, 1);
      expect(find.byKey(const ValueKey('startRecording')), findsOneWidget);
      expect(_examinerAudio().current, _asset('p1_home_q1'));
    });

    testWidgets('denied: says so and offers to ask again', (tester) async {
      await _launchApp(
        tester,
        permission: MicPermission.canAsk,
        afterRequest: MicPermission.canAsk,
      );
      await _go(
        tester,
        AppRoutes.speakingPractice(mode: 'practice', part: 1, setId: 'p1_home'),
      );
      await tester.tap(find.byKey(const ValueKey('micAction')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('micDenied')), findsOneWidget);
      expect(find.text('Microphone access is off'), findsOneWidget);
      expect(find.byKey(const ValueKey('startRecording')), findsNothing);
      _recorder.afterRequest = MicPermission.granted;
      await tester.tap(find.byKey(const ValueKey('micAction')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('startRecording')), findsOneWidget);
    });

    testWidgets('permanently denied: "Open settings", no prompt', (
      tester,
    ) async {
      await _launchApp(tester, permission: MicPermission.permanentlyDenied);
      await _go(tester, AppRoutes.speakingTest());
      expect(find.byKey(const ValueKey('micBlocked')), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(_recorder.settingsOpened, 1);
      expect(_recorder.requests, 0);

      // Allowed in the settings: back in the app, the test starts.
      _recorder.status = MicPermission.granted;
      _background(tester);
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('examinerSpeaking')), findsOneWidget);
    });
  });

  group('practice', () {
    testWidgets('record, play back, record again; finish to the '
        'self-review with XP', (tester) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.speakingHub);
      expect(find.byType(SpeakingHubScreen), findsOneWidget);
      // The transcript is off unless turned on.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('transcriptSwitch')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<SwitchCard>(find.byKey(const ValueKey('transcriptSwitch')))
            .value,
        isFalse,
      );
      await _tap(tester, find.byKey(const ValueKey('startSpeaking')));
      await tester.pumpAndSettle();

      final examiner = _examinerAudio();
      expect(find.text('Question 1 of 4'), findsOneWidget);
      expect(
        find.text(_content.part1.first.questions.first.text),
        findsOneWidget,
      );
      expect(examiner.current, _asset('p1_home_q1'));
      // The question can be played again.
      examiner.complete();
      await _tap(tester, find.byKey(const ValueKey('playQuestion')));
      expect(
        examiner.loaded.where((a) => a == _asset('p1_home_q1')),
        hasLength(2),
      );

      await _tap(tester, find.byKey(const ValueKey('startRecording')));
      expect(_recorder.isRecording, isTrue);
      expect(find.text('Recording'), findsOneWidget);
      await _wait(tester, const Duration(seconds: 12));
      expect(find.byKey(const ValueKey('recordingTime')), findsOneWidget);
      expect(find.text('0:12'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('stopRecording')));
      expect(find.text('Your answer · 0:12'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('playAnswer')));
      final playback = FakeSpeakingAudio.instances[1];
      expect(playback.current, startsWith('mem/'));
      final first = _recorder.starts.single;

      await _tap(tester, find.byKey(const ValueKey('reRecord')));
      await _wait(tester, const Duration(seconds: 20));
      await _tap(tester, find.byKey(const ValueKey('stopRecording')));
      expect(find.text('Your answer · 0:20'), findsOneWidget);
      expect(_store.deleted, [first], reason: 'the old take is deleted');

      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      expect(find.text('Question 2 of 4'), findsOneWidget);
      expect(examiner.current, _asset('p1_home_q2'));
      await _tap(tester, find.byKey(const ValueKey('startRecording')));
      await _wait(tester, const Duration(seconds: 25));
      await _tap(tester, find.byKey(const ValueKey('stopRecording')));
      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      await tester.pumpAndSettle();

      expect(find.byType(SpeakingReviewScreen), findsOneWidget);
      expect(find.text(NoAiFeedbackBanner.text), findsOneWidget);
      expect(find.byKey(const ValueKey('automaticChecks')), findsOneWidget);
      expect(find.text('Checked automatically'), findsOneWidget);
      _expectNoBands(tester);

      final saved = await _savedProgress();
      expect(saved.speakingSessions.single.answers, hasLength(2));
      expect(saved.totalXp, 2 * XpRules.perSpeakingAnswer);
      expect(saved.streak(_today), 1);
      final attempt = (await _savedAttempts()).single;
      expect(attempt.transcriptOn, isFalse);
      expect(FakeTranscriber.instances, isEmpty);
    });

    testWidgets('an interruption stops safely, keeps the partial answer and '
        'offers to re-record', (tester) async {
      await _launchApp(tester);
      await _go(
        tester,
        AppRoutes.speakingPractice(mode: 'practice', part: 1, setId: 'p1_work'),
      );
      await _tap(tester, find.byKey(const ValueKey('startRecording')));
      await _wait(tester, const Duration(seconds: 7));
      _background(tester);
      await tester.pump();
      await tester.pump();
      expect(_recorder.isRecording, isFalse);
      expect(_recorder.stops, 1);
      _resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Recording stopped'), findsOneWidget);
      expect(find.text('Your answer · 0:07'), findsOneWidget);
      await _tap(tester, find.text('Re-record this answer'));
      expect(_recorder.isRecording, isTrue);
      expect(find.text('Recording stopped'), findsNothing);
    });

    testWidgets('long pauses are found from the loudness while recording', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(
        tester,
        AppRoutes.speakingPractice(mode: 'practice', part: 1, setId: 'p1_free'),
      );
      await _tap(tester, find.byKey(const ValueKey('startRecording')));
      for (var s = 1; s <= 10; s++) {
        _now = _now.add(const Duration(seconds: 1));
        // Quiet from 3 s to 8 s.
        _recorder.level(s >= 3 && s < 8 ? -55 : -18);
      }
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('stopRecording')));
      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      for (var i = 0; i < 3; i++) {
        await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      }
      await tester.pumpAndSettle();
      final silences = (await _savedAttempts()).single.answers.single.silences;
      expect(silences, const [
        SilenceSpan(Duration(seconds: 3), Duration(seconds: 8)),
      ]);
      expect(find.text('Long pause at 0:03 (5 s)'), findsOneWidget);
    });

    testWidgets('the automatic transcript, when turned on, is labelled', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(
        tester,
        AppRoutes.speakingPractice(
          mode: 'practice',
          part: 1,
          setId: 'p1_home',
          transcript: true,
        ),
      );
      await _tap(tester, find.byKey(const ValueKey('startRecording')));
      await _wait(tester, const Duration(seconds: 15));
      await _tap(tester, find.byKey(const ValueKey('stopRecording')));
      expect(FakeTranscriber.instances.single.started, 1);
      for (var i = 0; i < 4; i++) {
        await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      }
      await tester.pumpAndSettle();
      expect(find.text(TranscriptCopy.label), findsOneWidget);
      expect(find.text('I grew up in a small town by the sea'), findsOneWidget);
    });
  });

  group('confidence', () {
    testWidgets('no timers, gentle prompts, and XP without a score', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(
        tester,
        AppRoutes.speakingPractice(
          mode: 'confidence',
          part: 2,
          setId: 'p2_skill',
        ),
      );
      expect(find.byKey(const ValueKey('gentlePrompts')), findsOneWidget);
      expect(find.text('Why did it matter?'), findsOneWidget);
      expect(find.byKey(const ValueKey('cueCard-p2_skill')), findsOneWidget);
      expect(_examinerAudio().current, _asset('p2_skill_topic'));

      await _tap(tester, find.byKey(const ValueKey('startRecording')));
      await _wait(tester, const Duration(seconds: 40));
      expect(find.text('Recording'), findsOneWidget);
      expect(find.byKey(const ValueKey('recordingTime')), findsNothing);
      expect(find.byType(TimerPill), findsNothing);
      expect(find.textContaining(RegExp(r'\d:\d\d')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('stopRecording')));
      expect(find.text('Your answer is recorded'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d:\d\d')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      await _tap(tester, find.byKey(const ValueKey('nextQuestion')));
      await tester.pumpAndSettle();
      expect(
        find.text('Confidence sessions are private and never scored.'),
        findsOneWidget,
      );
      final saved = await _savedProgress();
      expect(
        saved.speakingSessions.single.mode,
        SpeakingSession.confidenceMode,
      );
      expect(saved.totalXp, XpRules.perSpeakingAnswer);
    });

    testWidgets('after 3 Confidence sessions the hub suggests a Timed test', (
      tester,
    ) async {
      var p = const ProgressState();
      for (var i = 0; i < 3; i++) {
        p = p.withSpeakingSession(
          SpeakingSession(
            id: 'c$i',
            mode: SpeakingSession.confidenceMode,
            date: _today,
            minutes: 3,
            xp: 5,
            answers: const [],
          ),
        );
      }
      await _launchApp(tester, progress: p);
      await _go(tester, AppRoutes.speakingHub);
      expect(find.byKey(const ValueKey('tryTimed')), findsOneWidget);
      await _tap(tester, find.text('Try a Timed test'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('timedOutline')), findsOneWidget);
    });
  });

  group('timed test', () {
    testWidgets('recording starts after each question; one repeat per '
        'question', (tester) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.speakingTest());
      final examiner = _examinerAudio();
      expect(examiner.current, _asset('ex_intro'));
      expect(find.text('Listen to the examiner'), findsOneWidget);
      // Questions aren't shown, only heard, and can't be replayed.
      expect(find.byKey(const ValueKey('playQuestion')), findsNothing);

      examiner.complete();
      await tester.pump();
      expect(examiner.current, _asset('p1_home_intro'));
      expect(_recorder.isRecording, isFalse);
      examiner.complete();
      await tester.pump();
      expect(examiner.current, _asset('p1_home_q1'));
      expect(_recorder.isRecording, isFalse);
      examiner.complete();
      await tester.pump();
      await tester.pump();
      expect(_recorder.isRecording, isTrue, reason: 'starts by itself');
      expect(find.text('Recording'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('repeatQuestion')));
      expect(_recorder.cancels, 1);
      expect(_recorder.isRecording, isFalse);
      expect(examiner.current, _asset('p1_home_q1'));
      expect(
        examiner.loaded.where((a) => a == _asset('p1_home_q1')),
        hasLength(2),
      );
      examiner.complete();
      await tester.pump();
      await tester.pump();
      expect(_recorder.isRecording, isTrue);
      expect(find.byKey(const ValueKey('repeatQuestion')), findsNothing);

      await _wait(tester, const Duration(seconds: 20));
      await _tap(tester, find.byKey(const ValueKey('finishedAnswer')));
      expect(examiner.current, _asset('p1_home_q2'));
      // A new question can be repeated once again.
      examiner.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('repeatQuestion')), findsOneWidget);
    });

    testWidgets('Part 1 moves on after 5 minutes; Part 2 has 1:00 to '
        'prepare and stops at 2:00 with "Thank you"', (tester) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.speakingTest());
      final examiner = _examinerAudio();
      Future<void> examinerDone() async {
        examiner.complete();
        await tester.pump();
        await tester.pump();
      }

      await examinerDone(); // intro
      await examinerDone(); // topic intro
      await examinerDone(); // first question: recording
      expect(_recorder.isRecording, isTrue);
      // Part 1's five minutes pass (the clock jumps without a tick, so the
      // answer isn't stopped at its own limit first).
      _now = _now.add(const Duration(minutes: 5));
      await _tap(tester, find.byKey(const ValueKey('finishedAnswer')));
      expect(examiner.current, _asset('ex_part2_intro'));

      await examinerDone();
      expect(examiner.current, _asset('p2_skill_topic'));
      await examinerDone();
      expect(find.byKey(const ValueKey('preparing')), findsOneWidget);
      expect(find.byKey(const ValueKey('prepTimer')), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('notes')),
        'grandad, bike',
      );
      await _wait(tester, const Duration(seconds: 59));
      expect(find.byKey(const ValueKey('preparing')), findsOneWidget);
      expect(_recorder.isRecording, isFalse);
      await _wait(tester, const Duration(seconds: 1));
      expect(examiner.current, _asset('ex_part2_start'));
      await examinerDone();
      expect(_recorder.isRecording, isTrue);
      expect(find.byKey(const ValueKey('repeatQuestion')), findsNothing);

      // Under a minute: a gentle note, and the talk goes on.
      await _wait(tester, const Duration(seconds: 30));
      await _tap(tester, find.byKey(const ValueKey('finishedAnswer')));
      expect(find.byKey(const ValueKey('underAMinute')), findsOneWidget);
      await tester.tap(find.text('Keep talking'));
      await tester.pump();
      expect(_recorder.isRecording, isTrue);

      await _wait(tester, const Duration(seconds: 89));
      expect(_recorder.isRecording, isTrue);
      await _wait(tester, const Duration(seconds: 1));
      await tester.pump();
      expect(_recorder.isRecording, isFalse, reason: 'stops at 2:00');
      expect(examiner.current, _asset('ex_part2_stop'));
      await examinerDone();
      expect(examiner.current, _asset('p2_skill_follow'));
    });

    testWidgets('the whole test saves a session worth 20 XP', (tester) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.speakingTest());
      final examiner = _examinerAudio();
      for (var i = 0; i < 80; i++) {
        if (find.byType(SpeakingReviewScreen).evaluate().isNotEmpty) break;
        if (find.byKey(const ValueKey('preparing')).evaluate().isNotEmpty) {
          await _wait(tester, const Duration(minutes: 1));
        } else if (_recorder.isRecording) {
          await _wait(tester, const Duration(seconds: 20));
          await _tap(tester, find.byKey(const ValueKey('finishedAnswer')));
          if (find.text('Keep going?').evaluate().isNotEmpty) {
            await tester.tap(find.widgetWithText(TextButton, "I've finished"));
            await tester.pump();
            await tester.pump();
          }
        } else if (examiner.playing) {
          examiner.complete();
          await tester.pump();
          await tester.pump();
        } else {
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      await tester.pumpAndSettle();
      expect(find.byType(SpeakingReviewScreen), findsOneWidget);
      expect(examiner.loaded, contains(_asset('ex_end')));
      final saved = await _savedProgress();
      final session = saved.speakingSessions.single;
      expect(session.mode, SpeakingSession.timedMode);
      expect(saved.totalXp, XpRules.completedSpeakingTest);
      expect(session.answers.where((a) => a.isLongTurn), hasLength(1));
      expect(session.answers.map((a) => a.part).toSet(), {1, 2, 3});
      expect((await _savedAttempts()).single.notes, isEmpty);
      _expectNoBands(tester);
    });

    testWidgets('an interruption keeps the partial answer; re-record or go '
        'on', (tester) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.speakingTest());
      final examiner = _examinerAudio();
      for (var i = 0; i < 3; i++) {
        examiner.complete();
        await tester.pump();
        await tester.pump();
      }
      expect(_recorder.isRecording, isTrue);
      await _wait(tester, const Duration(seconds: 6));
      _background(tester);
      await tester.pump();
      await tester.pump();
      expect(_recorder.isRecording, isFalse);
      _resume(tester);
      await tester.pump();
      expect(find.text('Recording stopped'), findsOneWidget);
      expect(find.byKey(const ValueKey('reRecordAnswer')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('reRecordAnswer')));
      expect(_recorder.isRecording, isTrue);
      expect(_store.deleted, hasLength(1));
      await _tap(tester, find.byKey(const ValueKey('finishedAnswer')));
      expect(examiner.current, _asset('p1_home_q2'));
    });
  });

  group('self-review', () {
    testWidgets('checks, playback and saved ticks; never a score', (
      tester,
    ) async {
      await _launchApp(tester, attempts: [_attempt()]);
      await _go(tester, AppRoutes.speakingReview('a1'));
      expect(find.text(NoAiFeedbackBanner.text), findsOneWidget);
      expect(
        find.text('Shorter than usual  ·  Aim for 1:30–2:00'),
        findsNothing,
      );
      expect(find.textContaining('Aim for 1:30–2:00'), findsOneWidget);
      expect(find.text('Long pause at 0:12 (4 s)'), findsOneWidget);
      expect(find.text(CutShort.timeLimit.label), findsOneWidget);
      expect(find.textContaining('Under a minute'), findsOneWidget);

      final play = find.byKey(const ValueKey('play-p1_home_q1'));
      await tester.scrollUntilVisible(
        play,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(play);
      await tester.pump();
      expect(FakeSpeakingAudio.instances.last.current, 'mem/p1_home_q1.m4a');

      final tick = find.byKey(const ValueKey('tick-pronunciation-1'));
      await tester.scrollUntilVisible(
        tick,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(tick);
      await tester.pumpAndSettle();
      await tester.tap(tick);
      await tester.pumpAndSettle();
      final saved = (await _savedAttempts()).single;
      expect(saved.selfAssessment[SpeakingCriterion.pronunciation], {1});
      _expectNoBands(tester);
      expect(find.textContaining(RegExp(r'\d\.\d')), findsNothing);
    });

    testWidgets('"Delete my recordings" removes the audio and keeps the '
        'checks', (tester) async {
      await _launchApp(tester, attempts: [_attempt()]);
      await _go(tester, AppRoutes.profile);
      final row = find.byKey(const ValueKey('deleteRecordings'));
      await tester.scrollUntilVisible(
        row,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete recordings'));
      await tester.pumpAndSettle();
      expect(_store.deletedAll, 1);
      final attempt = (await _savedAttempts()).single;
      expect(attempt.hasRecordings, isFalse);
      expect(attempt.answers, hasLength(3));
      expect(attempt.answers[1].silences, isNotEmpty);
    });
  });

  testWidgets('Progress and Home show sessions, speaking time and the latest '
      'checks', (tester) async {
    final p = const ProgressState().withSpeakingSession(
      SpeakingSession(
        id: 's1',
        mode: 'timed',
        date: _today,
        minutes: 13,
        xp: 20,
        answers: [
          const SpeakingAnswerSummary(
            questionId: 'p1_home_q1',
            part: 1,
            duration: Duration(seconds: 30),
          ),
          const SpeakingAnswerSummary(
            questionId: 'p2_skill',
            part: 2,
            duration: Duration(seconds: 102),
            isLongTurn: true,
            longSilences: 2,
          ),
        ],
      ),
    );
    await _launchApp(tester, progress: p);
    const checks = 'Part 2 talk 1:42 · 2 long pauses';
    expect(find.byKey(const ValueKey('skillDetail-speaking')), findsOneWidget);
    expect(find.text('2:12 speaking · $checks'), findsOneWidget);

    await _go(tester, AppRoutes.progress);
    final card = find.byKey(const ValueKey('speakingCard'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('1 session')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('2:12')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text(checks)),
      findsOneWidget,
    );
  });

  group('layout at 320px', () {
    Future<void> pump(
      WidgetTester tester,
      Widget screen, {
      required bool rtl,
    }) async {
      _reset(attempts: [_attempt()]);
      tester.view.physicalSize = const Size(320, 640) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scrollThrough(WidgetTester tester) async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 8; i++) {
        _expectNoBands(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(list, const Offset(0, -400));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    /// Scrolls until [finder] is built (either way), then into view.
    Future<void> reveal(WidgetTester tester, Finder finder) async {
      final list = find.byType(Scrollable).first;
      if (finder.evaluate().isEmpty) {
        try {
          await tester.scrollUntilVisible(finder, 200, scrollable: list);
        } on StateError {
          await tester.scrollUntilVisible(finder, -200, scrollable: list);
        }
      }
      await tester.ensureVisible(finder);
      await tester.pump();
    }

    for (final rtl in [false, true]) {
      final dir = rtl ? 'RTL' : 'LTR';

      testWidgets('hub and self-review ($dir)', (tester) async {
        await pump(tester, const SpeakingHubScreen(), rtl: rtl);
        await scrollThrough(tester);
        await pump(
          tester,
          const SpeakingReviewScreen(attemptId: 'a1'),
          rtl: rtl,
        );
        await scrollThrough(tester);
      });

      testWidgets('practice while recording, confidence prompts ($dir)', (
        tester,
      ) async {
        await pump(
          tester,
          const SpeakingPracticeScreen(
            mode: SpeakingMode.confidence,
            part: SpeakingPart.part2,
            setId: 'p2_place',
          ),
          rtl: rtl,
        );
        final record = find.byKey(const ValueKey('startRecording'));
        await reveal(tester, record);
        await tester.tap(record);
        await tester.pump();
        await scrollThrough(tester);
        final stop = find.byKey(const ValueKey('stopRecording'));
        await reveal(tester, stop);
        await tester.tap(stop);
        await tester.pump();
        await scrollThrough(tester);
      });

      testWidgets('timed test preparing and recording ($dir)', (tester) async {
        await pump(tester, const SpeakingTestScreen(), rtl: rtl);
        final examiner = _examinerAudio();
        examiner.complete();
        await tester.pump();
        expect(tester.takeException(), isNull);
        examiner.complete();
        await tester.pump();
        examiner.complete();
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(const ValueKey('recordingIndicator')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        _now = _now.add(const Duration(minutes: 5));
        await tester.tap(find.byKey(const ValueKey('finishedAnswer')));
        await tester.pump();
        examiner.complete();
        await tester.pump();
        examiner.complete();
        await tester.pump();
        expect(find.byKey(const ValueKey('preparing')), findsOneWidget);
        await scrollThrough(tester);
      });
    }
  });
}
