import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/listening.dart';
import '../domain/listening_audio.dart';
import 'listening_providers.dart';
import 'widgets/audio_controls.dart';
import 'widgets/listening_question_body.dart';
import 'widgets/listening_results_pane.dart';
import 'widgets/transcript_view.dart';

/// Below this width the results and transcript are tabs; from it up they
/// sit side by side.
const _splitBreakpoint = 840.0;

/// A listening session outside the tab shell: an introduction, the audio
/// with the questions, then results with the transcript.
class ListeningSessionScreen extends ConsumerWidget {
  const ListeningSessionScreen({
    super.key,
    required this.setId,
    required this.mode,
  });

  final String setId;
  final ListeningMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(listeningSetsProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.listeningHub);
    if (sets.hasError && !sets.isLoading) {
      return SessionMessageScaffold(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load this recording",
        message: 'Check your connection and try again.',
        onBack: back,
        onRetry: () => ref.invalidate(listeningSetsProvider),
      );
    }
    final list = sets.value;
    if (list == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final set = list.where((s) => s.id == setId).firstOrNull;
    if (set == null) {
      return SessionMessageScaffold(
        icon: Icons.search_off_rounded,
        title: 'Recording not found',
        message: 'Pick a recording from the Listening hub.',
        onBack: back,
      );
    }
    if (!set.hasAudio) {
      return SessionMessageScaffold(
        icon: Icons.headphones_rounded,
        title: 'Audio not ready yet',
        message: "This recording's audio hasn't been added yet.",
        onBack: back,
      );
    }
    return ListeningSession(
      key: ValueKey('$setId-${mode.name}'),
      set: set,
      mode: mode,
    );
  }
}

enum _Phase {
  /// Instructions and Start.
  intro,

  /// The recording is playing, or paused (reading time, or by the learner
  /// in learning mode).
  listening,

  /// Timed mode: the recording has ended; time to check answers.
  checking,
  submitted,
}

enum _Pane { results, transcript }

class ListeningSession extends ConsumerStatefulWidget {
  const ListeningSession({super.key, required this.set, required this.mode});

  final ListeningSet set;
  final ListeningMode mode;

  @override
  ConsumerState<ListeningSession> createState() => _ListeningSessionState();
}

class _ListeningSessionState extends ConsumerState<ListeningSession>
    with WidgetsBindingObserver {
  late final ListeningSet _set = widget.set;
  late final DateTime Function() _clock;
  late final ListeningAudio _audio;
  final _subscriptions = <StreamSubscription<Object?>>[];

  var _phase = _Phase.intro;
  var _loading = true;
  Object? _loadError;

  var _position = Duration.zero;
  var _playing = false;
  var _speed = 1.0;

  /// Reading-time stops already made or skipped, by index into
  /// [ListeningSet.readingStops].
  final _stopsDone = <int>{};
  var _lastPosition = Duration.zero;

  /// Set while the audio is paused for reading time.
  QuestionGroup? _readingGroup;
  DateTime? _readingEndsAt;

  /// Learning mode: the recording has played to the end.
  var _audioEnded = false;
  DateTime? _checkEndsAt;

  DateTime? _startedAt;
  Timer? _ticker;

  final _responses = <String, String>{};
  final _checked = <String>{};

  var _submitting = false;
  ListeningGrade? _grade;
  var _xp = 0;
  var _autoSubmitted = false;

  var _pane = _Pane.results;
  String? _focusedLineId;
  late final _lineKeys = {for (final l in _set.lines) l.id: GlobalKey()};
  final _questionScroll = ScrollController();
  final _resultsScroll = ScrollController();
  final _transcriptScroll = ScrollController();

  bool get _timed => widget.mode == ListeningMode.timed;
  bool get _submitted => _phase == _Phase.submitted;

  @override
  void initState() {
    super.initState();
    _clock = ref.read(clockProvider);
    _audio = ref.read(listeningAudioFactoryProvider)();
    WidgetsBinding.instance.addObserver(this);
    _subscriptions
      ..add(_audio.positionStream.listen(_onPosition))
      ..add(
        _audio.playingStream.listen((p) {
          if (mounted) setState(() => _playing = p);
        }),
      )
      ..add(_audio.completed.listen((_) => _onEnded()));
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _audio.dispose();
    _questionScroll.dispose();
    _resultsScroll.dispose();
    _transcriptScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _audio.load(_set.audioAsset);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  // ------------------------------------------------------------ playback

  Future<void> _start() async {
    _startedAt = _clock();
    setState(() => _phase = _Phase.listening);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    await _audio.play();
  }

  void _onPosition(Duration position) {
    if (!mounted) return;
    final stops = _set.readingStops;
    for (final (i, stop) in stops.indexed) {
      if (_stopsDone.contains(i)) continue;
      if (_lastPosition < stop.at && position >= stop.at) {
        _stopsDone.add(i);
        if (!_submitted) _beginReadingTime(stop.group);
        break;
      }
    }
    _lastPosition = position;
    setState(() => _position = position);
  }

  void _beginReadingTime(QuestionGroup group) {
    _audio.pause();
    setState(() {
      _readingGroup = group;
      _readingEndsAt = _clock().add(group.readingTime);
    });
  }

  void _endReadingTime() {
    if (_readingGroup == null) return;
    setState(() {
      _readingGroup = null;
      _readingEndsAt = null;
    });
    _audio.play();
  }

  void _onEnded() {
    if (!mounted || _submitted || _phase == _Phase.intro) return;
    if (_timed) {
      if (_phase == _Phase.checking) return;
      setState(() {
        _phase = _Phase.checking;
        _checkEndsAt = _clock().add(ListeningSet.checkTime);
      });
    } else {
      setState(() => _audioEnded = true);
    }
  }

  Duration _left(DateTime? endsAt) {
    if (endsAt == null) return Duration.zero;
    final left = endsAt.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// Countdowns are worked out from the clock, so they stay right after
  /// the app was in the background.
  void _tick() {
    if (!mounted || _submitted) return;
    if (_readingGroup != null && _left(_readingEndsAt) == Duration.zero) {
      _endReadingTime();
    } else if (_phase == _Phase.checking &&
        _left(_checkEndsAt) == Duration.zero) {
      _submit(auto: true);
    } else if (_readingGroup != null || _phase == _Phase.checking) {
      setState(() {});
    }
  }

  Future<void> _seek(Duration to) async {
    // Seeking past a reading stop skips it; seeking back doesn't repeat it.
    for (final (i, stop) in _set.readingStops.indexed) {
      if (stop.at <= to) _stopsDone.add(i);
    }
    _lastPosition = to;
    setState(() {
      _position = to;
      if (to < _set.audioLength) _audioEnded = false;
    });
    await _audio.seek(to);
  }

  Future<void> _playPause() async {
    if (_readingGroup != null) return _endReadingTime();
    if (_playing) {
      await _audio.pause();
    } else {
      if (_position >= _set.audioLength) await _seek(Duration.zero);
      await _audio.play();
    }
  }

  Future<void> _playFromLine(String lineId) async {
    final timing = _set.timings[lineId];
    if (timing == null) return;
    await _seek(timing.start);
    await _audio.play();
  }

  // ------------------------------------------------------------ submit

  Future<void> _submit({bool auto = false}) async {
    if (_submitting || _submitted) return;
    _submitting = true;
    _ticker?.cancel();
    await _audio.pause();
    final grade = ListeningGrade(_set.questions, Map.of(_responses));
    final today = ref.read(todayProvider);
    final xp = XpRules.forListening(correct: grade.correct, timedSet: _timed);
    final attempt = ListeningAttempt(
      setId: _set.id,
      timed: _timed,
      date: today,
      correct: grade.correct,
      total: grade.total,
      minutes: LessonCompletion.minutesFor(
        _clock().difference(_startedAt ?? _clock()),
        (_set.timedLength.inSeconds / 60).ceil(),
      ),
      xp: xp,
      byType: {
        for (final MapEntry(:key, :value) in grade.byType.entries)
          key.name: TypeScore(correct: value.correct, total: value.total),
      },
    );
    await ref
        .read(progressControllerProvider.notifier)
        .completeListening(
          ListeningCompletion(
            attempt: attempt,
            questionIds: [for (final q in _set.questions) q.id],
            mistakes: [
              // Unanswered questions count as wrong but aren't reviewed:
              // there is no answer to learn from.
              for (final q in grade.wrong)
                if (q.isAnswered(_responses[q.id]))
                  SavedMistake(
                    source: MistakeSource.listening,
                    sourceId: _set.id,
                    itemId: q.id,
                    prompt: q.prompt,
                    yourAnswer: q.describe(_responses[q.id])!,
                    correctAnswer: q.correctAnswer,
                    explanation: q.explanation,
                    savedOn: today,
                  ),
            ],
          ),
        );
    if (!mounted) return;
    setState(() {
      _grade = grade;
      _xp = xp;
      _autoSubmitted = auto;
      _phase = _Phase.submitted;
      _readingGroup = null;
      _pane = _Pane.results;
      _submitting = false;
    });
  }

  void _exit() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.listeningHub);

  Future<void> _confirmLeave() async {
    if (_phase == _Phase.intro) return _exit();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave practice?'),
        content: const Text("Your answers in this practice won't be saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep practising'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if ((leave ?? false) && mounted) _exit();
  }

  Future<void> _confirmSubmit() async {
    final unanswered = [
      for (final q in _set.questions)
        if (!q.isAnswered(_responses[q.id])) q.number,
    ];
    final stillPlaying = _phase == _Phase.listening && !_audioEnded;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit your answers?'),
        content: Text(
          [
            if (stillPlaying) "The recording hasn't finished yet.",
            if (unanswered.isEmpty)
              'You have answered every question.'
            else
              'Unanswered: ${unanswered.join(', ')}. Unanswered questions '
                  'are marked wrong.',
          ].join(' '),
          key: const ValueKey('unanswered'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if ((submit ?? false) && mounted) await _submit();
  }

  /// Results: plays the question's evidence line and shows it in the
  /// transcript.
  Future<void> _playEvidence(ListeningQuestion q) async {
    setState(() {
      _focusedLineId = q.evidenceLineId;
      _pane = _Pane.transcript;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _lineKeys[q.evidenceLineId]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.2);
      }
    });
    await _playFromLine(q.evidenceLineId);
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final checkLeft = _left(_checkEndsAt);
    final screen = PopScope(
      canPop: _submitted || _phase == _Phase.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: TitledSessionTopBar(
          title: _set.title,
          closeTooltip: 'Close practice',
          onClose: _submitted ? _exit : _confirmLeave,
          trailing: _phase == _Phase.checking
              ? TimerPill(remaining: checkLeft, warningAt: checkLeft)
              : null,
        ),
        body: switch (_phase) {
          _Phase.intro => _intro(),
          _Phase.listening || _Phase.checking => _session(),
          _Phase.submitted => _results(),
        },
        bottomNavigationBar: StickyActionBar(
          child: switch (_phase) {
            _Phase.intro => AppButton.primary(
              key: const ValueKey('startListening'),
              label: 'Start listening',
              leadingIcon: Icons.headphones_rounded,
              isLoading: _loading,
              onPressed: _loading || _loadError != null ? null : _start,
            ),
            _Phase.listening || _Phase.checking => AppButton.primary(
              key: const ValueKey('submitListening'),
              label: _timed ? 'Submit' : 'Finish',
              isLoading: _submitting,
              onPressed: _confirmSubmit,
            ),
            _Phase.submitted => AppButton.primary(
              label: 'Back to Listening',
              onPressed: () => context.go(AppRoutes.listeningHub),
            ),
          },
        ),
      ),
    );
    // Timed exam screens have no animations.
    if (!_timed || _submitted) return screen;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: screen,
    );
  }

  Widget _intro() {
    final minutes = (_set.timedLength.inSeconds / 60).ceil();
    final rules = _timed
        ? [
            'The recording plays once. You can’t pause, rewind or skip it.',
            'Before each group of questions, you have time to read them. '
                'The recording waits.',
            'After the recording, you have '
                '${ListeningSet.checkTime.inMinutes} minute to check your '
                'answers. Then they are submitted.',
            'No hints or explanations until you submit. The transcript is '
                'shown with your results.',
          ]
        : [
            'Pause, go back and slow the recording down whenever you like.',
            'Reading time comes before each group of questions. You can '
                'skip it.',
            'Check an answer to see whether it’s right and why.',
            'The transcript is shown with your results.',
          ];
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          'PART ${_set.part} · ${_timed ? 'TIMED' : 'LEARNING'}',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          header: true,
          child: Text(_set.title, style: AppTextStyles.headlineLg),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _set.context,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_set.questions.length} questions · about $minutes min',
                style: AppTextStyles.labelLg,
              ),
              const SizedBox(height: AppSpacing.smd),
              for (final rule in rules)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsetsDirectional.only(top: 2),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(rule, style: AppTextStyles.bodyMd)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const InfoBanner(
          type: InfoBannerType.info,
          message:
              'Use headphones if you can. The answers come in the same order '
              'as the questions, so listen before you answer.',
        ),
        if (_loadError != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load the audio",
            message:
                'Check that the app has finished installing, then try '
                'again.',
            actionLabel: 'Retry',
            onAction: _load,
          ),
        ],
      ],
    );
  }

  Widget _session() {
    final reading = _readingGroup;
    final length = _set.audioLength;
    final Widget player = _timed
        ? TimedAudioStatus(
            position: _position,
            length: length,
            label: switch (_phase) {
              _Phase.checking => 'Recording finished',
              _ when reading != null => 'Paused for reading time',
              _ => 'Playing',
            },
          )
        : AudioControls(
            position: _position,
            length: length,
            playing: _playing,
            speed: _speed,
            onPlayPause: _playPause,
            onSeek: _seek,
            onSpeed: (s) {
              setState(() => _speed = s);
              _audio.setSpeed(s);
            },
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              player,
              if (reading != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ReadingTimeBanner(
                  label: reading.label.toLowerCase(),
                  remaining: _left(_readingEndsAt),
                  onSkip: _timed ? null : _endReadingTime,
                ),
              ],
              if (_phase == _Phase.checking) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: const InfoBanner(
                    key: ValueKey('checkTime'),
                    type: InfoBannerType.warning,
                    message:
                        'Check your answers. They are submitted when the '
                        'time runs out.',
                  ),
                ),
              ],
              if (_audioEnded && !_timed) ...[
                const SizedBox(height: AppSpacing.sm),
                const InfoBanner(
                  type: InfoBannerType.info,
                  message:
                      'The recording has finished. Check your answers, then '
                      'tap Finish.',
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _questions()),
      ],
    );
  }

  Widget _questions() {
    final children = <Widget>[];
    for (final group in _set.groups) {
      final questions = _set.questionsIn(group);
      children.add(
        _GroupHeader(
          group: group,
          matchingOptions:
              questions.firstOrNull?.type == ListeningQuestionType.matching
              ? questions.first.options
              : null,
        ),
      );
      for (final q in questions) {
        final checked = _checked.contains(q.id);
        children.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.smd),
            child: AppCard(
              key: ValueKey('question-${q.id}'),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${q.number}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ListeningQuestionBody(
                    question: q,
                    response: _responses[q.id],
                    revealed: checked,
                    autocorrect: !_timed,
                    onChanged: checked
                        ? null
                        : (r) => setState(() {
                            if (r == null) {
                              _responses.remove(q.id);
                            } else {
                              _responses[q.id] = r;
                            }
                          }),
                  ),
                  if (!_timed) ...[
                    const SizedBox(height: AppSpacing.smd),
                    if (checked)
                      Semantics(
                        liveRegion: true,
                        child: ListeningAnswerExplanation(
                          question: q,
                          correct: q.isCorrect(_responses[q.id]),
                          onPlayFrom: () => _playFromLine(q.evidenceLineId),
                        ),
                      )
                    else
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton.outline(
                          key: ValueKey('check-${q.id}'),
                          label: 'Check',
                          compact: true,
                          expand: false,
                          onPressed: q.isAnswered(_responses[q.id])
                              ? () => setState(() => _checked.add(q.id))
                              : null,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    }
    return SingleChildScrollView(
      key: const PageStorageKey('questions'),
      controller: _questionScroll,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _results() {
    final grade = _grade!;
    final results = ListeningResultsPane(
      grade: grade,
      xp: _xp,
      autoSubmitted: _autoSubmitted,
      controller: _resultsScroll,
      onPlayFrom: _playEvidence,
    );
    final transcript = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            0,
          ),
          child: AudioControls(
            position: _position,
            length: _set.audioLength,
            playing: _playing,
            speed: _speed,
            onPlayPause: _playPause,
            onSeek: _seek,
            onSpeed: (s) {
              setState(() => _speed = s);
              _audio.setSpeed(s);
            },
          ),
        ),
        Expanded(
          child: TranscriptView(
            set: _set,
            grade: grade,
            lineKeys: _lineKeys,
            currentLine: _playing ? _set.lineAt(_position) : null,
            focusedLineId: _focusedLineId,
            controller: _transcriptScroll,
            onPlayFrom: (line) {
              setState(() => _focusedLineId = line.id);
              _playFromLine(line.id);
            },
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _splitBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: results),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: transcript),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaneToggle(
              selected: _pane,
              tabs: const [
                (
                  value: _Pane.results,
                  id: 'results',
                  label: 'Results',
                  icon: Icons.checklist_rounded,
                ),
                (
                  value: _Pane.transcript,
                  id: 'transcript',
                  label: 'Transcript',
                  icon: Icons.subject_rounded,
                ),
              ],
              onChanged: (p) => setState(() => _pane = p),
            ),
            Expanded(
              child: IndexedStack(
                index: _pane.index,
                children: [results, transcript],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, this.matchingOptions});

  final QuestionGroup group;

  /// The box of options for a matching group, listed once.
  final List<ListeningOption>? matchingOptions;

  @override
  Widget build(BuildContext context) {
    final options = matchingOptions;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.smd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(group.label, style: AppTextStyles.headlineSm),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            group.instructions,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.smd),
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(group.heading, style: AppTextStyles.labelLg),
                if (options != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  MatchingOptionsList(options: options),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
