import 'package:flutter/material.dart';

import '../../../../core/models/skill.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/writing.dart';
import 'line_chart_view.dart';

/// The task: its type, time and length, the prompt and, for Task 1,
/// "View chart". Collapsible, so the editor gets more room. Not animated.
class WritingTaskCard extends StatefulWidget {
  const WritingTaskCard({
    super.key,
    required this.task,
    this.initiallyExpanded = true,
  });

  final WritingTask task;
  final bool initiallyExpanded;

  @override
  State<WritingTaskCard> createState() => _WritingTaskCardState();
}

class _WritingTaskCardState extends State<WritingTaskCard> {
  late var _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final chart = task.chart;
    return AppCard(
      key: const ValueKey('taskCard'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: SkillChip(
                  skill: Skill.writing,
                  label: '${task.type.label} · ${task.type.summary}',
                  size: AppPillSize.small,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('taskCardToggle'),
                tooltip: _expanded ? 'Hide task' : 'Show task',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.smd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_expanded) ...[
                  Text(task.prompt, style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    task.instructions,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else
                  Text(
                    task.prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}
