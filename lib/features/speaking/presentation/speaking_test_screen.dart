import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/widgets.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import '../domain/speaking_devices.dart';
import 'answer_capture.dart';
import 'speaking_providers.dart';
import 'speaking_session_saver.dart';
import 'widgets/mic_permission_gate.dart';
import 'widgets/speaking_widgets.dart';

/// Timings of the Timed test.
abstract final class TestTimings {
  /// Parts 1 and 3 each move on once this much time has passed.
  static const partLength = Duration(minutes: 5);
  static const preparation = Duration(minutes: 1);
  static const longTurn = Duration(minutes: 2);

  /// A long turn shorter than this gets a gentle note.
  static const longTurnMinimum = Duration(minutes: 1);

  /// The longest answer the recording allows, by kind.
  static const part1Answer = Duration(seconds: 60);
  static const roundingOffAnswer = Duration(seconds: 30);
  static const part3Answer = Duration(seconds: 90);
}

/// One step of the test.
sealed class _Step {
  const _Step(this.part);

  final SpeakingPart part;
}

/// The examiner says something; nothing is recorded.
class _Say extends _Step {
  const _Say(super.part, this.line);

  final ExaminerLine line;
}

/// The examiner asks; recording starts when the question ends.
class _Ask extends _Step {
  const _Ask(super.part, this.question, this.limit);

  final SpeakingQuestion question;
  final Duration limit;
}

/// One minute to prepare the long turn, with notes.
class _Prepare extends _Step {
  const _Prepare(this.card) : super(SpeakingPart.part2);

  final CueCard card;
}

/// The long turn: up to two minutes, then "Thank you".
class _LongTurn extends _Step {
  const _LongTurn(this.card) : super(SpeakingPart.part2);

  final CueCard card;
}

/// The test as the examiner runs it, for [card].
List<_Step> _plan(SpeakingContent c, CueCard card) => [
  _Say(SpeakingPart.part1, c.line('ex_intro')),
  for (final t in c.part1) ...[
    _Say(SpeakingPart.part1, t.intro),
    for (final q in t.questions)
      _Ask(SpeakingPart.part1, q, TestTimings.part1Answer),
  ],
  _Say(SpeakingPart.part2, c.line('ex_part2_intro')),
  _Say(SpeakingPart.part2, card.topic),
  _Prepare(card),
  _LongTurn(card),
  _Ask(SpeakingPart.part2, card.roundingOff, TestTimings.roundingOffAnswer),
  _Say(SpeakingPart.part3, card.part3Intro),
  for (final q in card.part3Questions)
    _Ask(SpeakingPart.part3, q, TestTimings.part3Answer),
  // Not in a part's time box: always said.
  _Say(SpeakingPart.part2, c.line('ex_end')),
];

/// The Timed test, outside the tab shell: the real format, about 11–14
/// minutes. No hints and no animations.
class SpeakingTestScreen extends ConsumerWidget {
  const SpeakingTestScreen({super.key, this.transcript = false});

  final bool transcript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(speakingContentProvider);
    final progress = ref.watch(progressControllerProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.speakingHub);
    if (content.hasError && !content.isLoading) {
      return SessionMessageScaffold(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load the test",
        message: 'Try again in a moment.',
        onBack: back,
        onRetry: () => ref.invalidate(speakingContentProvider),
      );
    }
    final c = content.value;
    final p = progress.value;
    if (c == null || p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // A different cue card each time.
    final done = p.speakingSessions
        .where((s) => s.mode == SpeakingSession.timedMode)
        .length;
    final card = c.cueCards[done % c.cueCards.length];
    return MediaQuery(
      // Timed exam screens have no animations.
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: _TestSession(content: c, card: card, transcript: transcript),
    );
  }
}

enum _Phase {
  /// Before the microphone check.
  waiting,
  examinerSpeaking,
  preparing,
  recording,

  /// An interruption stopped things; the learner chooses how to go on.
  interrupted,
  saving,
}

class _TestSession extends ConsumerStatefulWidget {
  const _TestSession({
    required this.content,
    required this.card,
    required this.transcript,
  });

  final SpeakingContent content;
  final CueCard card;
  final bool transcript;

  @override
  ConsumerState<_TestSession> createState() => _TestSessionState();
}

class _TestSessionState extends ConsumerState<_TestSession>
    with WidgetsBindingObserver {
  late final DateTime Function() _clock = ref.read(clockProvider);
  late final DateTime _startedAt = _clock();
  late final String _attemptId =
      'speaking-${_startedAt.microsecondsSinceEpoch}';
  late final List<_Step> _steps = _plan(widget.content, widget.card);
  late final SpeakingRecorder _recorder = ref.read(
    speakingRecorderFactoryProvider,
  )();
  late final SpeakingAudio _examiner = ref.read(speakingAudioFactoryProvider)();
  late final AnswerCapture _capture = AnswerCapture(
    recorder: _recorder,
    store: ref.read(recordingStoreProvider),
    attemptId: _attemptId,
    clock: _clock,
    transcriber: widget.transcript
        ? ref.read(speechTranscriberFactoryProvider)()
        : null,
  );
  StreamSubscription<void>? _completed;
  final _notes = TextEditingController();

  var _index = 0;
  var _phase = _Phase.waiting;
  final _answers = <RecordedAnswer>[];

  /// Questions the learner asked to hear again (once each).
  final _repeated = <String>{};

  /// When each timed part began.
  final _partStarted = <SpeakingPart, DateTime>{};
  DateTime? _prepEndsAt;

  /// After the examiner finishes, what happens next.
  VoidCallback? _afterSpeaking;

  /// An interruption kept part of this answer.
  RecordedAnswer? _partial;
  Timer? _ticker;

  _Step get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _completed = _examiner.completed.listen((_) => _onExaminerDone());
    _capture.addListener(_onCapture);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _completed?.cancel();
    _capture
      ..removeListener(_onCapture)
      ..discard()
      ..dispose();
    _examiner.dispose();
    _recorder.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onCapture() {
    if (mounted) setState(() {});
  }

  void _begin() {
    if (_phase != _Phase.waiting || !mounted) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _run();
  }

  // ------------------------------------------------------------ flow

  /// Whether [part]'s time is up (Parts 1 and 3 only).
  bool _partOver(SpeakingPart part) {
    if (part == SpeakingPart.part2) return false;
    final started = _partStarted[part];
    return started != null &&
        _clock().difference(started) >= TestTimings.partLength;
  }

  Future<void> _run() async {
    if (!mounted) return;
    final step = _step;
    switch (step) {
      case _Say(:final line):
        _speak(line, then: _next);
      case _Ask(:final question):
        _partStarted.putIfAbsent(step.part, _clock);
        _speak(question, then: () => _startRecording(question));
      case _Prepare():
        setState(() {
          _phase = _Phase.preparing;
          _prepEndsAt = _clock().add(TestTimings.preparation);
        });
      case _LongTurn(:final card):
        _speak(
          widget.content.line('ex_part2_start'),
          then: () => _startRecording(card.longTurn, isLongTurn: true),
        );
    }
  }

  /// Moves to the next step, skipping what's left of Part 1 or Part 3 once
  /// its time is up.
  Future<void> _next() async {
    if (!mounted) return;
    var i = _index + 1;
    // Part 2 is never cut, and the closing line is filed under it.
    while (i < _steps.length && _partOver(_steps[i].part)) {
      i++;
    }
    if (i >= _steps.length) return _finish();
    setState(() => _index = i);
    await _run();
  }

  Future<void> _speak(ExaminerLine line, {required VoidCallback then}) async {
    setState(() {
      _phase = _Phase.examinerSpeaking;
      _afterSpeaking = then;
    });
    try {
      await _examiner.loadAsset(line.audioAsset);
      await _examiner.play();
    } catch (_) {
      // Without the audio, carry on rather than get stuck.
      _onExaminerDone();
    }
  }

  void _onExaminerDone() {
    if (!mounted || _phase != _Phase.examinerSpeaking) return;
    final then = _afterSpeaking;
    _afterSpeaking = null;
    then?.call();
  }

  Future<void> _startRecording(
    SpeakingQuestion question, {
    bool isLongTurn = false,
  }) async {
    setState(() => _phase = _Phase.recording);
    await _capture.start(question, isLongTurn: isLongTurn);
  }

  Duration get _limit => switch (_step) {
    _Ask(:final limit) => limit,
    _ => TestTimings.longTurn,
  };

  void _tick() {
    if (!mounted) return;
    switch (_phase) {
      case _Phase.preparing:
        final ends = _prepEndsAt;
        if (ends != null && !_clock().isBefore(ends)) {
          _prepEndsAt = null;
          _next();
        } else {
          setState(() {});
        }
      case _Phase.recording:
        if (_capture.isRecording && _capture.elapsed >= _limit) {
          _finishAnswer(cutShort: CutShort.timeLimit);
        } else {
          setState(() {});
        }
      case _:
        break;
    }
  }

  /// The learner finished, or the time ran out ([cutShort]).
  Future<void> _finishAnswer({CutShort? cutShort}) async {
    if (!_capture.isRecording) return;
    final answer = await _capture.stop(cutShort: cutShort);
    if (answer != null) _answers.add(answer);
    if (!mounted) return;
    if (_step is _LongTurn) {
      _speak(widget.content.line('ex_part2_stop'), then: _next);
    } else {
      await _next();
    }
  }

  /// "I've finished": a long turn under a minute gets a gentle note first.
  Future<void> _onFinished() async {
    if (_step is _LongTurn && _capture.elapsed < TestTimings.longTurnMinimum) {
      final keepGoing = await showDialog<bool>(
        context: context,
        // Timed exam screens have no animations.
        animationStyle: AnimationStyle.noAnimation,
        builder: (context) => AlertDialog(
          key: const ValueKey('underAMinute'),
          title: const Text('Keep going?'),
          content: const Text(
            "You've spoken for less than a minute. In the test, the "
            'examiner would usually let you talk for up to 2 minutes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("I've finished"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keep talking'),
            ),
          ],
        ),
      );
      if ((keepGoing ?? true) || !mounted) return;
    }
    await _finishAnswer();
  }

  /// "Could you repeat the question?": once per question, like asking the
  /// examiner.
  Future<void> _repeat() async {
    final step = _step;
    if (step is! _Ask || _repeated.contains(step.question.id)) return;
    _repeated.add(step.question.id);
    await _capture.discard();
    _speak(step.question, then: () => _startRecording(step.question));
  }

  // ------------------------------------------------------------ interruptions

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    switch (_phase) {
      case _Phase.recording:
        _interruptRecording();
      case _Phase.examinerSpeaking:
        _examiner.pause();
        setState(() {
          _partial = null;
          _phase = _Phase.interrupted;
        });
      case _:
        break;
    }
  }

  /// Stops safely and keeps what was recorded. The phase changes first, so
  /// the next lifecycle events (inactive, hidden, paused) do nothing.
  Future<void> _interruptRecording() async {
    setState(() {
      _partial = null;
      _phase = _Phase.interrupted;
    });
    final answer = await _capture.stop(cutShort: CutShort.interrupted);
    if (mounted) setState(() => _partial = answer);
  }

  /// Keep the partial answer (if any) and go on.
  Future<void> _continueAfterInterruption() async {
    final partial = _partial;
    _partial = null;
    if (partial == null) {
      // The examiner was speaking: say it again.
      await _run();
      return;
    }
    _answers.add(partial);
    if (_step is _LongTurn) {
      _speak(widget.content.line('ex_part2_stop'), then: _next);
    } else {
      await _next();
    }
  }

  /// Throw the partial answer away and record it again.
  Future<void> _reRecord() async {
    final partial = _partial;
    _partial = null;
    if (partial?.path case final path?) {
      await ref.read(recordingStoreProvider).delete(path);
    }
    final step = _step;
    switch (step) {
      case _Ask(:final question):
        await _startRecording(question);
      case _LongTurn(:final card):
        await _startRecording(card.longTurn, isLongTurn: true);
      case _:
        await _run();
    }
  }

  // ------------------------------------------------------------ end

  Future<void> _finish() async {
    setState(() => _phase = _Phase.saving);
    _ticker?.cancel();
    final attempt = SpeakingAttempt(
      id: _attemptId,
      mode: SpeakingMode.timed,
      startedAt: _startedAt,
      finishedAt: _clock(),
      answers: _answers,
      notes: _notes.text.trim(),
      transcriptOn: widget.transcript,
    );
    await saveSpeakingSession(ref, attempt);
    if (mounted) context.pushReplacement(AppRoutes.speakingReview(_attemptId));
  }

  void _exit() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.speakingHub);

  Future<void> _confirmLeave() async {
    if (_phase == _Phase.waiting) return _exit();
    final leave = await showConfirmDialog(
      context,
      title: 'Leave the test?',
      message: "Your answers in this test won't be kept.",
      confirmLabel: 'Leave',
    );
    if (!leave || !mounted) return;
    await _examiner.pause();
    await _capture.discard();
    final store = ref.read(recordingStoreProvider);
    for (final a in [..._answers, ?_partial]) {
      if (a.path case final path?) await store.delete(path);
    }
    if (mounted) _exit();
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final part = _phase == _Phase.waiting ? null : _step.part;
    final isEnd = _index == _steps.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: TitledSessionTopBar(
          title: part == null || isEnd
              ? 'Timed test'
              : 'Timed test · ${part.label}',
          closeTooltip: 'Close the test',
          onClose: _confirmLeave,
          trailing: _phase == _Phase.preparing
              ? TimerPill(
                  key: const ValueKey('prepTimer'),
                  remaining: _prepLeft,
                  warningAt: const Duration(seconds: 10),
                )
              : null,
        ),
        body: MicPermissionGate(
          recorder: _recorder,
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
              return _body();
            },
          ),
        ),
        bottomNavigationBar: _bottom(),
      ),
    );
  }

  Duration get _prepLeft {
    final ends = _prepEndsAt;
    if (ends == null) return Duration.zero;
    final left = ends.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  Widget? _bottom() {
    switch (_phase) {
      case _Phase.recording:
        final step = _step;
        final canRepeat = step is _Ask && !_repeated.contains(step.question.id);
        return StickyActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canRepeat) ...[
                AppButton.outline(
                  key: const ValueKey('repeatQuestion'),
                  label: 'Could you repeat the question?',
                  onPressed: _repeat,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton.primary(
                key: const ValueKey('finishedAnswer'),
                label: "I've finished",
                onPressed: _onFinished,
              ),
            ],
          ),
        );
      case _Phase.interrupted:
        return StickyActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_partial != null) ...[
                AppButton.outline(
                  key: const ValueKey('reRecordAnswer'),
                  label: 'Re-record this answer',
                  onPressed: _reRecord,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton.primary(
                key: const ValueKey('continueTest'),
                label: 'Continue',
                onPressed: _continueAfterInterruption,
              ),
            ],
          ),
        );
      case _:
        return null;
    }
  }

  Widget _body() {
    final step = _step;
    final card = switch (step) {
      _Prepare(:final card) || _LongTurn(:final card) => card,
      _ => null,
    };
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        switch (_phase) {
          _Phase.waiting ||
          _Phase.saving => const Center(child: CircularProgressIndicator()),
          _Phase.examinerSpeaking => const _Status(
            key: ValueKey('examinerSpeaking'),
            icon: Icons.record_voice_over_outlined,
            title: 'Listen to the examiner',
          ),
          _Phase.preparing => const _Status(
            key: ValueKey('preparing'),
            icon: Icons.edit_note_rounded,
            title: 'Prepare your talk',
            message:
                'You have one minute to think about what to say. Notes '
                'are optional.',
          ),
          _Phase.recording => Center(
            child: RecordingIndicator(elapsed: _capture.elapsed),
          ),
          _Phase.interrupted => _Status(
            key: const ValueKey('interrupted'),
            icon: Icons.pause_circle_outline_rounded,
            title: _partial == null ? 'The test paused' : 'Recording stopped',
            message: _partial == null
                ? 'Something interrupted the test. Continue when you are '
                      'ready; the examiner will repeat what was said.'
                : 'Something interrupted the recording. We kept what you '
                      'said before it stopped.',
          ),
        },
        if (card != null) ...[
          const SizedBox(height: AppSpacing.md),
          CueCardView(card: card),
        ],
        if (step is _Prepare || step is _LongTurn) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('notes'),
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            readOnly: step is _LongTurn,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
        ],
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSm,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
