import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../progress/domain/progress_state.dart';
import '../../progress/presentation/progress_controller.dart';
import '../domain/listening.dart';
import 'listening_providers.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// Listening hub: pick a recording and a mode; see recent attempts.
///
/// [initialType] (e.g. from a Progress recommendation) preselects the first
/// recording with that question type.
class ListeningHubScreen extends ConsumerStatefulWidget {
  const ListeningHubScreen({super.key, this.initialType});

  final ListeningQuestionType? initialType;

  @override
  ConsumerState<ListeningHubScreen> createState() => _ListeningHubScreenState();
}

class _ListeningHubScreenState extends ConsumerState<ListeningHubScreen> {
  String? _setId;
  var _mode = ListeningMode.learning;

  @override
  void didUpdateWidget(ListeningHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opened again with another type while this hub was kept in the tab.
    if (widget.initialType != oldWidget.initialType) _setId = null;
  }

  @override
  Widget build(BuildContext context) {
    final sets = ref.watch(listeningSetsProvider);
    final progress = ref.watch(progressControllerProvider);

    final Widget body;
    Widget? bottom;
    if (sets.hasValue && !sets.hasError) {
      final playable = sets.requireValue.where((s) => s.hasAudio).toList();
      final set =
          playable.where((s) => s.id == _setId).firstOrNull ??
          playable
              .where((s) => s.types.contains(widget.initialType))
              .firstOrNull ??
          playable.firstOrNull;
      body = _content(
        sets.requireValue,
        set,
        progress.value?.listeningAttempts ?? [],
      );
      bottom = StickyActionBar(
        child: AppButton.primary(
          label: 'Start practice',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: set == null
              ? null
              : () => context.push(
                  AppRoutes.listeningSession(
                    set.id,
                    timed: _mode == ListeningMode.timed,
                  ),
                ),
        ),
      );
    } else if (sets.hasError && !sets.isLoading) {
      body = ListView(
        padding: _padding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load listening practice",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(listeningSetsProvider),
          ),
        ],
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: const TabTopBar(title: 'Listening', showBack: true),
      body: body,
      bottomNavigationBar: bottom,
    );
  }

  Widget _content(
    List<ListeningSet> sets,
    ListeningSet? selected,
    List<ListeningAttempt> attempts,
  ) {
    final timed = _mode == ListeningMode.timed;
    return ListView(
      padding: _padding,
      children: [
        const SectionTitle('Recording'),
        if (sets.isEmpty)
          const EmptyStateView(
            icon: Icons.headphones_rounded,
            title: 'No recordings yet',
            message: 'Listening practice will appear here.',
          ),
        for (final s in sets) ...[
          SelectionCard(
            key: ValueKey('set-${s.id}'),
            title: s.title,
            subtitle: s.hasAudio
                ? 'Part ${s.part} · ${s.questions.length} questions · '
                      '${s.types.map((t) => t.label).join(', ')} · about '
                      '${(s.timedLength.inSeconds / 60).ceil()} min'
                : 'Part ${s.part} · Audio coming soon',
            leading: const SelectionLeadingBox(icon: Icons.headphones_rounded),
            state: !s.hasAudio
                ? SelectionCardState.disabled
                : s.id == selected?.id
                ? SelectionCardState.selected
                : SelectionCardState.idle,
            onTap: s.hasAudio ? () => setState(() => _setId = s.id) : null,
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        const SizedBox(height: AppSpacing.sm),
        const SectionTitle('Mode'),
        SelectionCard(
          key: const ValueKey('mode-learning'),
          title: 'Learning',
          subtitle:
              'Pause, replay and slow down. Check each answer and see why.',
          leading: const SelectionLeadingBox(icon: Icons.school_rounded),
          state: timed ? SelectionCardState.idle : SelectionCardState.selected,
          onTap: () => setState(() => _mode = ListeningMode.learning),
        ),
        const SizedBox(height: AppSpacing.smd),
        SelectionCard(
          key: const ValueKey('mode-timed'),
          title: 'Timed',
          subtitle:
              'Like the exam: the recording plays once, with reading time '
              'before each group. Answers are marked when you submit.',
          leading: const SelectionLeadingBox(icon: Icons.timer_outlined),
          state: timed ? SelectionCardState.selected : SelectionCardState.idle,
          onTap: () => setState(() => _mode = ListeningMode.timed),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Recent attempts'),
        _RecentAttempts(attempts: attempts, sets: sets),
      ],
    );
  }
}

/// The latest attempts with raw scores, newest first.
class _RecentAttempts extends ConsumerWidget {
  const _RecentAttempts({required this.attempts, required this.sets});

  static const _shown = 5;

  final List<ListeningAttempt> attempts;
  final List<ListeningSet> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attempts.isEmpty) {
      return Text(
        'No attempts yet. Your scores will appear here.',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
      );
    }
    final today = ref.watch(todayProvider);
    final recent = attempts.reversed.take(_shown).toList();
    return Column(
      children: [
        for (final (i, a) in recent.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _AttemptRow(
            attempt: a,
            title:
                sets.where((s) => s.id == a.setId).firstOrNull?.title ??
                'Listening practice',
            today: today,
          ),
        ],
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({
    required this.attempt,
    required this.title,
    required this.today,
  });

  final ListeningAttempt attempt;
  final String title;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final details = [
      attempt.timed ? 'Timed' : 'Learning',
      timeAgoLabel(today, attempt.date),
    ].join(' · ');
    final score = '${attempt.correct}/${attempt.total}';
    return AppCard(
      semanticLabel: '$title, $details. Score $score',
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
            Text(
              score,
              style: AppTextStyles.tabular(
                AppTextStyles.headlineSm,
              ).copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
