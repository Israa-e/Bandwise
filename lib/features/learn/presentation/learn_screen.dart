import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../domain/course.dart';
import '../domain/learning_path.dart';
import 'learn_providers.dart';
import 'widgets/path_view.dart';

const _listPadding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// The Learn tab: one unit's path of lessons.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(learningPathProvider);
    final today = ref.watch(todayProvider);
    final value = path.value;

    final Widget body;
    if (value != null && !path.hasError) {
      body = _LearnContent(path: value);
    } else if (path.hasError && !path.isLoading) {
      body = ListView(
        padding: _listPadding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load your path",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(learningPathProvider),
          ),
        ],
      );
    } else {
      body = const _LearnSkeleton();
    }

    return Scaffold(
      appBar: _LearnTopBar(streak: value?.progress.streak(today)),
      body: body,
    );
  }
}

class _LearnTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _LearnTopBar({required this.streak});

  /// Null while loading.
  final int? streak;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final streak = this.streak;
    return TopBarSurface(
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.page,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: const Text('Learn', style: AppTextStyles.headlineMd),
                  ),
                ),
                if (streak != null)
                  StreakChip(days: streak, active: streak > 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearnContent extends ConsumerWidget {
  const _LearnContent({required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedUnitProvider) ?? path.startUnit;
    final unit = path.course.unit(selected);
    final stats = path.statsFor(unit);

    void open(LessonNode node) {
      if (node.isLocked) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('${node.lockedReason}.')));
        return;
      }
      context.push(
        node.status == LessonStatus.reviewNeeded
            ? AppRoutes.review
            : AppRoutes.lessonPath(node.lesson.id),
      );
    }

    return ListView(
      padding: _listPadding,
      children: [
        Row(
          children: [
            Flexible(
              child: AppPill(
                label: unit.focus,
                icon: _focusIcon(unit),
                background: AppColors.primaryTint,
                foreground: AppColors.primary,
                size: AppPillSize.small,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _pickUnit(context, ref, selected),
              icon: const Icon(Icons.expand_more_rounded, size: 18),
              iconAlignment: IconAlignment.end,
              label: const Text('Change unit'),
            ),
          ],
        ),
        Semantics(
          header: true,
          child: Text(unit.fullTitle, style: AppTextStyles.headlineLg),
        ),
        if (unit.number == path.startUnit) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Your recommended starting point',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _UnitProgressCard(stats: stats),
        const SizedBox(height: AppSpacing.xl),
        PathView(
          key: ValueKey('path-${unit.number}'),
          nodes: path.nodesFor(unit),
          onOpen: open,
        ),
      ],
    );
  }

  static IconData _focusIcon(Unit unit) => switch (unit.number) {
    1 => Icons.style_rounded,
    2 => Icons.account_tree_rounded,
    _ => Icons.edit_note_rounded,
  };

  Future<void> _pickUnit(BuildContext context, WidgetRef ref, int current) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          children: [
            const Text('Choose a unit', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.smd),
            for (final unit in path.course.units) ...[
              SelectionCard(
                title: unit.fullTitle,
                subtitle: _unitSubtitle(unit),
                state: unit.number == current
                    ? SelectionCardState.selected
                    : SelectionCardState.idle,
                onTap: () {
                  ref.read(selectedUnitProvider.notifier).select(unit.number);
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: AppSpacing.smd),
            ],
          ],
        ),
      ),
    );
  }

  String _unitSubtitle(Unit unit) {
    final stats = path.statsFor(unit);
    final parts = [
      if (unit.number == path.startUnit) 'Recommended start',
      if (!path.isUnlocked(unit.lessons.first))
        'Locked'
      else
        '${stats.percentComplete}% complete',
    ];
    return parts.join(' · ');
  }
}

/// Completion and accuracy for the unit. No band.
class _UnitProgressCard extends StatelessWidget {
  const _UnitProgressCard({required this.stats});

  final UnitStats stats;

  @override
  Widget build(BuildContext context) {
    final accuracy = stats.accuracyPercent;
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  label:
                      '${stats.percentComplete}% complete, '
                      '${stats.completed} of ${stats.total} done',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: '${stats.percentComplete}%',
                          children: [
                            TextSpan(
                              text: ' complete',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        key: const ValueKey('unitPercent'),
                        style: AppTextStyles.tabular(AppTextStyles.headlineMd),
                      ),
                      Text(
                        '${stats.completed} of ${stats.total} done',
                        style: AppTextStyles.tabular(
                          AppTextStyles.bodySm,
                        ).copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: AppPill(
                  label: accuracy == null
                      ? 'No answers yet'
                      : 'Accuracy $accuracy%',
                  icon: accuracy == null ? null : Icons.verified_rounded,
                  iconColor: AppColors.success,
                  background: accuracy == null
                      ? AppColors.background
                      : AppColors.successTint,
                  foreground: accuracy == null
                      ? AppColors.textMuted
                      : AppColors.text,
                  size: AppPillSize.small,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smd),
          AppLinearProgress(
            value: stats.fraction,
            semanticLabel: 'Unit progress',
          ),
        ],
      ),
    );
  }
}

class _LearnSkeleton extends StatelessWidget {
  const _LearnSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: _listPadding,
          children: const [
            SkeletonBox(width: 120, height: 22),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 32),
            SizedBox(height: AppSpacing.md),
            SkeletonCard(height: 96),
            SizedBox(height: AppSpacing.xl),
            SkeletonCard(height: 80),
            SizedBox(height: AppSpacing.xl),
            SkeletonCard(height: 80),
            SizedBox(height: AppSpacing.xl),
            SkeletonCard(height: 80),
          ],
        ),
      ),
    );
  }
}
