import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bandwise/app.dart';
import 'package:bandwise/core/router/app_router.dart';
import 'package:bandwise/core/router/app_routes.dart';
import 'package:bandwise/core/utils/clock.dart';
import 'package:bandwise/core/widgets/widgets.dart';
import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/listening/data/asset_listening_repository.dart';
import 'package:bandwise/features/listening/domain/listening.dart';
import 'package:bandwise/features/listening/domain/listening_audio.dart';
import 'package:bandwise/features/listening/domain/listening_repository.dart';
import 'package:bandwise/features/listening/presentation/listening_hub_screen.dart';
import 'package:bandwise/features/listening/presentation/listening_providers.dart';
import 'package:bandwise/features/onboarding/domain/onboarding_state.dart';
import 'package:bandwise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:bandwise/features/progress/domain/progress_state.dart';
import 'package:bandwise/features/progress/domain/skill_insights.dart';
import 'package:bandwise/features/review/domain/review_planner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 15);

const _onboarding = OnboardingState(
  step: OnboardingStep.plan,
  completed: true,
  targetBand: TargetBand.band7,
  level: EnglishLevel.intermediate,
  dailyMinutes: 20,
  placementSkipped: true,
);

/// Each line lasts 3 s and is followed by 1 s of silence, so line i starts
/// at i × 4 s.
Map<String, dynamic> _timestamps(Map<String, dynamic> script) => {
  'lines': [
    for (final (i, l) in (script['lines'] as List).indexed)
      {'id': l['id'], 'startMs': i * 4000, 'endMs': i * 4000 + 3000},
  ],
};

ListeningSet _load(String id, {bool withAudio = true}) {
  Map<String, dynamic> read(String file) =>
      jsonDecode(File('assets/listening/$id/$file').readAsStringSync())
          as Map<String, dynamic>;
  final script = read('script.json');
  return parseListeningSet(
    script: script,
    questions: read('questions.json'),
    timestamps: withAudio ? _timestamps(script) : null,
    audioAsset: 'assets/listening/$id/listening.mp3',
  );
}

final _setA = _load('set_a');
final _setB = _load('set_b');

Duration _startOf(ListeningSet set, String lineId) =>
    set.timings[lineId]!.start;

ListeningQuestion _q(ListeningSet set, int number) =>
    set.questions.firstWhere((q) => q.number == number);

class _FakeRepository implements ListeningRepository {
  _FakeRepository(this.sets);

  final List<ListeningSet> sets;

  @override
  Future<List<ListeningSet>> fetchSets() async => sets;
}

/// Plays nothing; tests move the position and end the recording.
class FakeListeningAudio implements ListeningAudio {
  FakeListeningAudio() {
    instances.add(this);
  }

  static final instances = <FakeListeningAudio>[];

  final _positions = StreamController<Duration>.broadcast(sync: true);
  final _playingChanges = StreamController<bool>.broadcast(sync: true);
  final _completions = StreamController<void>.broadcast(sync: true);

  String? loaded;
  final seeks = <Duration>[];
  var speed = 1.0;
  var disposed = false;

  @override
  var position = Duration.zero;

  @override
  var playing = false;

  @override
  Future<void> load(String asset) async => loaded = asset;

  @override
  Future<void> play() async {
    playing = true;
    _playingChanges.add(true);
  }

  @override
  Future<void> pause() async {
    playing = false;
    _playingChanges.add(false);
  }

  @override
  Future<void> seek(Duration to) async {
    seeks.add(to);
    emit(to);
  }

  @override
  Future<void> setSpeed(double s) async => speed = s;

  /// Playback reached [to].
  void emit(Duration to) {
    position = to;
    _positions.add(to);
  }

  /// The recording played to the end.
  void complete() {
    playing = false;
    _playingChanges.add(false);
    _completions.add(null);
  }

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Stream<bool> get playingStream => _playingChanges.stream;

  @override
  Stream<void> get completed => _completions.stream;

  @override
  Future<void> dispose() async => disposed = true;
}

/// The fake time the session reads. Tests move it forward.
late DateTime _now;

Future<void> _launchApp(
  WidgetTester tester, {
  List<ListeningSet>? sets,
  ProgressState? progress,
}) async {
  _now = DateTime(2026, 10, 15, 9);
  FakeListeningAudio.instances.clear();
  SharedPreferences.setMockInitialValues({
    'onboarding.v1': jsonEncode(_onboarding.toJson()),
    'progress.v1': ?switch (progress) {
      final p? => jsonEncode(p.toJson()),
      null => null,
    },
  });
  tester.view.physicalSize = const Size(390, 1000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(_today),
        clockProvider.overrideWithValue(() => _now),
        listeningRepositoryProvider.overrideWithValue(
          _FakeRepository(sets ?? [_setA, _setB]),
        ),
        listeningAudioFactoryProvider.overrideWithValue(FakeListeningAudio.new),
      ],
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

/// Taps without waiting to settle: sessions tick while counting down.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}

/// Moves the fake clock on and lets the session tick.
Future<void> _wait(WidgetTester tester, Duration d) async {
  _now = _now.add(d);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<ProgressState> _savedProgress() async {
  final raw = (await SharedPreferences.getInstance()).getString('progress.v1');
  return ProgressState.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
}

Finder _card(ListeningQuestion q) => find.byKey(ValueKey('question-${q.id}'));

Future<void> _type(
  WidgetTester tester,
  ListeningQuestion q,
  String text,
) async {
  final field = find.descendant(of: _card(q), matching: find.byType(TextField));
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, text);
  await tester.pump();
}

/// Opens [set] and starts the recording.
Future<FakeListeningAudio> _start(
  WidgetTester tester,
  ListeningSet set, {
  required bool timed,
}) async {
  await _go(tester, AppRoutes.listeningSession(set.id, timed: timed));
  await _tap(tester, find.byKey(const ValueKey('startListening')));
  return FakeListeningAudio.instances.last;
}

/// The end of the line that announces reading time for [group].
Duration _stopOf(ListeningSet set, int group) =>
    set.timings[set.groups[group].readingTimeAfterLineId]!.end;

void main() {
  group('domain', () {
    test('word limits count a phone number or "6th" as one number', () {
      expect(WordLimit.count('07723 418590'), (words: 0, numbers: 1));
      expect(WordLimit.count('6th'), (words: 0, numbers: 1));
      expect(WordLimit.count('Thursday evenings'), (words: 2, numbers: 0));
      expect(WordLimit.count('6th November'), (words: 1, numbers: 1));
    });

    test('completion answers ignore case and digit spacing, not spelling', () {
      final pottery = _q(_setA, 1);
      final phone = _q(_setA, 3);
      final day = _q(_setA, 4);
      expect(pottery.isCorrect('  POTTERY '), isTrue);
      expect(pottery.isCorrect('potery'), isFalse);
      expect(phone.isCorrect('07723418590'), isTrue);
      expect(phone.isCorrect('077 23 41 85 90'), isTrue);
      expect(phone.isCorrect('07723 418950'), isFalse);
      expect(day.isCorrect('Thursdays'), isTrue, reason: 'accepted variant');
      // Over the word limit is wrong even with the answer in it.
      expect(day.isCorrect('on Thursday'), isFalse);
      expect(pottery.isAnswered('  '), isFalse);
    });

    test('choice answers match the option key', () {
      final q = _q(_setB, 21);
      expect(q.isCorrect('B'), isTrue);
      expect(q.isCorrect('A'), isFalse);
      expect(q.correctAnswer, 'B. They had seen the problem for themselves.');
    });

    test('sets parse with unique question ids and reading stops', () {
      expect(_setA.questions.map((q) => q.id), contains('set_a:q1'));
      expect(_setA.hasAudio, isTrue);
      expect(_load('set_a', withAudio: false).hasAudio, isFalse);
      expect([for (final s in _setA.readingStops) s.group.first], [1, 6]);
      expect(_setA.lineAt(const Duration(milliseconds: 4100)), 1);
      // The pause after a line belongs to that line.
      expect(_setA.lineAt(const Duration(milliseconds: 3500)), 0);
      expect(
        _setA.timedLength,
        _setA.audioLength + const Duration(seconds: 30 * 2 + 60),
      );
    });

    test('grading scores by question type', () {
      final grade = ListeningGrade(_setB.questions, {
        'set_b:q21': 'B',
        'set_b:q22': 'A',
        'set_b:q26': 'A',
      });
      expect(grade.correct, 2);
      expect(grade.byType[ListeningQuestionType.multipleChoice]!.correct, 1);
      expect(grade.byType[ListeningQuestionType.matching]!.correct, 1);
    });
  });

  group('progress', () {
    ListeningCompletion completion({
      required int correct,
      bool timed = false,
      List<SavedMistake> mistakes = const [],
    }) => ListeningCompletion(
      attempt: ListeningAttempt(
        setId: 'set_a',
        timed: timed,
        date: _today,
        correct: correct,
        total: 10,
        minutes: 8,
        xp: XpRules.forListening(correct: correct, timedSet: timed),
        byType: {'formCompletion': TypeScore(correct: correct, total: 10)},
      ),
      questionIds: [for (final q in _setA.questions) q.id],
      mistakes: mistakes,
    );

    SavedMistake mistake(String answer) => SavedMistake(
      source: MistakeSource.listening,
      sourceId: 'set_a',
      itemId: 'set_a:q2',
      prompt: 'Surname: ______',
      yourAnswer: answer,
      correctAnswer: 'Halloran',
      explanation: '…',
      savedOn: _today,
    );

    test('an attempt earns XP, minutes and a streak day, and saves '
        'mistakes', () {
      final p = const ProgressState().withListeningAttempt(
        completion(correct: 7, timed: true, mistakes: [mistake('Haloran')]),
      );
      expect(p.listeningAttempts.single.correct, 7);
      expect(p.totalXp, 2 * 7 + 10);
      expect(p.minutesOn(_today), 8);
      expect(p.streak(_today), 1);
      expect(p.mistakes.single.source, MistakeSource.listening);
    });

    test('a new attempt replaces the set\'s saved mistakes', () {
      final p = const ProgressState()
          .withListeningAttempt(
            completion(correct: 5, mistakes: [mistake('Haloran')]),
          )
          .withListeningAttempt(completion(correct: 10));
      expect(p.mistakes, isEmpty);
      expect(p.listeningAttempts, hasLength(2));
    });

    test('attempts survive a save and load', () {
      final p = const ProgressState().withListeningAttempt(
        completion(correct: 6, mistakes: [mistake('Haloran')]),
      );
      final loaded = ProgressState.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(
        loaded.listeningAttempts.single.byType['formCompletion']!.total,
        10,
      );
      expect(loaded.mistakes.single.source, MistakeSource.listening);
    });

    test('mistakes are reviewed only for sets with audio', () {
      final p = const ProgressState().withListeningAttempt(
        completion(correct: 9, mistakes: [mistake('Haloran')]),
      );
      ReviewPlanner planner(ListeningSet set) =>
          ReviewPlanner(course: course, progress: p, listeningSets: [set]);
      final due = planner(_setA).dueOn(_today);
      expect(due.single, isA<ListeningMistakeReviewItem>());
      expect(planner(_load('set_a', withAudio: false)).items, isEmpty);
    });

    test('insights name the weakest type, rule-based', () {
      final insights = ListeningInsights.from([
        for (final (mc, matching) in [(1, 4), (2, 5)])
          ListeningAttempt(
            setId: 'set_b',
            timed: false,
            date: _today,
            correct: mc + matching,
            total: 10,
            minutes: 8,
            xp: 0,
            byType: {
              'multipleChoice': TypeScore(correct: mc, total: 5),
              'matching': TypeScore(correct: matching, total: 5),
            },
          ),
      ]);
      expect(insights.weakestType, ListeningQuestionType.multipleChoice);
      expect(insights.recent.map((p) => p.percent), [50, 70]);
    });
  });

  group('hub', () {
    testWidgets('Practice opens the Listening hub with both recordings', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.practice);
      await tester.tap(find.byKey(const ValueKey('practice-listening')));
      await tester.pumpAndSettle();
      expect(find.byType(ListeningHubScreen), findsOneWidget);
      expect(find.text(_setA.title), findsOneWidget);
      expect(find.text(_setB.title), findsOneWidget);
      // No band anywhere.
      expect(find.textContaining('Band'), findsNothing);
    });

    testWidgets('a recording without audio is listed but disabled', (
      tester,
    ) async {
      await _launchApp(tester, sets: [_setA, _load('set_b', withAudio: false)]);
      await _go(tester, AppRoutes.listeningHub);
      expect(find.textContaining('Audio coming soon'), findsOneWidget);
      final card = tester.widget<SelectionCard>(
        find.byKey(const ValueKey('set-set_b')),
      );
      expect(card.state, SelectionCardState.disabled);
    });

    testWidgets('Start opens the chosen recording in the chosen mode', (
      tester,
    ) async {
      await _launchApp(tester);
      await _go(tester, AppRoutes.listeningHub);
      await tester.tap(find.byKey(const ValueKey('set-set_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mode-timed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start practice'));
      await tester.pumpAndSettle();
      expect(find.text('PART 3 · TIMED'), findsOneWidget);
      expect(find.textContaining('plays once'), findsOneWidget);
      expect(FakeListeningAudio.instances.last.loaded, _setB.audioAsset);
    });
  });

  group('timed', () {
    testWidgets('plays once with reading time, check time, then submits', (
      tester,
    ) async {
      await _launchApp(tester);
      final audio = await _start(tester, _setA, timed: true);
      expect(audio.playing, isTrue);
      // No controls: the recording can't be paused or moved.
      expect(find.byKey(const ValueKey('timedAudioStatus')), findsOneWidget);
      expect(find.byKey(const ValueKey('playPause')), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Check'), findsNothing);

      // The announcement ends: the audio waits for the reading time.
      audio.emit(_stopOf(_setA, 0) + const Duration(milliseconds: 100));
      await tester.pump();
      expect(audio.playing, isFalse);
      expect(find.text('Read questions 1–5 · '), findsNothing);
      expect(find.textContaining('Read questions 1–5'), findsOneWidget);
      expect(find.byKey(const ValueKey('skipReadingTime')), findsNothing);
      await _wait(tester, const Duration(seconds: 29));
      expect(audio.playing, isFalse);
      await _wait(tester, const Duration(seconds: 1));
      expect(audio.playing, isTrue);
      expect(find.byKey(const ValueKey('readingTime')), findsNothing);

      // Exam conditions: no autocorrect or suggestions.
      await _type(tester, _q(_setA, 1), 'pottery');
      final field = tester.widget<TextField>(
        find.descendant(
          of: _card(_q(_setA, 1)),
          matching: find.byType(TextField),
        ),
      );
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(find.text('Correct'), findsNothing);

      audio.emit(_stopOf(_setA, 1) + const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.textContaining('Read questions 6–10'), findsOneWidget);
      await _wait(tester, const Duration(seconds: 30));
      expect(audio.playing, isTrue);

      audio.complete();
      await tester.pump();
      expect(find.byKey(const ValueKey('checkTime')), findsOneWidget);
      expect(find.byType(TimerPill), findsOneWidget);
      await _wait(tester, const Duration(seconds: 61));
      await tester.pumpAndSettle();

      expect(find.text("Time's up"), findsOneWidget);
      expect(find.text('1/10'), findsOneWidget);
      final saved = await _savedProgress();
      expect(saved.listeningAttempts.single.timed, isTrue);
      expect(saved.totalXp, 2 * 1 + XpRules.timedSetBonus);
    });

    testWidgets('timed screens have no animations', (tester) async {
      await _launchApp(tester);
      await _start(tester, _setA, timed: true);
      final context = tester.element(
        find.byKey(const ValueKey('timedAudioStatus')),
      );
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
    });

    testWidgets('leaving asks first and saves nothing', (tester) async {
      await _launchApp(tester);
      await _start(tester, _setA, timed: true);
      await _tap(tester, find.byTooltip('Close practice'));
      expect(find.text('Leave practice?'), findsOneWidget);
      await _tap(tester, find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.byType(ListeningHubScreen), findsNothing);
      expect(FakeListeningAudio.instances.last.disposed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('progress.v1'), isNull);
    });
  });

  group('learning', () {
    testWidgets('reading time can be skipped; Check explains and plays '
        'from the evidence', (tester) async {
      await _launchApp(tester);
      final audio = await _start(tester, _setA, timed: false);
      expect(find.byKey(const ValueKey('audioControls')), findsOneWidget);

      audio.emit(_stopOf(_setA, 0) + const Duration(milliseconds: 100));
      await tester.pump();
      expect(audio.playing, isFalse);
      await _tap(tester, find.byKey(const ValueKey('skipReadingTime')));
      expect(audio.playing, isTrue);
      expect(find.byKey(const ValueKey('readingTime')), findsNothing);

      final q1 = _q(_setA, 1);
      await _type(tester, q1, '  POTTERY');
      await _tap(tester, find.byKey(ValueKey('check-${q1.id}')));
      expect(
        find.descendant(of: _card(q1), matching: find.text('Correct')),
        findsOneWidget,
      );
      await _tap(
        tester,
        find.descendant(of: _card(q1), matching: find.text('Play from here')),
      );
      expect(audio.seeks.last, _startOf(_setA, q1.evidenceLineId));
      expect(audio.playing, isTrue);

      final q2 = _q(_setA, 2);
      await _type(tester, q2, 'Haloran');
      await _tap(tester, find.byKey(ValueKey('check-${q2.id}')));
      expect(
        find.descendant(of: _card(q2), matching: find.text('Not quite')),
        findsOneWidget,
      );
      // Over the word limit is flagged while typing.
      final q4 = _q(_setA, 4);
      await _type(tester, q4, 'on Thursday');
      expect(find.text('Write one word and/or a number'), findsOneWidget);
    });

    testWidgets('pause, back 5 seconds and speed', (tester) async {
      await _launchApp(tester);
      final audio = await _start(tester, _setB, timed: false);
      // Before the first reading-time stop.
      audio.emit(const Duration(milliseconds: 2500));
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('playPause')));
      expect(audio.playing, isFalse);
      await _tap(tester, find.byKey(const ValueKey('back5')));
      expect(audio.seeks.last, Duration.zero);
      await _tap(tester, find.byKey(const ValueKey('speed')));
      expect(audio.speed, 0.75);
    });

    testWidgets('results show the transcript with answers highlighted and '
        'play from any line', (tester) async {
      await _launchApp(tester);
      final audio = await _start(tester, _setB, timed: false);
      final q21 = _q(_setB, 21);
      await _tap(tester, find.byKey(ValueKey('option-${q21.id}-B')));
      final q26 = _q(_setB, 26);
      await _tap(tester, find.byKey(ValueKey('chip-${q26.id}-C')));
      expect(
        find.text('C. check it with the catering manager'),
        findsOneWidget,
      );

      await _tap(tester, find.byKey(const ValueKey('submitListening')));
      expect(
        find.textContaining("The recording hasn't finished yet."),
        findsOneWidget,
      );
      await _tap(tester, find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Your results'), findsOneWidget);
      expect(find.text('1/10'), findsOneWidget);
      expect(find.textContaining('Band'), findsNothing);
      final saved = await _savedProgress();
      expect(saved.listeningAttempts.single.xp, 2);
      // Only answered wrong questions are saved for review.
      expect(saved.mistakes.map((m) => m.itemId), [q26.id]);

      // "Play from here" on a result opens the transcript at its line.
      final result = find.byKey(ValueKey('result-${q26.id}'));
      await _tap(
        tester,
        find.descendant(of: result, matching: find.text('Play from here')),
      );
      await tester.pumpAndSettle();
      expect(audio.seeks.last, _startOf(_setB, q26.evidenceLineId));
      final line = find.byKey(ValueKey('line-${q26.evidenceLineId}'));
      expect(line, findsOneWidget);
      expect(find.text('Q26'), findsOneWidget);

      // Any line plays from its start.
      final other = find.byKey(const ValueKey('line-b005'));
      await tester.ensureVisible(other);
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(audio.seeks.last, _startOf(_setB, 'b005'));
    });
  });

  group('review', () {
    testWidgets('a listening mistake plays its clip and reveals the line', (
      tester,
    ) async {
      final q2 = _q(_setA, 2);
      final progress = const ProgressState().withListeningAttempt(
        ListeningCompletion(
          attempt: ListeningAttempt(
            setId: 'set_a',
            timed: false,
            date: _today,
            correct: 9,
            total: 10,
            minutes: 8,
            xp: 18,
          ),
          questionIds: [q2.id],
          mistakes: [
            SavedMistake(
              source: MistakeSource.listening,
              sourceId: 'set_a',
              itemId: q2.id,
              prompt: q2.prompt,
              yourAnswer: 'Haloran',
              correctAnswer: q2.correctAnswer,
              explanation: q2.explanation,
              savedOn: _today,
            ),
          ],
        ),
      );
      await _launchApp(tester, progress: progress);
      await _go(tester, AppRoutes.review);
      expect(find.textContaining('Listening: ${_setA.title}'), findsOneWidget);
      expect(find.byKey(const ValueKey('clipTranscript')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('playClip')));
      final audio = FakeListeningAudio.instances.last;
      // From the line before the answer.
      final index = _setA.lineIndex(q2.evidenceLineId);
      expect(audio.seeks.last, _startOf(_setA, _setA.lines[index - 1].id));
      expect(audio.playing, isTrue);
      // It stops at the end of the answer's line.
      audio.emit(_setA.timings[q2.evidenceLineId]!.end);
      await tester.pump();
      expect(audio.playing, isFalse);

      await tester.enterText(find.byType(TextField), 'halloran');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsOneWidget);
      expect(find.byKey(const ValueKey('clipTranscript')), findsOneWidget);
    });
  });

  testWidgets('Progress shows listening accuracy after an attempt', (
    tester,
  ) async {
    final progress = const ProgressState().withListeningAttempt(
      ListeningCompletion(
        attempt: ListeningAttempt(
          setId: 'set_b',
          timed: true,
          date: _today,
          correct: 6,
          total: 10,
          minutes: 9,
          xp: 22,
          byType: {
            'multipleChoice': const TypeScore(correct: 2, total: 5),
            'matching': const TypeScore(correct: 4, total: 5),
          },
        ),
        questionIds: const [],
        mistakes: const [],
      ),
    );
    await _launchApp(tester, progress: progress);
    await _go(tester, AppRoutes.progress);
    final card = find.byKey(const ValueKey('listeningCard'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('1 attempt')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(
          'Multiple choice is your '
          'weakest question type lately.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('Band')),
      findsNothing,
    );
  });
}
