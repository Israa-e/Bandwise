import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/writing.dart';
import '../domain/writing_submission.dart';
import 'widgets/feedback_widgets.dart';
import 'widgets/submission_loader.dart';

/// One criterion: its estimate, what went well, what to improve, and the
/// notes on the essay that belong to it.
class CriterionDetailScreen extends ConsumerWidget {
  const CriterionDetailScreen({
    super.key,
    required this.submissionId,
    required this.criterionId,
  });

  final String submissionId;
  final String criterionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SubmissionLoader(
      submissionId: submissionId,
      builder: (context, task, submission, all) {
        final criterion = WritingCriterion.byId(criterionId);
        final feedback = switch (submission.result) {
          AnalysedResult(:final feedback) => feedback,
          _ => null,
        };
        final c = feedback?.criterion(criterionId);
        if (criterion == null || feedback == null || c == null) {
          return const Scaffold(
            appBar: TabTopBar(title: 'Criterion', showBack: true),
            body: EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'No feedback for this criterion',
            ),
          );
        }
        final notes = feedback.annotationsFor(criterionId);
        Widget section(String title, String text, IconData icon) => AppCard(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(title, style: AppTextStyles.labelLg)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(text, style: AppTextStyles.bodyMd),
            ],
          ),
        );

        return Scaffold(
          appBar: TabTopBar(title: criterion.label, showBack: true),
          body: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.smd,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${task.type.label} · ${criterion.label}',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    EstimateRangeText(
                      range: c.range,
                      style: AppTextStyles.headlineXl,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const EstimateLabel(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              section(
                'What you did well',
                c.strength,
                Icons.thumb_up_alt_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              section('What to improve', c.improvement, Icons.trending_up),
              const SizedBox(height: AppSpacing.sm),
              section(
                'About this criterion',
                c.explanation,
                Icons.info_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle('Examples from your essay'),
              if (notes.isEmpty)
                Text(
                  'No notes on specific phrases for this criterion.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              else
                for (final (i, note) in notes.indexed) ...[
                  AppCard(
                    key: ValueKey('example-${note.id}'),
                    onTap: () =>
                        showAnnotationSheet(context, notes: notes, index: i),
                    semanticLabel:
                        '${note.type.label} note: ${note.original}. '
                        'Open the note',
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          Icon(
                            note.type.icon,
                            size: 20,
                            color: note.type.color,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '‘${note.original}’',
                              style: AppTextStyles.bodyMd,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        );
      },
    );
  }
}
