import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/essay_diff.dart';
import 'widgets/submission_loader.dart';

/// The revision and the draft it revised, compared word by word for each
/// paragraph. Shows what changed, never a score change.
class RevisionCompareScreen extends StatelessWidget {
  const RevisionCompareScreen({super.key, required this.submissionId});

  final String submissionId;

  static const note =
      'Resubmissions show how your writing changed, not a new official '
      'score.';

  @override
  Widget build(BuildContext context) {
    return SubmissionLoader(
      submissionId: submissionId,
      builder: (context, task, submission, all) {
        final previous = all
            .where((s) => s.id == submission.revisionOf)
            .firstOrNull;
        if (previous == null) {
          return const Scaffold(
            appBar: TabTopBar(title: 'Compare drafts', showBack: true),
            body: EmptyStateView(
              icon: Icons.compare_arrows_rounded,
              title: 'Nothing to compare',
              message: 'This essay is not a revision of another one.',
            ),
          );
        }
        final diffs = diffEssays(previous.text, submission.text);
        final total = diffs.fold(
          const ChangeCounts(),
          (sum, d) => sum + d.counts,
        );
        return Scaffold(
          appBar: const TabTopBar(title: 'Compare drafts', showBack: true),
          body: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.smd,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              const InfoBanner(key: ValueKey('compareNote'), message: note),
              const SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ResultStatTile(
                        key: const ValueKey('count-added'),
                        label: 'Added',
                        value: '${total.added}',
                        caption: 'words',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ResultStatTile(
                        key: const ValueKey('count-removed'),
                        label: 'Removed',
                        value: '${total.removed}',
                        caption: 'words',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ResultStatTile(
                        key: const ValueKey('count-replaced'),
                        label: 'Replaced',
                        value: '${total.replaced}',
                        caption: total.replaced == 1 ? 'phrase' : 'phrases',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Draft 1: ${previous.wordCount} words · '
                'Draft 2: ${submission.wordCount} words',
                style: AppTextStyles.tabular(
                  AppTextStyles.bodySm,
                ).copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _DiffLegend(),
              const SizedBox(height: AppSpacing.md),
              for (final d in diffs) ...[
                _ParagraphDiffCard(diff: d),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

const _removedStyle = TextStyle(
  color: AppColors.errorText,
  backgroundColor: AppColors.errorTint,
  decoration: TextDecoration.lineThrough,
  decorationColor: AppColors.errorText,
);

const _addedStyle = TextStyle(
  backgroundColor: AppColors.successTint,
  decoration: TextDecoration.underline,
  decorationColor: AppColors.success,
  decorationThickness: 2,
  fontWeight: FontWeight.w600,
);

class _DiffLegend extends StatelessWidget {
  const _DiffLegend();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'Removed', style: _removedStyle),
          TextSpan(text: ': crossed out    '),
          TextSpan(text: 'Added', style: _addedStyle),
          TextSpan(text: ': underlined and bold'),
        ],
      ),
      style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
    );
  }
}

class _ParagraphDiffCard extends StatelessWidget {
  const _ParagraphDiffCard({required this.diff});

  final ParagraphDiff diff;

  @override
  Widget build(BuildContext context) {
    final counts = diff.counts;
    final summary = !diff.changed
        ? 'No changes'
        : diff.before == null
        ? 'New paragraph'
        : diff.after == null
        ? 'Paragraph removed'
        : [
            if (counts.added > 0) '${counts.added} added',
            if (counts.removed > 0) '${counts.removed} removed',
            if (counts.replaced > 0) '${counts.replaced} replaced',
          ].join(' · ');
    return AppCard(
      key: ValueKey('diff-${diff.index}'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Paragraph ${diff.index + 1}',
                  style: AppTextStyles.labelLg,
                ),
              ),
              Text(
                summary,
                style: AppTextStyles.tabular(
                  AppTextStyles.labelMd,
                ).copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(
            TextSpan(
              children: [
                for (final (i, s) in diff.segments.indexed) ...[
                  if (i > 0) const TextSpan(text: ' '),
                  TextSpan(
                    text: s.text,
                    style: switch (s.op) {
                      DiffOp.same => null,
                      DiffOp.added => _addedStyle,
                      DiffOp.removed => _removedStyle,
                    },
                    semanticsLabel: switch (s.op) {
                      DiffOp.same => null,
                      DiffOp.added => 'added: ${s.text}',
                      DiffOp.removed => 'removed: ${s.text}',
                    },
                  ),
                ],
              ],
            ),
            style: AppTextStyles.bodyMd,
          ),
        ],
      ),
    );
  }
}
