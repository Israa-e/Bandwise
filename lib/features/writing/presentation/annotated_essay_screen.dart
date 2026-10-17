import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/writing.dart';
import '../domain/writing_feedback.dart';
import '../domain/writing_submission.dart';
import 'widgets/feedback_widgets.dart';
import 'widgets/submission_loader.dart';

/// The essay with its notes highlighted, filtered by type.
class AnnotatedEssayScreen extends StatefulWidget {
  const AnnotatedEssayScreen({super.key, required this.submissionId});

  final String submissionId;

  @override
  State<AnnotatedEssayScreen> createState() => _AnnotatedEssayScreenState();
}

class _AnnotatedEssayScreenState extends State<AnnotatedEssayScreen> {
  /// Null shows every type.
  AnnotationType? _filter;

  @override
  Widget build(BuildContext context) {
    return SubmissionLoader(
      submissionId: widget.submissionId,
      builder: (context, task, submission, all) {
        final feedback = switch (submission.result) {
          AnalysedResult(:final feedback) => feedback,
          _ => null,
        };
        if (feedback == null) {
          return const Scaffold(
            appBar: TabTopBar(title: 'Your essay', showBack: true),
            body: EmptyStateView(
              icon: Icons.notes_rounded,
              title: 'No notes on this essay',
              message: 'Notes appear when an essay has been reviewed.',
            ),
          );
        }
        final shown = [
          for (final a in feedback.annotations)
            if (_filter == null || a.type == _filter) a,
        ]..sort((a, b) => a.start.compareTo(b.start));
        return Scaffold(
          appBar: const TabTopBar(title: 'Your essay', showBack: true),
          body: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.page,
              AppSpacing.smd,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              AnnotationStatsRow(annotations: feedback.annotations),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppFilterChip(
                    key: const ValueKey('filter-all'),
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final type in AnnotationType.values)
                    AppFilterChip(
                      key: ValueKey('filter-${type.name}'),
                      label: type.label,
                      selected: _filter == type,
                      onTap: () => setState(() => _filter = type),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.smd),
              _Legend(
                types: _filter == null ? AnnotationType.values : [_filter!],
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                key: const ValueKey('annotatedEssay'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, p) in paragraphSpansOf(
                      submission.text,
                    ).indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      AnnotatedParagraph(
                        text: p.text,
                        offset: p.start,
                        annotations: shown,
                        onTap: (a) => showAnnotationSheet(
                          context,
                          notes: shown,
                          index: shown.indexOf(a),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap a highlighted phrase to see the note. The notes '
                'explain; any changes are yours to make when you revise.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Which icon and underline each type uses.
class _Legend extends StatelessWidget {
  const _Legend({required this.types});

  final List<AnnotationType> types;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final type in types)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 16, color: type.color),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  '${type.label}: ${type.underlineName.toLowerCase()}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
