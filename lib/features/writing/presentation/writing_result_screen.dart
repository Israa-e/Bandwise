import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/writing.dart';
import '../domain/writing_feedback.dart';
import '../domain/writing_repository.dart';
import '../domain/writing_submission.dart';
import 'widgets/feedback_widgets.dart';
import 'widgets/line_chart_view.dart';
import 'widgets/submission_loader.dart';
import 'writing_editor_screen.dart';
import 'writing_providers.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// After submitting: evaluating, then feedback, or an error with Retry.
class WritingResultScreen extends ConsumerWidget {
  const WritingResultScreen({
    super.key,
    required this.submissionId,
    this.timeUp = false,
  });

  final String submissionId;

  /// Arrived here because the time ran out.
  final bool timeUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SubmissionLoader(
      submissionId: submissionId,
      builder: (context, task, submission, all) {
        final result = ref.watch(writingResultProvider(submissionId));
        void close() => context.go(AppRoutes.writingHub);
        final Widget body;
        Widget? bottom;
        if (result.hasValue && !result.isLoading) {
          final view = switch (result.requireValue) {
            AnalysedResult(:final feedback, :final sample) => FeedbackOverview(
              task: task,
              submission: submission,
              feedback: feedback,
              sample: sample,
            ),
            DemoResult() => DemoFeedbackView(
              task: task,
              submission: submission,
            ),
          };
          body = view;
          bottom = _Actions(submission: submission);
        } else if (result.hasError && !result.isLoading) {
          body = EmptyStateView(
            key: const ValueKey('feedbackError'),
            icon: Icons.cloud_off_rounded,
            title: "Feedback isn't available right now",
            message: 'Your essay is saved.',
            action: Column(
              children: [
                AppButton.primary(
                  label: 'Retry',
                  expand: false,
                  onPressed: () =>
                      ref.invalidate(writingResultProvider(submissionId)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.outline(
                  label: 'Back to Writing',
                  expand: false,
                  onPressed: close,
                ),
              ],
            ),
          );
        } else {
          body = const _Evaluating();
        }
        return Scaffold(
          appBar: TitledSessionTopBar(
            title: 'Feedback · ${task.type.label}',
            closeTooltip: 'Close feedback',
            onClose: close,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (timeUp || submission.timeUp)
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
                      key: ValueKey('timeUp'),
                      type: InfoBannerType.warning,
                      icon: Icons.timer_off_outlined,
                      title: "Time's up",
                      message: 'Your essay was submitted automatically.',
                    ),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
          bottomNavigationBar: bottom,
        );
      },
    );
  }
}

/// A calm, indeterminate wait. No steps or percentages: we don't know how
/// far along the review is.
class _Evaluating extends StatelessWidget {
  const _Evaluating();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('evaluating'),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Reviewing your essay',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSm,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This usually takes a few seconds. Your essay is saved, so '
                'you can leave and come back.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.submission});

  final WritingSubmission submission;

  @override
  Widget build(BuildContext context) {
    final revise = AppButton.primary(
      label: 'Revise and resubmit',
      leadingIcon: Icons.edit_rounded,
      onPressed: () => context.push(AppRoutes.writingRevise(submission.id)),
    );
    if (submission.revisionOf == null) return StickyActionBar(child: revise);
    return StickyActionBar(
      child: Row(
        children: [
          Expanded(
            child: AppButton.outline(
              label: 'Compare drafts',
              onPressed: () =>
                  context.push(AppRoutes.writingCompare(submission.id)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: revise),
        ],
      ),
    );
  }
}

/// "Task 1 · Academic report", the topic, and the essay's length and time.
class _EssayHeader extends StatelessWidget {
  const _EssayHeader({required this.task, required this.submission});

  final WritingTask task;
  final WritingSubmission submission;

  @override
  Widget build(BuildContext context) {
    final chart = task.chart;
    final details = [
      '${submission.wordCount} words',
      TimerPill.format(submission.timeUsed),
      if (submission.revisionOf != null)
        'Revision'
      else
        submission.mode == WritingMode.timed ? 'Timed' : 'Learning',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${task.type.label} · ${task.type.kind}',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(task.topic, style: AppTextStyles.headlineMd),
        const SizedBox(height: 2),
        Text(
          details,
          style: AppTextStyles.tabular(
            AppTextStyles.bodySm,
          ).copyWith(color: AppColors.textMuted),
        ),
        if (chart != null)
          TextButton.icon(
            onPressed: () => showChartSheet(context, chart),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 40),
            ),
            icon: const Icon(Icons.show_chart_rounded, size: 18),
            label: const Text('View chart'),
          ),
      ],
    );
  }
}

/// Full feedback: the overall and criterion estimates, top improvements,
/// notes on the essay and paragraph notes.
class FeedbackOverview extends StatelessWidget {
  const FeedbackOverview({
    super.key,
    required this.task,
    required this.submission,
    required this.feedback,
    required this.sample,
  });

  final WritingTask task;
  final WritingSubmission submission;
  final WritingFeedback feedback;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final paragraphs = paragraphsOf(submission.text);
    return ListView(
      key: ValueKey('feedbackOverview-${task.type.name}'),
      padding: _padding,
      children: [
        _EssayHeader(task: task, submission: submission),
        const SizedBox(height: AppSpacing.smd),
        if (sample) ...[
          const InfoBanner(
            key: ValueKey('sampleNotice'),
            message:
                "AI review isn't connected yet, so this is prepared feedback "
                'for the sample essay.',
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        AppCard(
          key: const ValueKey('overallCard'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall', style: AppTextStyles.labelLg),
              const SizedBox(height: AppSpacing.xxs),
              EstimateRangeText(
                range: feedback.overall,
                style: AppTextStyles.headlineXl,
              ),
              const SizedBox(height: AppSpacing.sm),
              const EstimateLabel(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Criteria'),
        for (final criterion in task.type.criteria)
          if (feedback.criterion(criterion.id) case final c?) ...[
            _CriterionCard(
              criterion: criterion,
              feedback: c,
              onTap: () => context.push(
                AppRoutes.writingCriterion(submission.id, criterion.id),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const EstimateLabel(),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Top improvements'),
        _NumberedList(items: feedback.topImprovements),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Notes on your essay'),
        AppCard(
          key: const ValueKey('annotationsCard'),
          onTap: () => context.push(AppRoutes.writingEssay(submission.id)),
          semanticLabel:
              '${feedback.annotations.length} notes on your essay. Open '
              'the annotated essay',
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnnotationStatsRow(annotations: feedback.annotations),
                const SizedBox(height: AppSpacing.smd),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'View your essay with notes',
                        style: AppTextStyles.labelLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (feedback.paragraphNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Paragraph by paragraph'),
          for (final note in feedback.paragraphNotes)
            if (note.paragraph < paragraphs.length) ...[
              _ParagraphNoteCard(
                index: note.paragraph,
                paragraph: paragraphs[note.paragraph],
                note: note.note,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ],
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({
    required this.criterion,
    required this.feedback,
    required this.onTap,
  });

  final WritingCriterion criterion;
  final CriterionFeedback feedback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('criterion-${criterion.id}'),
      onTap: onTap,
      semanticLabel:
          '${criterion.label}: ${feedback.range.spoken}, $estimateLabel. '
          '${feedback.strength}',
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(criterion.label, style: AppTextStyles.labelLg),
                ),
                const SizedBox(width: AppSpacing.sm),
                EstimateRangeText(range: feedback.range),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              feedback.strength,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items});

  final List<TopImprovement> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.smd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.smd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppTextStyles.labelLg),
                      const SizedBox(height: 2),
                      Text(item.detail, style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ParagraphNoteCard extends StatelessWidget {
  const _ParagraphNoteCard({
    required this.index,
    required this.paragraph,
    required this.note,
  });

  final int index;
  final String paragraph;
  final String note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paragraph ${index + 1}', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            paragraph,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(note, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

/// For an essay that wasn't analysed: general advice only, no estimates and
/// no notes on the text.
class DemoFeedbackView extends StatelessWidget {
  const DemoFeedbackView({
    super.key,
    required this.task,
    required this.submission,
  });

  final WritingTask task;
  final WritingSubmission submission;

  @override
  Widget build(BuildContext context) {
    final general = generalFeedbackFor(task.type);
    return ListView(
      key: const ValueKey('demoFeedback'),
      padding: _padding,
      children: [
        _EssayHeader(task: task, submission: submission),
        const SizedBox(height: AppSpacing.smd),
        InfoBanner(
          key: const ValueKey('demoBanner'),
          type: InfoBannerType.warning,
          title: "Demo feedback — AI review isn't connected yet",
          message:
              "Your essay hasn't been analysed, so there are no estimates "
              'and no notes on your text. Here is general advice for '
              '${task.type.label}.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('What to check'),
        for (final criterion in task.type.criteria) ...[
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(criterion.label, style: AppTextStyles.labelLg),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  general.criteriaTips[criterion]!,
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        const SectionTitle('Before you revise'),
        _NumberedList(items: general.checklist),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your essay', style: AppTextStyles.labelLg),
              const SizedBox(height: AppSpacing.xs),
              for (final p in paragraphsOf(submission.text))
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(p, style: AppTextStyles.bodyMd),
                ),
              WordCountLabel(
                words: submission.wordCount,
                minimum: task.type.minWords,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
