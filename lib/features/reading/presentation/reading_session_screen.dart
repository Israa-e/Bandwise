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
import '../domain/reading.dart';
import 'reading_providers.dart';
import 'widgets/passage_view.dart';
import 'widgets/question_navigator.dart';
import 'widgets/questions_pane.dart';
import 'widgets/results_pane.dart';

/// Below this width the passage and questions are tabs; from it up they
/// sit side by side.
const splitBreakpoint = 840.0;

/// Shown from 5:00 left in timed mode.
const _warningAt = Duration(minutes: 5);

/// A reading session outside the tab shell: answer, submit, then results.
class ReadingSessionScreen extends ConsumerWidget {
  const ReadingSessionScreen({
    super.key,
    required this.passageId,
    required this.mode,
    this.type,
  });

  final String passageId;
  final ReadingMode mode;

  /// Learning mode only: practise one question type.
  final ReadingQuestionType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passages = ref.watch(readingPassagesProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.readingHub);
    if (passages.hasError && !passages.isLoading) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load this passage",
        message: 'Check your connection and try again.',
        onBack: back,
        onRetry: () => ref.invalidate(readingPassagesProvider),
      );
    }
    final list = passages.value;
    if (list == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final passage = list.where((p) => p.id == passageId).firstOrNull;
    if (passage == null) {
      return _Message(
        icon: Icons.search_off_rounded,
        title: 'Passage not found',
        message: 'Pick a passage from the Reading hub.',
        onBack: back,
      );
    }
    final timed = mode == ReadingMode.timed;
    return ReadingSession(
      key: ValueKey('$passageId-${mode.name}-${type?.name}'),
      passage: passage,
      mode: mode,
      // Timed practice is always the full passage.
      type: timed ? null : type,
    );
  }
}

enum _Pane { passage, questions }

class ReadingSession extends ConsumerStatefulWidget {
  const ReadingSession({
    super.key,
    required this.passage,
    required this.mode,
    this.type,
  });

  final ReadingPassage passage;
  final ReadingMode mode;
  final ReadingQuestionType? type;

  @override
  ConsumerState<ReadingSession> createState() => _ReadingSessionState();
}

class _ReadingSessionState extends ConsumerState<ReadingSession>
    with WidgetsBindingObserver {
  late final List<ReadingQuestion> _questions = widget.passage.questionsFor(
    widget.type,
  );
  late final DateTime Function() _clock;

  /// Set when the session opens; the timer and study minutes count from it.
  late final DateTime _startedAt;

  final _responses = <String, ReadingResponse>{};
  final _flagged = <String>{};
  final _checked = <String>{};
  final _highlights = <int, List<TextRange>>{};

  var _pane = _Pane.passage;
  EvidenceSpan? _evidence;

  late final _paragraphKeys = [
    for (final _ in widget.passage.paragraphs) GlobalKey(),
  ];
  late final _questionKeys = {for (final q in _questions) q.id: GlobalKey()};
  final _passageScroll = ScrollController();
  final _questionScroll = ScrollController();

  Timer? _ticker;
  var _submitting = false;

  /// Set once submitted.
  ReadingGrade? _grade;
  var _xp = 0;
  var _timeUsed = Duration.zero;
  var _timeUp = false;

  bool get _timed => widget.mode == ReadingMode.timed;
  bool get _submitted => _grade != null;

  @override
  void initState() {
    super.initState();
    _clock = ref.read(clockProvider);
    _startedAt = _clock();
    WidgetsBinding.instance.addObserver(this);
    if (_timed) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _passageScroll.dispose();
    _questionScroll.dispose();
    super.dispose();
  }

  /// The time left is always worked out from the start time, so it stays
  /// right after the app was in the background.
  Duration get _remaining {
    final left =
        const Duration(minutes: ReadingPassage.timedMinutes) -
        _clock().difference(_startedAt);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!_timed || _submitted || !mounted) return;
    if (_remaining == Duration.zero) {
      _submit(timeUp: true);
    } else {
      setState(() {});
    }
  }

  Future<void> _submit({bool timeUp = false}) async {
    if (_submitting || _submitted) return;
    _submitting = true;
    _ticker?.cancel();
    final passage = widget.passage;
    final grade = ReadingGrade(_questions, Map.of(_responses));
    final today = ref.read(todayProvider);
    const limit = Duration(minutes: ReadingPassage.timedMinutes);
    final elapsed = _clock().difference(_startedAt);
    final timeUsed = _timed && elapsed > limit ? limit : elapsed;
    final xp = XpRules.forReading(correct: grade.correct, timedPassage: _timed);
    final attempt = ReadingAttempt(
      passageId: passage.id,
      timed: _timed,
      date: today,
      correct: grade.correct,
      total: grade.total,
      minutes: LessonCompletion.minutesFor(
        _clock().difference(_startedAt),
        ReadingPassage.timedMinutes,
      ),
      xp: xp,
      questionType: widget.type?.name,
      byType: {
        for (final MapEntry(:key, :value) in grade.byType.entries)
          key.name: TypeScore(correct: value.correct, total: value.total),
      },
    );
    await ref
        .read(progressControllerProvider.notifier)
        .completeReading(
          ReadingCompletion(
            attempt: attempt,
            questionIds: [for (final q in _questions) q.id],
            mistakes: [
              // Unanswered questions count as wrong but aren't reviewed: there
              // is no answer to learn from.
              for (final q in grade.wrong)
                if (q.isAnswered(_responses[q.id]))
                  SavedMistake(
                    source: MistakeSource.reading,
                    sourceId: passage.id,
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
      _timeUsed = timeUsed;
      _timeUp = timeUp;
      _evidence = null;
      _pane = _Pane.questions;
      _submitting = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_questionScroll.hasClients) _questionScroll.jumpTo(0);
    });
  }

  void _exit() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.readingHub);

  Future<void> _confirmLeave() async {
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
      for (final (i, q) in _questions.indexed)
        if (!q.isAnswered(_responses[q.id])) i + 1,
    ];
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit your answers?'),
        content: Text(
          unanswered.isEmpty
              ? 'You have answered every question.'
              : 'Unanswered: ${unanswered.join(', ')}. Unanswered questions '
                    'are marked wrong.',
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

  Future<void> _openNavigator() async {
    final index = await showQuestionNavigator(context, [
      for (final q in _questions)
        (
          answered: q.isAnswered(_responses[q.id]),
          flagged: _flagged.contains(q.id),
        ),
    ]);
    if (index == null || !mounted) return;
    setState(() => _pane = _Pane.questions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _questionKeys[_questions[index].id];
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.05);
      }
    });
  }

  void _showEvidence(ReadingQuestion q) {
    setState(() {
      _evidence = q.evidence;
      _pane = _Pane.passage;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToSentence(
        _paragraphKeys[q.evidence.paragraph],
        widget.passage.paragraphs[q.evidence.paragraph],
        q.evidence.sentence,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _submitted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: TitledSessionTopBar(
          title: widget.passage.title,
          closeTooltip: 'Close practice',
          onClose: _submitted ? _exit : _confirmLeave,
          trailing: _timed && !_submitted
              ? TimerPill(remaining: _remaining, warningAt: _warningAt)
              : null,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final passage = _passageView();
            final side = _sidePane();
            if (constraints.maxWidth >= splitBreakpoint) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: passage),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(child: side),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaneToggle(
                  pane: _pane,
                  secondLabel: _submitted ? 'Results' : 'Questions',
                  onChanged: (p) => setState(() => _pane = p),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _pane.index,
                    children: [passage, side],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: StickyActionBar(
          child: _submitted
              ? AppButton.primary(
                  label: 'Back to Reading',
                  onPressed: () => context.go(AppRoutes.readingHub),
                )
              : Row(
                  children: [
                    Expanded(child: _navigatorButton(context)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.primary(
                        label: _timed ? 'Submit' : 'Finish',
                        isLoading: _submitting,
                        onPressed: _confirmSubmit,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// "6/10" with a grid icon, so it never truncates on phones; the split
  /// layout has room for "6/10 answered". Screen readers always hear the
  /// full text.
  Widget _navigatorButton(BuildContext context) {
    final answered = _questions
        .where((q) => q.isAnswered(_responses[q.id]))
        .length;
    final total = _questions.length;
    final wide = MediaQuery.sizeOf(context).width >= splitBreakpoint;
    return Semantics(
      button: true,
      label: 'Questions: $answered of $total answered',
      onTap: _openNavigator,
      excludeSemantics: true,
      child: AppButton.outline(
        key: const ValueKey('navigatorButton'),
        label: wide ? '$answered/$total answered' : '$answered/$total',
        leadingIcon: Icons.grid_view_rounded,
        onPressed: _openNavigator,
      ),
    );
  }

  Widget _passageView() => PassageView(
    passage: widget.passage,
    paragraphKeys: _paragraphKeys,
    highlights: _highlights,
    evidence: _evidence,
    controller: _passageScroll,
    onHighlight: (p, range) =>
        setState(() => (_highlights[p] ??= []).add(range)),
    onClearHighlights: () => setState(_highlights.clear),
  );

  Widget _sidePane() {
    final grade = _grade;
    if (grade != null) {
      return ResultsPane(
        grade: grade,
        xp: _xp,
        timeUp: _timeUp,
        timed: _timed,
        timeUsed: _timeUsed,
        controller: _questionScroll,
        onShowEvidence: _showEvidence,
      );
    }
    final warning = _timed && _remaining <= _warningAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (warning)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.smd,
              AppSpacing.page,
              0,
            ),
            child: Semantics(
              liveRegion: true,
              child: const InfoBanner(
                type: InfoBannerType.warning,
                message:
                    'About 5 minutes left. Answers are submitted when the '
                    'time runs out.',
              ),
            ),
          ),
        Expanded(
          child: QuestionsPane(
            passage: widget.passage,
            questions: _questions,
            questionKeys: _questionKeys,
            responses: _responses,
            flagged: _flagged,
            checked: _checked,
            learning: !_timed,
            controller: _questionScroll,
            onChanged: (q, r) => setState(() {
              if (r == null) {
                _responses.remove(q.id);
              } else {
                _responses[q.id] = r;
              }
            }),
            onToggleFlag: (q) => setState(() {
              if (!_flagged.remove(q.id)) _flagged.add(q.id);
            }),
            onCheck: (q) => setState(() => _checked.add(q.id)),
            onShowEvidence: _showEvidence,
          ),
        ),
      ],
    );
  }
}

/// The phone toggle between the passage and the questions (or results).
class _PaneToggle extends StatelessWidget {
  const _PaneToggle({
    required this.pane,
    required this.secondLabel,
    required this.onChanged,
  });

  final _Pane pane;
  final String secondLabel;
  final ValueChanged<_Pane> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(_Pane p, String label, IconData icon) {
      final selected = pane == p;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? AppColors.card : Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.nestedRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('pane-${p.name}'),
              onTap: () => onChanged(p),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMd.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        0,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.disabledFill,
          borderRadius: AppRadii.buttonRadius,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xxs),
          child: Row(
            children: [
              tab(_Pane.passage, 'Passage', Icons.article_outlined),
              const SizedBox(width: AppSpacing.xxs),
              tab(_Pane.questions, secondLabel, Icons.checklist_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return Scaffold(
      appBar: SessionTopBar(onClose: onBack, closeTooltip: 'Close practice'),
      body: EmptyStateView(
        icon: icon,
        title: title,
        message: message,
        action: Column(
          children: [
            if (onRetry != null) ...[
              AppButton.primary(
                label: 'Retry',
                expand: false,
                onPressed: onRetry,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton.outline(
              label: 'Go back',
              expand: false,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
