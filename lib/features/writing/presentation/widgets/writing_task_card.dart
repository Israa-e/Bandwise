import 'package:flutter/material.dart';

import '../../../../core/models/skill.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/writing.dart';
import 'line_chart_view.dart';

/// The task: its type and time, the prompt and, for Task 1, the chart.
/// Collapsible, so the editor gets more room. Not animated.
///
/// The chart starts open; it closes to "View chart" when [collapseChart]
/// turns true (the student started typing), and can be opened again.
class WritingTaskCard extends StatefulWidget {
  const WritingTaskCard({
    super.key,
    required this.task,
    this.initiallyExpanded = true,
    this.collapseChart = false,
  });

  final WritingTask task;
  final bool initiallyExpanded;
  final bool collapseChart;

  @override
  State<WritingTaskCard> createState() => _WritingTaskCardState();
}

class _WritingTaskCardState extends State<WritingTaskCard> {
  late var _expanded = widget.initiallyExpanded;
  late var _chartOpen = !widget.collapseChart;

  @override
  void didUpdateWidget(WritingTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collapseChart && !oldWidget.collapseChart) _chartOpen = false;
  }

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
              // Short, and given all the free width, so it isn't cut.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SkillChip(
                    skill: Skill.writing,
                    label: '${task.type.label} · ${task.type.minutes} min',
                    size: AppPillSize.small,
                  ),
                ),
              ),
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
                if (chart != null) ...[
                  if (_chartOpen) ...[
                    const SizedBox(height: AppSpacing.md),
                    ChartView(key: const ValueKey('taskChart'), data: chart),
                  ],
                  TextButton.icon(
                    key: const ValueKey('chartToggle'),
                    onPressed: () => setState(() => _chartOpen = !_chartOpen),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 40),
                    ),
                    icon: Icon(
                      _chartOpen
                          ? Icons.expand_less_rounded
                          : Icons.show_chart_rounded,
                      size: 18,
                    ),
                    label: Text(_chartOpen ? 'Hide chart' : 'View chart'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
