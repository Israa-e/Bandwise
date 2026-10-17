import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../data/writing_content.dart';
import '../domain/writing.dart';
import '../domain/writing_repository.dart';
import '../domain/writing_submission.dart';
import 'widgets/feedback_widgets.dart';
import 'widgets/writing_task_card.dart';
import 'writing_providers.dart';

/// From this width the task and notes sit beside the editor.
const _wideBreakpoint = 840.0;

/// Shown from 5:00 left in timed mode.
const _warningAt = Duration(minutes: 5);

/// The draft is saved this often while it has changes.
const autosaveInterval = Duration(seconds: 3);

/// The essay editor, for a new essay (continuing its draft if there is
/// one) or for revising a submitted essay.
class WritingEditorScreen extends ConsumerWidget {
  const WritingEditorScreen({
    super.key,
    required String this.taskId,
    required this.mode,
  }) : submissionId = null;

  const WritingEditorScreen.revise({super.key, required this.submissionId})
    : taskId = null,
      mode = WritingMode.learning;

  final String? taskId;

  /// For a new essay; a saved draft keeps its own mode.
  final WritingMode mode;

  /// The submission being revised.
  final String? submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(writingTasksProvider);
    final drafts = ref.watch(writingDraftsProvider);
    final submissions = ref.watch(writingSubmissionsProvider);
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.writingHub);

    if ([tasks, drafts, submissions].any((a) => a.hasError && !a.isLoading)) {
      return _Message(
        title: "Couldn't open the editor",
        message: 'Check your connection and try again.',
        onBack: back,
        onRetry: () => ref
          ..invalidate(writingTasksProvider)
          ..invalidate(writingDraftsProvider)
          ..invalidate(writingSubmissionsProvider),
      );
    }
    if (!tasks.hasValue || !drafts.hasValue || !submissions.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final revising = submissionId == null
        ? null
        : submissions.requireValue
              .where((s) => s.id == submissionId)
              .firstOrNull;
    final task = tasks.requireValue
        .where((t) => t.id == (revising?.taskId ?? taskId))
        .firstOrNull;
    if (task == null || (submissionId != null && revising == null)) {
      return _Message(
        title: 'Essay not found',
        message: 'Pick a task from the Writing hub.',
        onBack: back,
      );
    }
    final id = WritingDraft.draftIdFor(
      taskId: task.id,
      revisionOf: revising?.id,
    );
    final saved = drafts.requireValue[id];
    final now = ref.read(clockProvider)();
    return WritingEditor(
      key: ValueKey(id),
      task: task,
      revising: revising,
      isNew: saved == null,
      initialDraft:
          saved ??
          WritingDraft(
            taskId: task.id,
            mode: revising == null ? mode : WritingMode.learning,
            startedAt: now,
            savedAt: now,
            text: revising?.text ?? '',
            revisionOf: revising?.id,
          ),
    );
  }
}

class WritingEditor extends ConsumerStatefulWidget {
  const WritingEditor({
    super.key,
    required this.task,
    required this.initialDraft,
    required this.isNew,
    this.revising,
  });

  final WritingTask task;
  final WritingDraft initialDraft;

  /// The draft hasn't been saved yet.
  final bool isNew;
  final WritingSubmission? revising;

  @override
  ConsumerState<WritingEditor> createState() => _WritingEditorState();
}

class _WritingEditorState extends ConsumerState<WritingEditor>
    with WidgetsBindingObserver {
  late WritingDraft _draft = widget.initialDraft;
  late final _text = EssayEditingController(text: _draft.text);
  late final _notes = TextEditingController(text: _draft.notes);
  late final DateTime Function() _clock;
  late final WritingDraftsController _drafts;

  Timer? _ticker;
  var _sinceSave = Duration.zero;
  var _dirty = false;
  var _submitting = false;
  var _submitted = false;

  /// Time with the editor open, up to the last time it went to the
  /// background, plus when it was last brought back (null while in the
  /// background).
  late Duration _activeBefore = _draft.activeTime;
  DateTime? _activeSince;

  bool get _timed => _draft.mode == WritingMode.timed;
  WritingTaskType get _type => widget.task.type;

  @override
  void initState() {
    super.initState();
    _clock = ref.read(clockProvider);
    _drafts = ref.read(writingDraftsProvider.notifier);
    _activeSince = _clock();
    WidgetsBinding.instance.addObserver(this);
    _text.addListener(_changed);
    _notes.addListener(_changed);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isNew) unawaited(_save());
      // A timed draft reopened after its time ran out is submitted at once.
      _tick();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    // Leaving keeps the draft. Providers can't change while the tree is
    // being torn down, so this waits for the current frame to finish.
    if (!_submitted && !_left) {
      final persist = _persist();
      scheduleMicrotask(persist);
    }
    _text.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Rebuilds for the word count, and marks the draft as unsaved.
  void _changed() => setState(
    () => _dirty = _text.text != _draft.text || _notes.text != _draft.notes,
  );

  Duration get _activeTime {
    final since = _activeSince;
    return _activeBefore +
        (since == null ? Duration.zero : _clock().difference(since));
  }

  /// Worked out from the start time, so it stays right after the app was
  /// in the background or closed.
  Duration get _remaining {
    final left =
        Duration(minutes: _type.minutes) -
        _clock().difference(_draft.startedAt);
    return left.isNegative ? Duration.zero : left;
  }

  Duration get _timeUsed {
    if (!_timed) return _activeTime;
    final limit = Duration(minutes: _type.minutes);
    final elapsed = _clock().difference(_draft.startedAt);
    return elapsed > limit ? limit : elapsed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _activeSince ??= _clock();
        _tick();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_activeSince != null) {
          _activeBefore = _activeTime;
          _activeSince = null;
        }
        if (!_submitted) unawaited(_save());
    }
  }

  void _tick() {
    if (_submitted || _submitting || !mounted) return;
    if (_timed && _remaining == Duration.zero) {
      unawaited(_submit(timeUp: true));
      return;
    }
    _sinceSave += const Duration(seconds: 1);
    if (_dirty && _sinceSave >= autosaveInterval) {
      unawaited(_save());
    } else if (_timed) {
      setState(() {});
    }
  }

  WritingDraft _current() => _draft.copyWith(
    text: _text.text,
    notes: _notes.text,
    activeTime: _activeTime,
    savedAt: _clock(),
  );

  Future<void> _save() async {
    final draft = _current();
    _sinceSave = Duration.zero;
    if (mounted) {
      setState(() {
        _draft = draft;
        _dirty = false;
      });
    }
    await _drafts.save(draft);
  }

  /// Saving on leaving, to run once the editor is gone. An empty learning
  /// draft isn't worth keeping.
  Future<void> Function() _persist() {
    final draft = _current();
    final empty =
        draft.text.trim().isEmpty &&
        draft.notes.trim().isEmpty &&
        draft.mode == WritingMode.learning &&
        draft.revisionOf == null;
    final drafts = _drafts;
    return () => empty ? drafts.delete(draft.id) : drafts.save(draft);
  }

  /// Set once the draft was saved on leaving.
  var _left = false;

  Future<void> _leave() async {
    if (!_submitted) {
      _left = true;
      _ticker?.cancel();
      await _persist()();
    }
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go(AppRoutes.writingHub);
  }

  Future<void> _confirmSubmit() async {
    final words = countWords(_text.text);
    final timeUsed = _timeUsed;
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit your essay?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogRow(label: 'Words', value: '$words'),
              _DialogRow(label: 'Time used', value: TimerPill.format(timeUsed)),
              if (words < _type.minWords) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoBanner(
                  key: const ValueKey('underMinimum'),
                  type: InfoBannerType.warning,
                  message:
                      'Responses under ${_type.minWords} words are '
                      'penalised.',
                ),
              ],
              const SizedBox(height: AppSpacing.smd),
              const Text(
                "You can't edit after submitting.",
                style: AppTextStyles.bodyMd,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep writing'),
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

  Future<void> _submit({bool timeUp = false}) async {
    if (_submitting || _submitted) return;
    setState(() => _submitting = true);
    _ticker?.cancel();
    final now = _clock();
    final timeUsed = _timeUsed;
    final existing = ref.read(writingSubmissionsProvider).value ?? const [];
    final submission = WritingSubmission(
      // Unique even if two essays are submitted in the same instant.
      id: 'ws-${now.microsecondsSinceEpoch}-${existing.length + 1}',
      taskId: widget.task.id,
      mode: _draft.mode,
      text: _text.text.trim(),
      timeUsed: timeUsed,
      submittedAt: now,
      revisionOf: _draft.revisionOf,
      timeUp: timeUp,
    );
    await ref.read(writingSubmissionsProvider.notifier).save(submission);
    _submitted = true;
    await _drafts.delete(_draft.id);
    await ref
        .read(progressControllerProvider.notifier)
        .completeWriting(
          date: ref.read(todayProvider),
          minutes: LessonCompletion.minutesFor(timeUsed, _type.minutes),
        );
    if (!mounted) return;
    context.pushReplacement(
      AppRoutes.writingResult(submission.id, timeUp: timeUp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revising = widget.revising;
    final words = countWords(_text.text);
    return PopScope(
      // Back saves the draft first, like the close button.
      canPop: _submitted || _left,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: TitledSessionTopBar(
          title: revising == null
              ? '${_type.label} · ${widget.task.topic}'
              : 'Revise · ${_type.label}',
          closeTooltip: 'Close editor',
          onClose: _leave,
          subtitle: _SaveStatus(saved: !_dirty),
          trailing: _timed
              ? TimerPill(remaining: _remaining, warningAt: _warningAt)
              : null,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final side = _sidePanels(revising);
            final editor = _editorArea();
            if (constraints.maxWidth >= _wideBreakpoint) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: ListView(padding: _listPadding, children: side),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    flex: 3,
                    child: ListView(padding: _listPadding, children: editor),
                  ),
                ],
              );
            }
            return ListView(
              padding: _listPadding,
              children: [...side, ...editor],
            );
          },
        ),
        bottomNavigationBar: StickyActionBar(
          child: Row(
            children: [
              Expanded(
                child: WordCountLabel(words: words, minimum: _type.minWords),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: 'Submit',
                expand: false,
                isLoading: _submitting,
                onPressed: _confirmSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _listPadding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.page,
    AppSpacing.smd,
    AppSpacing.page,
    AppSpacing.xl,
  );

  List<Widget> _sidePanels(WritingSubmission? revising) => [
    WritingTaskCard(task: widget.task),
    const SizedBox(height: AppSpacing.smd),
    if (revising != null) ...[
      _NotesToAddress(submission: revising, type: _type),
      const SizedBox(height: AppSpacing.smd),
    ],
    if (!_timed) ...[
      CollapsibleCard(
        key: const ValueKey('tipsPanel'),
        title: 'Structure tips',
        icon: Icons.lightbulb_outline_rounded,
        initiallyExpanded: revising == null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final tip in structureTips[_type]!)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(tip, style: AppTextStyles.bodySm)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.smd),
      CollapsibleCard(
        key: const ValueKey('planPanel'),
        title: 'Plan your essay',
        subtitle: 'Not counted and not submitted',
        icon: Icons.edit_note_rounded,
        initiallyExpanded: false,
        child: _BoxedField(
          child: TextField(
            key: const ValueKey('planField'),
            controller: _notes,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.bodyMd,
            decoration: const InputDecoration.collapsed(
              hintText: 'Main ideas, examples, paragraph order…',
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.smd),
    ],
  ];

  List<Widget> _editorArea() => [
    if (_timed && _remaining <= _warningAt) ...[
      Semantics(
        liveRegion: true,
        child: const InfoBanner(
          type: InfoBannerType.warning,
          message:
              'About 5 minutes left. Your essay is submitted when the time '
              'runs out.',
        ),
      ),
      const SizedBox(height: AppSpacing.smd),
    ],
    if (kDebugMode)
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('useSampleEssay'),
          onPressed: () => _text.text = widget.task.sampleEssay,
          icon: const Icon(Icons.bug_report_outlined, size: 18),
          label: const Text('Use sample essay'),
        ),
      ),
    _BoxedField(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: TextField(
        key: const ValueKey('essayField'),
        controller: _text,
        minLines: 12,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        // Computer-delivered IELTS has no spell check or autocorrect.
        autocorrect: !_timed,
        enableSuggestions: !_timed,
        spellCheckConfiguration: _timed
            ? const SpellCheckConfiguration.disabled()
            : null,
        smartDashesType: _timed ? SmartDashesType.disabled : null,
        smartQuotesType: _timed ? SmartQuotesType.disabled : null,
        textCapitalization: _timed
            ? TextCapitalization.none
            : TextCapitalization.sentences,
        style: AppTextStyles.bodyLg,
        decoration: const InputDecoration.collapsed(
          hintText:
              'Start writing here. Leave a blank line between paragraphs.',
        ),
      ),
    ),
  ];
}

/// Shows blank lines between paragraphs at a reduced height, so paragraphs
/// get a gap rather than a full empty line.
class EssayEditingController extends TextEditingController {
  EssayEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final base = style ?? AppTextStyles.bodyLg;
    final gap = base.copyWith(fontSize: (base.fontSize ?? 16) * 0.6, height: 1);
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : TextRange.empty;
    final composingStyle = base.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );

    final spans = <TextSpan>[];
    var start = 0;
    (bool, bool)? kind;
    void flush(int end) {
      if (end <= start || kind == null) return;
      final (isGap, isComposing) = kind;
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: isGap ? gap : (isComposing ? composingStyle : null),
        ),
      );
    }

    for (var i = 0; i < text.length; i++) {
      final next = (
        text[i] == '\n' && i > 0 && text[i - 1] == '\n',
        i >= composing.start && i < composing.end,
      );
      if (next != kind) {
        flush(i);
        start = i;
        kind = next;
      }
    }
    flush(text.length);
    return TextSpan(style: base, children: spans);
  }
}

/// "142 words · 150 minimum"; green with a check from the minimum.
class WordCountLabel extends StatelessWidget {
  const WordCountLabel({super.key, required this.words, required this.minimum});

  final int words;
  final int minimum;

  @override
  Widget build(BuildContext context) {
    final reached = words >= minimum;
    final color = reached ? AppColors.success : AppColors.text;
    return Semantics(
      label:
          '$words ${words == 1 ? 'word' : 'words'}, minimum $minimum'
          '${reached ? ', reached' : ''}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle_rounded : Icons.notes_rounded,
            size: 20,
            color: reached ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$words ${words == 1 ? 'word' : 'words'}',
                    style: TextStyle(color: color),
                  ),
                  TextSpan(
                    text: ' · $minimum minimum',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              key: const ValueKey('wordCount'),
              maxLines: 2,
              style: AppTextStyles.tabular(AppTextStyles.labelLg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.saved});

  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('saveStatus'),
      children: [
        Icon(
          saved ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            saved ? 'Draft saved' : 'Saving…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// A bordered writing area.
class _BoxedField extends StatelessWidget {
  const _BoxedField({
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(AppSpacing.smd),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: child,
    );
  }
}

/// What the feedback asked for, beside the editor while revising.
class _NotesToAddress extends StatelessWidget {
  const _NotesToAddress({required this.submission, required this.type});

  final WritingSubmission submission;
  final WritingTaskType type;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    void item(Widget leading, String title, String? detail) => items.add(
      Padding(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMd),
                  if (detail != null)
                    Text(
                      detail,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    const bullet = Icon(
      Icons.check_box_outline_blank_rounded,
      size: 18,
      color: AppColors.primary,
    );
    switch (submission.result) {
      case AnalysedResult(:final feedback):
        for (final t in feedback.topImprovements) {
          item(bullet, t.title, t.detail);
        }
        for (final a in feedback.annotations) {
          item(
            Icon(a.type.icon, size: 18, color: a.type.color),
            '‘${a.original}’',
            '${a.type.label}: ${a.why}',
          );
        }
      case DemoResult():
        for (final t in generalFeedbackFor(type).checklist) {
          item(bullet, t.title, t.detail);
        }
      case null:
        item(bullet, 'Feedback is still on its way', null);
    }
    return CollapsibleCard(
      key: const ValueKey('notesToAddress'),
      title: 'Notes to address',
      subtitle:
          'You make the changes; the feedback doesn\'t rewrite your essay.',
      icon: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(value, style: AppTextStyles.tabular(AppTextStyles.labelLg)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return Scaffold(
      appBar: SessionTopBar(onClose: onBack, closeTooltip: 'Close editor'),
      body: EmptyStateView(
        icon: Icons.error_outline_rounded,
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
