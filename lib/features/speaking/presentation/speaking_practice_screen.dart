import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/speaking.dart';
import '../domain/speaking_attempt.dart';
import '../domain/speaking_devices.dart';
import 'answer_capture.dart';
import 'speaking_providers.dart';
import 'speaking_session_saver.dart';
import 'widgets/mic_permission_gate.dart';
import 'widgets/recorder_panel.dart';
import 'widgets/speaking_widgets.dart';

/// Longest recording in Practice and Confidence; the Part 2 long turn
/// stops at 2:00 as in the test.
const _maxAnswer = Duration(minutes: 3);
const longTurnLimit = Duration(minutes: 2);

/// Practice or Confidence mode on one Part 1 topic, or one cue card's Part
/// 2 or Part 3. One question at a time, outside the tab shell.
class SpeakingPracticeScreen extends ConsumerWidget {
  const SpeakingPracticeScreen({
    super.key,
    required this.mode,
    required this.part,
    required this.setId,
    this.transcript = false,
  });

  final SpeakingMode mode;
  final SpeakingPart part;

  /// A Part 1 topic id, or a cue card id for Parts 2 and 3.
  final String setId;
  final bool transcript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(speakingContentProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.speakingHub);
    if (content.hasError && !content.isLoading) {
      return SessionMessageScaffold(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load these questions",
        message: 'Try again in a moment.',
        onBack: back,
        onRetry: () => ref.invalidate(speakingContentProvider),
      );
    }
    final c = content.value;
    if (c == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final questions = switch (part) {
      SpeakingPart.part1 =>
        c.part1.where((t) => t.id == setId).firstOrNull?.questions,
      SpeakingPart.part2 => switch (c.cueCard(setId)) {
        final card? => [card.longTurn, card.roundingOff],
        null => null,
      },
      SpeakingPart.part3 => c.cueCard(setId)?.part3Questions,
    };
    if (questions == null || questions.isEmpty) {
      return SessionMessageScaffold(
        icon: Icons.search_off_rounded,
        title: 'Questions not found',
        message: 'Pick a topic from the Speaking hub.',
        onBack: back,
      );
    }
    return _PracticeSession(
      key: ValueKey('$mode-$part-$setId'),
      content: c,
      mode: mode,
      part: part,
      card: part == SpeakingPart.part1 ? null : c.cueCard(setId),
      questions: questions,
      transcript: transcript,
    );
  }
}

class _PracticeSession extends ConsumerStatefulWidget {
  const _PracticeSession({
    super.key,
    required this.content,
    required this.mode,
    required this.part,
    required this.card,
    required this.questions,
    required this.transcript,
  });

  final SpeakingContent content;
  final SpeakingMode mode;
  final SpeakingPart part;
  final CueCard? card;
  final List<SpeakingQuestion> questions;
  final bool transcript;

  @override
  ConsumerState<_PracticeSession> createState() => _PracticeSessionState();
}

class _PracticeSessionState extends ConsumerState<_PracticeSession>
    with WidgetsBindingObserver {
  late final DateTime Function() _clock = ref.read(clockProvider);
  late final DateTime _startedAt = _clock();
  late final String _attemptId =
      'speaking-${_startedAt.microsecondsSinceEpoch}';
  late final SpeakingRecorder _recorder = ref.read(
    speakingRecorderFactoryProvider,
  )();
  late final SpeakingAudio _examiner = ref.read(speakingAudioFactoryProvider)();
  late final SpeakingAudio _playback = ref.read(speakingAudioFactoryProvider)();
  late final AnswerCapture _capture = AnswerCapture(
    recorder: _recorder,
    store: ref.read(recordingStoreProvider),
    attemptId: _attemptId,
    clock: _clock,
    transcriber: widget.transcript
        ? ref.read(speechTranscriberFactoryProvider)()
        : null,
  );
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _notes = TextEditingController();

  var _index = 0;
  final _answers = <String, RecordedAnswer>{};
  var _examinerPlaying = false;
  var _playbackPlaying = false;
  var _interrupted = false;
  var _saving = false;
  var _ready = false;
  Timer? _ticker;

  bool get _confidence => widget.mode == SpeakingMode.confidence;
  SpeakingQuestion get _question => widget.questions[_index];
  bool get _isLongTurn => _question.id == widget.card?.id;
  bool get _isLast => _index == widget.questions.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscriptions
      ..add(
        _examiner.playingStream.listen((p) {
          if (mounted) setState(() => _examinerPlaying = p);
        }),
      )
      ..add(
        _playback.playingStream.listen((p) {
          if (mounted) setState(() => _playbackPlaying = p);
        }),
      );
    _capture.addListener(_onCapture);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _capture
      ..removeListener(_onCapture)
      ..discard()
      ..dispose();
    _examiner.dispose();
    _playback.dispose();
    _recorder.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onCapture() {
    if (mounted) setState(() {});
  }

  /// Called once the microphone may be used.
  void _begin() {
    if (_ready || !mounted) return;
    setState(() => _ready = true);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _playQuestion();
  }

  void _tick() {
    if (!mounted || !_capture.isRecording) return;
    final limit = _isLongTurn ? longTurnLimit : _maxAnswer;
    if (_capture.elapsed >= limit) {
      _stop(cutShort: CutShort.timeLimit);
    } else if (!_confidence) {
      setState(() {});
    }
  }

  /// A call or the app going into the background stops the recording; what
  /// was said is kept.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _capture.isRecording) {
      _stop(cutShort: CutShort.interrupted);
      setState(() => _interrupted = true);
    }
  }

  String get _questionAsset =>
      _isLongTurn ? widget.card!.topic.audioAsset : _question.audioAsset;

  Future<void> _playQuestion() async {
    await _playback.pause();
    try {
      await _examiner.loadAsset(_questionAsset);
      await _examiner.play();
    } catch (_) {
      // The question is on screen; the audio is a help.
    }
  }

  Future<void> _record() async {
    await _examiner.pause();
    await _playback.pause();
    final old = _answers[_question.id];
    setState(() => _interrupted = false);
    await _capture.start(_question, isLongTurn: _isLongTurn);
    if (old?.path case final path?) {
      await ref.read(recordingStoreProvider).delete(path);
    }
  }

  Future<void> _stop({CutShort? cutShort}) async {
    final answer = await _capture.stop(cutShort: cutShort);
    if (answer != null && mounted) {
      setState(() => _answers[answer.questionId] = answer);
    }
  }

  Future<void> _togglePlayback() async {
    if (_playbackPlaying) return _playback.pause();
    final path = _answers[_question.id]?.path;
    if (path == null) return;
    await _examiner.pause();
    await _playback.loadRecording(path);
    await _playback.play();
  }

  Future<void> _next() async {
    if (_capture.isRecording) await _stop();
    if (_isLast) return _finish();
    await _examiner.pause();
    await _playback.pause();
    setState(() {
      _index++;
      _interrupted = false;
    });
    await _playQuestion();
  }

  Future<void> _finish() async {
    if (_capture.isRecording) await _stop();
    await _examiner.pause();
    await _playback.pause();
    if (_answers.isEmpty) {
      if (mounted) _exit();
      return;
    }
    setState(() => _saving = true);
    final attempt = SpeakingAttempt(
      id: _attemptId,
      mode: widget.mode,
      startedAt: _startedAt,
      finishedAt: _clock(),
      answers: [for (final q in widget.questions) ?_answers[q.id]],
      notes: _notes.text.trim(),
      transcriptOn: widget.transcript,
    );
    await saveSpeakingSession(ref, attempt);
    if (mounted) context.pushReplacement(AppRoutes.speakingReview(_attemptId));
  }

  void _exit() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.speakingHub);

  Future<void> _confirmLeave() async {
    if (_answers.isEmpty && !_capture.isRecording) return _exit();
    final leave = await showConfirmDialog(
      context,
      title: 'Leave practice?',
      message: "The answers you've recorded in this session won't be kept.",
      confirmLabel: 'Leave',
    );
    if (!leave || !mounted) return;
    await _capture.discard();
    final store = ref.read(recordingStoreProvider);
    for (final a in _answers.values) {
      if (a.path case final path?) await store.delete(path);
    }
    if (mounted) _exit();
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.mode.label} · ${widget.part.label}';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: TitledSessionTopBar(
          title: title,
          closeTooltip: 'Close practice',
          onClose: _confirmLeave,
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
        bottomNavigationBar: _ready
            ? StickyActionBar(
                child: AppButton.primary(
                  key: const ValueKey('nextQuestion'),
                  label: _isLast ? 'Finish' : 'Next question',
                  trailingIcon: _isLast ? null : Icons.arrow_forward_rounded,
                  isLoading: _saving,
                  onPressed: _next,
                ),
              )
            : null,
      ),
    );
  }

  Widget _body() {
    final q = _question;
    final card = widget.card;
    return ListView(
      key: ValueKey('question-$_index'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'Question ${_index + 1} of ${widget.questions.length}',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isLongTurn && card != null)
          CueCardView(card: card)
        else
          AppCard(
            key: ValueKey('questionText-${q.id}'),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Text(
              q.text,
              style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('playQuestion'),
            onPressed: _capture.isRecording
                ? null
                : _examinerPlaying
                ? _examiner.pause
                : _playQuestion,
            icon: Icon(
              _examinerPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
              size: 18,
            ),
            label: Text(
              _examinerPlaying ? 'Pause the question' : 'Play the question',
            ),
          ),
        ),
        if (_confidence) ...[
          const SizedBox(height: AppSpacing.xs),
          GentlePrompts(part: q.part),
        ],
        if (_isLongTurn) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('notes'),
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'A few words to plan what you will say',
            ),
          ),
        ],
        if (_interrupted) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            key: const ValueKey('interrupted'),
            type: InfoBannerType.warning,
            title: 'Recording stopped',
            message:
                'Something interrupted the recording. We kept what you said '
                'before it stopped.',
            actionLabel: 'Re-record this answer',
            onAction: _record,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        RecorderPanel(
          recording: _capture.isRecording,
          elapsed: _capture.elapsed,
          answer: _answers[q.id],
          showTimes: !_confidence,
          playing: _playbackPlaying,
          onRecord: _record,
          onStop: _stop,
          onPlay: _togglePlayback,
          onReRecord: _record,
        ),
        if (widget.transcript) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            '${TranscriptCopy.label}. ${TranscriptCopy.deviceNote}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
