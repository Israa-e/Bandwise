import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../lesson/presentation/widgets/exercise_views.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/domain/review_schedule.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/review_planner.dart';
import 'review_providers.dart';
import 'widgets/review_complete_view.dart';
import 'widgets/review_rating_bar.dart';

const _closeTooltip = 'Close review';

/// Daily review, outside the tab shell: saved mistakes and vocabulary due
/// today. Each item is saved as soon as it's rated, so closing needs no
/// confirmation.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  /// The queue when the screen opened. Kept for the whole session: rating
  /// items changes progress, but shouldn't change what this session shows.
  List<ReviewItem>? _queue;

  @override
  Widget build(BuildContext context) {
    final planner = ref.watch(reviewPlannerProvider);
    final today = ref.watch(todayProvider);
    if (_queue == null && planner.hasValue && !planner.hasError) {
      _queue = planner.requireValue.dueOn(today);
    }
    final queue = _queue;
    if (queue != null) {
      return queue.isEmpty
          ? _NothingDue(next: planner.value?.nextReviewAfter(today))
          : _ReviewSession(queue: queue);
    }
    if (planner.hasError && !planner.isLoading) {
      return _Shell(
        child: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: "Couldn't load your reviews",
          message: 'Check your connection and try again.',
          action: AppButton.primary(
            label: 'Retry',
            expand: false,
            onPressed: () => ref.invalidate(reviewPlannerProvider),
          ),
        ),
      );
    }
    return const _Shell(child: Center(child: CircularProgressIndicator()));
  }
}

void _exit(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.home);

/// A screen with only the close button in the top bar.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SessionTopBar(
        onClose: () => _exit(context),
        closeTooltip: _closeTooltip,
      ),
      body: child,
    );
  }
}

class _NothingDue extends ConsumerWidget {
  const _NothingDue({required this.next});

  final DateTime? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = this.next;
    final today = ref.watch(todayProvider);
    return _Shell(
      child: EmptyStateView(
        icon: Icons.task_alt_rounded,
        title: 'Nothing to review right now',
        message: next == null
            ? 'Mistakes from lessons and the words you learn will appear '
                  'here when they are due.'
            : 'Your next review is ${_dayLabel(today, next)}.',
        action: AppButton.primary(
          label: 'Back to Home',
          expand: false,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime today, DateTime day) =>
      daysBetween(today, day) == 1 ? 'tomorrow' : 'on ${formatShortDate(day)}';
}

class _ReviewSession extends ConsumerStatefulWidget {
  const _ReviewSession({required this.queue});

  final List<ReviewItem> queue;

  @override
  ConsumerState<_ReviewSession> createState() => _ReviewSessionState();
}

class _ReviewSessionState extends ConsumerState<_ReviewSession> {
  /// Items still to finish. "Again" moves the current item to the end.
  late final List<ReviewItem> _queue = [...widget.queue];
  late final int _total = widget.queue.length;
  var _done = 0;
  var _xp = 0;

  final _startedAt = DateTime.now();
  var _ratings = 0;
  var _minutesRecorded = 0;

  int? _picked;
  var _checked = false;
  var _revealed = false;
  var _saving = false;

  /// Bumped per shown item so each gets a fresh scroll position.
  var _shown = 0;

  bool get _finished => _queue.isEmpty;
  ReviewItem get _current => _queue.first;

  /// Whole minutes since the session started, rounded up and capped at two
  /// per rated item so an idle screen doesn't count as study time.
  int _sessionMinutes() {
    final elapsed = DateTime.now().difference(_startedAt);
    return (elapsed.inSeconds / 60).ceil().clamp(1, _ratings * 2);
  }

  Future<void> _rate(ReviewRating rating) async {
    if (_saving) return;
    setState(() => _saving = true);
    final item = _current;
    _ratings++;
    final minutes = _sessionMinutes() - _minutesRecorded;
    _minutesRecorded += minutes;
    final xp = await ref
        .read(progressControllerProvider.notifier)
        .review(
          ReviewCompletion(
            key: item.key,
            rating: rating,
            date: ref.read(todayProvider),
            minutes: minutes,
          ),
        );
    if (!mounted) return;
    setState(() {
      _queue.removeAt(0);
      if (rating == ReviewRating.again) {
        _queue.add(item);
      } else {
        _done++;
      }
      _xp += xp;
      _picked = null;
      _checked = false;
      _revealed = false;
      _saving = false;
      _shown++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _finished ? _complete() : _item();
  }

  Widget _item() {
    final item = _current;
    // The latest schedule: an item rated Again earlier in this session has
    // a newer one than when the queue was built.
    final schedule = ref
        .watch(progressControllerProvider)
        .value
        ?.reviews[item.key];
    final rating = ReviewRatingBar(
      schedule: schedule,
      onRate: _rate,
      enabled: !_saving,
    );

    final Widget body;
    final Widget bottom;
    switch (item) {
      case WordReviewItem(:final card):
        body = FlashcardView(
          exercise: card,
          revealed: _revealed,
          eyebrow: 'Vocabulary review',
        );
        bottom = StickyActionBar(
          child: _revealed
              ? rating
              : AppButton.primary(
                  label: 'Reveal meaning',
                  onPressed: () => setState(() => _revealed = true),
                ),
        );
      case MistakeReviewItem(:final exercise):
        body = QuestionView(
          exercise: exercise,
          picked: _picked,
          checked: _checked,
          onPick: (i) => setState(() => _picked = i),
        );
        final correct = _picked == exercise.correctIndex;
        bottom = !_checked
            ? StickyActionBar(
                child: AppButton.primary(
                  label: 'Check',
                  onPressed: _picked == null
                      ? null
                      : () => setState(() => _checked = true),
                ),
              )
            : correct
            ? FeedbackPanel(
                correct: true,
                correctAnswer: exercise.correctAnswer,
                explanation: exercise.explanation,
                action: rating,
              )
            // A wrong answer is "Again": the question comes back later in
            // this session.
            : FeedbackPanel(
                correct: false,
                correctAnswer: exercise.correctAnswer,
                explanation: exercise.explanation,
                action: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "You'll see this question again in this review.",
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.smd),
                    AppButton.primary(
                      label: 'Continue',
                      isLoading: _saving,
                      onPressed: () => _rate(ReviewRating.again),
                    ),
                  ],
                ),
              );
    }

    final position = (_done + 1).clamp(1, _total);
    return Scaffold(
      appBar: SessionTopBar(
        onClose: () => _exit(context),
        closeTooltip: _closeTooltip,
        progress: _done / _total,
        counter: '$position of $_total',
        progressLabel: 'Review progress',
      ),
      body: ListView(
        key: ValueKey(_shown),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          _Source(item: item),
          const SizedBox(height: AppSpacing.smd),
          body,
        ],
      ),
      bottomNavigationBar: bottom,
    );
  }

  Widget _complete() {
    final today = ref.watch(todayProvider);
    final next = ref.watch(reviewPlannerProvider).value?.nextReviewAfter(today);
    final progress = ref.watch(progressControllerProvider).value;
    return Scaffold(
      body: SafeArea(
        child: ReviewCompleteView(
          reviewed: _done,
          xpEarned: _xp,
          today: today,
          nextReview: next,
          xpCapReached:
              (progress?.reviewXpOn(today) ?? 0) >= XpRules.maxReviewPerDay,
        ),
      ),
      bottomNavigationBar: StickyActionBar(
        child: AppButton.primary(
          label: 'Back to Home',
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
    );
  }
}

/// Where the item comes from: "Saved mistake · Unit 2, Lesson 1".
class _Source extends StatelessWidget {
  const _Source({required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final lesson = item.lesson;
    final (label, icon) = switch (item) {
      MistakeReviewItem() => ('Saved mistake', Icons.bookmark_rounded),
      WordReviewItem() => ('Saved word', Icons.style_rounded),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.warning),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            '$label · Unit ${lesson.unit}, ${lesson.label}',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
