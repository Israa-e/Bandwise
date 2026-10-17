import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/skill.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../domain/writing.dart';
import '../domain/writing_submission.dart';
import 'writing_providers.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// Writing hub: pick Task 1 or Task 2 and a mode, continue a draft, and see
/// recent essays.
class WritingHubScreen extends ConsumerStatefulWidget {
  const WritingHubScreen({super.key});

  @override
  ConsumerState<WritingHubScreen> createState() => _WritingHubScreenState();
}

class _WritingHubScreenState extends ConsumerState<WritingHubScreen> {
  String? _taskId;
  var _mode = WritingMode.learning;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(writingTasksProvider);
    final drafts = ref.watch(writingDraftsProvider);
    final submissions = ref.watch(writingSubmissionsProvider);

    final error = [
      tasks,
      drafts,
      submissions,
    ].any((a) => a.hasError && !a.isLoading);
    final ready = tasks.hasValue && drafts.hasValue && submissions.hasValue;

    final Widget body;
    Widget? bottom;
    if (error) {
      body = ListView(
        padding: _padding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load writing practice",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () {
              ref
                ..invalidate(writingTasksProvider)
                ..invalidate(writingDraftsProvider)
                ..invalidate(writingSubmissionsProvider);
            },
          ),
        ],
      );
    } else if (ready) {
      final list = tasks.requireValue;
      final task = list.where((t) => t.id == _taskId).firstOrNull ?? list.first;
      final draft =
          drafts.requireValue[WritingDraft.draftIdFor(taskId: task.id)];
      body = _content(list, task, draft, submissions.requireValue);
      bottom = StickyActionBar(
        child: draft == null
            ? AppButton.primary(
                label: 'Start writing',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => _start(task),
              )
            : Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: 'Start over',
                      onPressed: () => _startOver(task, draft),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Continue draft',
                      onPressed: () => context.push(
                        AppRoutes.writingTask(
                          task.id,
                          timed: draft.mode == WritingMode.timed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: const TabTopBar(title: 'Writing', showBack: true),
      body: body,
      bottomNavigationBar: bottom,
    );
  }

  void _start(WritingTask task) => context.push(
    AppRoutes.writingTask(task.id, timed: _mode == WritingMode.timed),
  );

  Future<void> _startOver(WritingTask task, WritingDraft draft) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: Text(
          'Your draft (${countWords(draft.text)} words) will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Delete draft'),
          ),
        ],
      ),
    );
    if (!(discard ?? false) || !mounted) return;
    await ref.read(writingDraftsProvider.notifier).delete(draft.id);
    if (mounted) _start(task);
  }

  Widget _content(
    List<WritingTask> tasks,
    WritingTask task,
    WritingDraft? draft,
    List<WritingSubmission> submissions,
  ) {
    final timed = _mode == WritingMode.timed;
    return ListView(
      padding: _padding,
      children: [
        const SectionTitle('Task'),
        for (final t in tasks) ...[
          _TaskCard(
            task: t,
            selected: t.id == task.id,
            onTap: () => setState(() => _taskId = t.id),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        if (draft != null) ...[
          _DraftNotice(draft: draft),
          const SizedBox(height: AppSpacing.smd),
        ],
        const SizedBox(height: AppSpacing.sm),
        const SectionTitle('Mode'),
        if (draft != null)
          Text(
            'Your draft continues in ${draft.mode == WritingMode.timed ? 'timed' : 'learning'} '
            'mode. Start over to change mode.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          )
        else ...[
          SelectionCard(
            title: 'Learning',
            subtitle:
                'No timer. Structure tips and a space to plan your essay.',
            leading: const SelectionLeadingBox(icon: Icons.school_rounded),
            state: timed
                ? SelectionCardState.idle
                : SelectionCardState.selected,
            onTap: () => setState(() => _mode = WritingMode.learning),
          ),
          const SizedBox(height: AppSpacing.smd),
          SelectionCard(
            title: 'Timed',
            subtitle:
                '${task.type.minutes} minutes, no tips and no spell check, '
                'like the computer-delivered test.',
            leading: const SelectionLeadingBox(icon: Icons.timer_outlined),
            state: timed
                ? SelectionCardState.selected
                : SelectionCardState.idle,
            onTap: () => setState(() => _mode = WritingMode.timed),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Recent essays'),
        _RecentEssays(submissions: submissions, tasks: tasks),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Debug'),
          SwitchCard(
            title: 'Simulate feedback error',
            subtitle: 'The mock review fails, to show the error state.',
            value: ref.watch(writingDebugProvider),
            onChanged: ref.read(writingDebugProvider.notifier).setSimulateError,
          ),
        ],
      ],
    );
  }
}

/// A task in the Writing skill colors.
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final WritingTask task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('writingTask-${task.id}'),
      selected: selected,
      color: selected ? null : Skill.writing.tint,
      onTap: onTap,
      semanticLabel:
          '${task.type.label}, ${task.type.kind}: ${task.topic}. '
          '${task.type.minutes} minutes, at least ${task.type.minWords} '
          'words',
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadii.nestedRadius,
              ),
              child: Icon(
                task.chart == null
                    ? Icons.edit_note_rounded
                    : Icons.show_chart_rounded,
                color: Skill.writing.color,
              ),
            ),
            const SizedBox(width: AppSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.type.label} · ${task.type.kind}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(task.topic, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    task.type.summary,
                    style: AppTextStyles.tabular(
                      AppTextStyles.bodySm,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftNotice extends ConsumerWidget {
  const _DraftNotice({required this.draft});

  final WritingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final words = countWords(draft.text);
    return InfoBanner(
      key: const ValueKey('draftNotice'),
      icon: Icons.edit_document,
      title: 'Draft saved',
      message:
          '$words ${words == 1 ? 'word' : 'words'} · '
          '${draft.mode == WritingMode.timed ? 'Timed' : 'Learning'} · '
          'saved ${timeAgoLabel(today, draft.savedAt)}',
    );
  }
}

/// The latest essays, newest first.
class _RecentEssays extends ConsumerWidget {
  const _RecentEssays({required this.submissions, required this.tasks});

  static const _shown = 5;

  final List<WritingSubmission> submissions;
  final List<WritingTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (submissions.isEmpty) {
      return Text(
        'No essays yet. Your submitted essays and their feedback will '
        'appear here.',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
      );
    }
    final today = ref.watch(todayProvider);
    final recent = submissions.reversed.take(_shown).toList();
    return Column(
      children: [
        for (final (i, s) in recent.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _EssayRow(
            submission: s,
            task: tasks.where((t) => t.id == s.taskId).firstOrNull,
            today: today,
          ),
        ],
      ],
    );
  }
}

class _EssayRow extends StatelessWidget {
  const _EssayRow({
    required this.submission,
    required this.task,
    required this.today,
  });

  final WritingSubmission submission;
  final WritingTask? task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final s = submission;
    final title = [?task?.type.label, task?.topic ?? 'Essay'].join(' · ');
    final details = [
      if (s.revisionOf != null)
        'Revision'
      else
        s.mode == WritingMode.timed ? 'Timed' : 'Learning',
      '${s.wordCount} words',
      timeAgoLabel(today, s.submittedAt),
    ].join(' · ');
    final status = switch (s.result) {
      null => 'Feedback pending',
      AnalysedResult() => 'Feedback ready',
      DemoResult() => 'Demo feedback',
    };
    return AppCard(
      key: ValueKey('essay-${s.id}'),
      onTap: () => context.push(AppRoutes.writingResult(s.id)),
      semanticLabel: '$title, $details. $status',
      padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: AppPill(
                label: status,
                background: s.result is AnalysedResult
                    ? AppColors.successTint
                    : AppColors.primaryTint,
                foreground: AppColors.text,
                size: AppPillSize.small,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
