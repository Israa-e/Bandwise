import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../domain/progress_state.dart';
import 'progress_providers.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// Skill filter for reading mistakes; lesson mistakes use their unit's
/// focus ("Vocabulary", "Grammar", …).
const _readingSkill = 'Reading';

/// Saved mistakes from one lesson or passage.
class _MistakeGroup {
  _MistakeGroup(this.title, this.skill);

  final String title;
  final String skill;
  final mistakes = <SavedMistake>[];
}

/// Every saved mistake, grouped by where it was made, with the next review
/// date of each.
class MistakeNotebookScreen extends ConsumerStatefulWidget {
  const MistakeNotebookScreen({super.key});

  @override
  ConsumerState<MistakeNotebookScreen> createState() =>
      _MistakeNotebookScreenState();
}

class _MistakeNotebookScreenState extends ConsumerState<MistakeNotebookScreen> {
  /// Null shows every skill.
  String? _skill;

  List<_MistakeGroup> _groups(ProgressPageData data) {
    final course = data.path.course;
    final groups = <String, _MistakeGroup>{};
    for (final m in data.progress.mistakes) {
      final group = groups.putIfAbsent('${m.source.name}:${m.sourceId}', () {
        if (m.source == MistakeSource.reading) {
          final passage = data.passages
              .where((p) => p.id == m.sourceId)
              .firstOrNull;
          return _MistakeGroup(
            passage?.title ?? 'Reading passage',
            _readingSkill,
          );
        }
        final lesson = course.lessonById(m.sourceId);
        if (lesson == null) return _MistakeGroup('Lesson', 'Lessons');
        final unit = course.unit(lesson.unit);
        return _MistakeGroup(
          'Unit ${unit.number} · ${lesson.label}: ${lesson.title}',
          unit.focus,
        );
      });
      group.mistakes.add(m);
    }
    // Lessons in path order, then passages in hub order.
    final order = [
      for (final l in course.lessons) '${MistakeSource.lesson.name}:${l.id}',
      for (final p in data.passages) '${MistakeSource.reading.name}:${p.id}',
    ];
    int rank(String key) {
      final i = order.indexOf(key);
      return i < 0 ? order.length : i;
    }

    final keys = groups.keys.toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    return [for (final k in keys) groups[k]!];
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(progressPageProvider);
    final Widget body;
    if (page.hasValue && !page.hasError) {
      body = _content(page.requireValue);
    } else if (page.hasError && !page.isLoading) {
      body = ListView(
        padding: _padding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load your mistakes",
            message: 'They are saved. Try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(progressPageProvider),
          ),
        ],
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: const TabTopBar(title: 'Mistake notebook', showBack: true),
      body: body,
    );
  }

  Widget _content(ProgressPageData data) {
    final mistakes = data.progress.mistakes;
    if (mistakes.isEmpty) {
      return const EmptyStateView(
        key: ValueKey('mistakesEmpty'),
        icon: Icons.error_outline_rounded,
        title: 'No mistakes saved yet',
        message:
            'Wrong answers from lessons and reading practice are saved '
            'here, so you can review them.',
      );
    }
    final today = ref.watch(todayProvider);
    final dueOn = {for (final i in data.planner.queued) i.key: i.dueOn};
    final dueToday = mistakes
        .where((m) => !(dueOn[m.reviewKey]?.isAfter(today) ?? true))
        .length;
    final groups = _groups(data);
    final skills = {for (final g in groups) g.skill};
    final skill = skills.contains(_skill) ? _skill : null;
    final shown = [
      for (final g in groups)
        if (skill == null || g.skill == skill) g,
    ];

    return ListView(
      padding: _padding,
      children: [
        Text(
          [
            mistakes.length == 1
                ? '1 saved mistake'
                : '${mistakes.length} saved mistakes',
            if (dueToday > 0) '$dueToday due today',
          ].join(' · '),
          key: const ValueKey('mistakeCount'),
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.smd),
        AppButton.primary(
          label: 'Review now',
          leadingIcon: Icons.replay_rounded,
          onPressed: () => context.push(AppRoutes.review),
        ),
        if (skills.length > 1) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppFilterChip(
                label: 'All',
                selected: skill == null,
                onTap: () => setState(() => _skill = null),
              ),
              for (final s in skills)
                AppFilterChip(
                  label: s,
                  selected: skill == s,
                  onTap: () => setState(() => _skill = s),
                ),
            ],
          ),
        ],
        for (final group in shown) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionTitle(group.title),
          for (final m in group.mistakes) ...[
            _MistakeCard(mistake: m, dueOn: dueOn[m.reviewKey], today: today),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({
    required this.mistake,
    required this.dueOn,
    required this.today,
  });

  final SavedMistake mistake;

  /// Null when the question is no longer in the course.
  final DateTime? dueOn;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final due = dueOn;
    final review = due == null
        ? 'Not scheduled for review'
        : due.isAfter(today)
        ? 'Next review: ${formatMediumDate(due)}'
        : 'Next review: today';
    return AppCard(
      key: ValueKey('mistake-${mistake.itemId}'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(mistake.prompt, style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.smd),
          _AnswerLine(
            icon: Icons.close_rounded,
            color: AppColors.error,
            label: 'Your answer',
            answer: mistake.yourAnswer,
          ),
          const SizedBox(height: AppSpacing.xs),
          _AnswerLine(
            icon: Icons.check_rounded,
            color: AppColors.success,
            label: 'Correct answer',
            answer: mistake.correctAnswer,
          ),
          const SizedBox(height: AppSpacing.smd),
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  review,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.answer,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $answer',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textMuted,
                ),
                children: [TextSpan(text: answer, style: AppTextStyles.bodyMd)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
