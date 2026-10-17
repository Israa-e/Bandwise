import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../learn/domain/course.dart';
import '../../learn/domain/learning_path.dart';
import '../../learn/presentation/learn_providers.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/presentation/progress_controller.dart';
import 'widgets/exercise_views.dart';
import 'widgets/lesson_complete_view.dart';
import 'widgets/lesson_intro_view.dart';

/// A lesson, outside the tab shell: intro, exercises, then results.
///
/// Nothing is saved until the last exercise is done; leaving earlier asks
/// for confirmation and discards the attempt.
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(learningPathProvider);
    // Keep the path from the start of the attempt: completing the lesson
    // changes progress, but the screen should stay on its results.
    return switch (path) {
      AsyncValue(:final value?) => _LessonLoaded(
        key: ValueKey(lessonId),
        path: value,
        lessonId: lessonId,
      ),
      AsyncValue(hasError: true) => _Message(
        icon: Icons.error_outline_rounded,
        title: "Couldn't load this lesson",
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(learningPathProvider),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _LessonLoaded extends StatelessWidget {
  const _LessonLoaded({super.key, required this.path, required this.lessonId});

  final LearningPath path;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final lesson = path.course.lessonById(lessonId);
    if (lesson == null) {
      return const _Message(
        icon: Icons.search_off_rounded,
        title: 'Lesson not found',
        message: 'This lesson may have moved. Pick one from your path.',
      );
    }
    final node = path.nodeFor(lesson);
    if (node.isLocked) {
      return _Message(
        icon: Icons.lock_outline_rounded,
        title: 'This lesson is locked',
        message: '${node.lockedReason}.',
      );
    }
    if (!lesson.isPlayable) {
      return _Message(
        icon: Icons.hourglass_empty_rounded,
        title: 'Content coming soon',
        message: '"${lesson.title}" is being written. Try another lesson.',
      );
    }
    return _LessonFlow(
      unit: path.course.unit(lesson.unit),
      lesson: lesson,
      completedBefore: path.progress.isCompleted(lesson.id),
      following: _following(path.course, lesson),
    );
  }

  /// The lesson after [lesson] in path order, if any.
  static Lesson? _following(Course course, Lesson lesson) {
    final all = course.lessons.toList();
    final i = all.indexWhere((l) => l.id == lesson.id);
    return i >= 0 && i + 1 < all.length ? all[i + 1] : null;
  }
}

const _closeTooltip = 'Close lesson';

enum _Phase { intro, exercises, complete }

class _LessonFlow extends ConsumerStatefulWidget {
  const _LessonFlow({
    required this.unit,
    required this.lesson,
    required this.completedBefore,
    required this.following,
  });

  final Unit unit;
  final Lesson lesson;
  final bool completedBefore;
  final Lesson? following;

  @override
  ConsumerState<_LessonFlow> createState() => _LessonFlowState();
}

class _LessonFlowState extends ConsumerState<_LessonFlow> {
  var _phase = _Phase.intro;
  var _index = 0;

  /// Question answers by exercise index. One try per question.
  final _answers = <int, int>{};
  int? _picked;
  var _checked = false;
  var _revealed = false;
  var _saving = false;
  DateTime? _startedAt;
  LessonCompletion? _completion;

  List<Exercise> get _exercises => widget.lesson.exercises;
  Exercise get _current => _exercises[_index];

  void _start() => setState(() {
    _phase = _Phase.exercises;
    _startedAt = DateTime.now();
  });

  void _check() => setState(() {
    _answers[_index] = _picked!;
    _checked = true;
  });

  Future<void> _next() async {
    if (_index + 1 < _exercises.length) {
      setState(() {
        _index++;
        _picked = null;
        _checked = false;
        _revealed = false;
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final lesson = widget.lesson;
    var correct = 0;
    final mistakes = <SavedMistake>[];
    for (final MapEntry(key: i, value: picked) in _answers.entries) {
      final q = _exercises[i] as QuestionExercise;
      if (picked == q.correctIndex) {
        correct++;
      } else {
        mistakes.add(
          SavedMistake(
            sourceId: lesson.id,
            itemId: q.id,
            prompt: q.savedPrompt,
            yourAnswer: q.options[picked],
            correctAnswer: q.correctAnswer,
            explanation: q.explanation,
            savedOn: ref.read(todayProvider),
          ),
        );
      }
    }
    final completion = LessonCompletion(
      lessonId: lesson.id,
      date: ref.read(todayProvider),
      correctFirstTry: correct,
      questionCount: lesson.questionCount,
      minutes: LessonCompletion.minutesFor(
        DateTime.now().difference(_startedAt!),
        lesson.estimatedMinutes,
      ),
      mistakes: mistakes,
    );
    await ref
        .read(progressControllerProvider.notifier)
        .completeLesson(completion);
    if (!mounted) return;
    setState(() {
      _completion = completion;
      _phase = _Phase.complete;
      _saving = false;
    });
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave lesson?'),
        content: const Text("Your progress in this lesson won't be saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep learning'),
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

  @override
  Widget build(BuildContext context) {
    final midLesson = _phase == _Phase.exercises;
    return PopScope(
      canPop: !midLesson,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: switch (_phase) {
        _Phase.intro => _intro(),
        _Phase.exercises => _exercise(),
        _Phase.complete => _complete(),
      },
    );
  }

  Widget _intro() {
    return Scaffold(
      appBar: SessionTopBar(onClose: _exit, closeTooltip: _closeTooltip),
      body: LessonIntroView(
        unit: widget.unit,
        lesson: widget.lesson,
        completedBefore: widget.completedBefore,
      ),
      bottomNavigationBar: StickyActionBar(
        child: AppButton.primary(
          label: 'Start',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: _start,
        ),
      ),
    );
  }

  Widget _exercise() {
    final exercise = _current;
    final done = _index + (_checked || _revealed ? 1 : 0);
    final Widget body;
    final Widget bottom;
    switch (exercise) {
      case FlashcardExercise():
        body = FlashcardView(exercise: exercise, revealed: _revealed);
        bottom = StickyActionBar(
          child: _revealed
              ? AppButton.primary(
                  label: 'Continue',
                  isLoading: _saving,
                  onPressed: _next,
                )
              : AppButton.primary(
                  label: 'Reveal meaning',
                  onPressed: () => setState(() => _revealed = true),
                ),
        );
      case QuestionExercise():
        body = QuestionView(
          exercise: exercise,
          picked: _picked,
          checked: _checked,
          onPick: (i) => setState(() => _picked = i),
        );
        bottom = _checked
            ? FeedbackPanel(
                correct: _picked == exercise.correctIndex,
                correctAnswer: exercise.correctAnswer,
                explanation: exercise.explanation,
                onContinue: _saving ? () {} : _next,
              )
            : StickyActionBar(
                child: AppButton.primary(
                  label: 'Check',
                  onPressed: _picked == null ? null : _check,
                ),
              );
    }

    return Scaffold(
      appBar: SessionTopBar(
        onClose: _confirmLeave,
        closeTooltip: _closeTooltip,
        progress: done / _exercises.length,
        counter: '$done/${_exercises.length}',
        progressLabel: 'Lesson progress',
      ),
      body: ListView(
        // A fresh scroll position for each exercise.
        key: ValueKey(_index),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [body],
      ),
      bottomNavigationBar: bottom,
    );
  }

  Widget _complete() {
    final today = ref.watch(todayProvider);
    final minutes =
        ref.watch(progressControllerProvider).value?.minutesOn(today) ?? 0;
    final goal =
        ref.watch(onboardingControllerProvider).value?.dailyMinutes ??
        OnboardingState.defaultDailyMinutes;
    final following = widget.following;
    return Scaffold(
      body: SafeArea(
        child: LessonCompleteView(
          lessonTitle: widget.lesson.title,
          completion: _completion!,
          minutesToday: minutes,
          dailyGoal: goal,
        ),
      ),
      bottomNavigationBar: StickyActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (following != null) ...[
              AppButton.primary(
                label: 'Continue',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    context.pushReplacement(AppRoutes.lessonPath(following.id)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton.outline(
              label: 'Back to Home',
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen message with a way back (locked, coming soon, errors).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    void back() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.learn);
    return Scaffold(
      appBar: SessionTopBar(onClose: back, closeTooltip: _closeTooltip),
      body: EmptyStateView(
        icon: icon,
        title: title,
        message: message,
        action: Column(
          children: [
            if (onAction != null) ...[
              AppButton.primary(
                label: actionLabel!,
                expand: false,
                onPressed: onAction,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton.outline(label: 'Go back', expand: false, onPressed: back),
          ],
        ),
      ),
    );
  }
}
