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
import '../domain/reading.dart';
import 'reading_providers.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// Reading hub: pick a passage, a mode and optionally one question type;
/// see recent attempts.
class ReadingHubScreen extends ConsumerStatefulWidget {
  const ReadingHubScreen({super.key});

  @override
  ConsumerState<ReadingHubScreen> createState() => _ReadingHubScreenState();
}

class _ReadingHubScreenState extends ConsumerState<ReadingHubScreen> {
  String? _passageId;
  var _mode = ReadingMode.learning;
  ReadingQuestionType? _type;

  @override
  Widget build(BuildContext context) {
    final passages = ref.watch(readingPassagesProvider);
    final progress = ref.watch(progressControllerProvider);

    final Widget body;
    Widget? bottom;
    if (passages.hasValue && !passages.hasError) {
      final list = passages.requireValue;
      final passage =
          list.where((p) => p.id == _passageId).firstOrNull ?? list.first;
      body = _content(list, passage, progress.value?.readingAttempts ?? []);
      bottom = StickyActionBar(
        child: AppButton.primary(
          label: 'Start practice',
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: () => context.push(
            AppRoutes.readingSession(
              passage.id,
              timed: _mode == ReadingMode.timed,
              type: _mode == ReadingMode.timed ? null : _type?.name,
            ),
          ),
        ),
      );
    } else if (passages.hasError && !passages.isLoading) {
      body = ListView(
        padding: _padding,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load reading passages",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(readingPassagesProvider),
          ),
        ],
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: const TabTopBar(title: 'Reading', showBack: true),
      body: body,
      bottomNavigationBar: bottom,
    );
  }

  Widget _content(
    List<ReadingPassage> passages,
    ReadingPassage passage,
    List<ReadingAttempt> attempts,
  ) {
    final timed = _mode == ReadingMode.timed;
    final type = passage.types.contains(_type) ? _type : null;
    return ListView(
      padding: _padding,
      children: [
        const _SectionTitle('Passage'),
        for (final p in passages) ...[
          SelectionCard(
            key: ValueKey('passage-${p.id}'),
            title: p.title,
            subtitle:
                '${p.topic} · ${p.wordCount} words · '
                '${p.questions.length} questions',
            leading: const SelectionLeadingBox(icon: Icons.menu_book_rounded),
            state: p.id == passage.id
                ? SelectionCardState.selected
                : SelectionCardState.idle,
            onTap: () => setState(() => _passageId = p.id),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        const SizedBox(height: AppSpacing.sm),
        const _SectionTitle('Mode'),
        SelectionCard(
          title: 'Learning',
          subtitle: 'No timer. Check each answer and see why.',
          leading: const SelectionLeadingBox(icon: Icons.school_rounded),
          state: timed ? SelectionCardState.idle : SelectionCardState.selected,
          onTap: () => setState(() => _mode = ReadingMode.learning),
        ),
        const SizedBox(height: AppSpacing.smd),
        SelectionCard(
          title: 'Timed',
          subtitle:
              '${ReadingPassage.timedMinutes} minutes for the whole passage. '
              'Answers are marked when you submit.',
          leading: const SelectionLeadingBox(icon: Icons.timer_outlined),
          state: timed ? SelectionCardState.selected : SelectionCardState.idle,
          onTap: () => setState(() => _mode = ReadingMode.timed),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle('Question type'),
        if (timed)
          Text(
            'Timed practice uses every question in the passage.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FilterChip(
                label: 'All types',
                selected: type == null,
                onTap: () => setState(() => _type = null),
              ),
              for (final t in passage.types)
                _FilterChip(
                  label: t.label,
                  selected: type == t,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionTitle('Recent attempts'),
        _RecentAttempts(attempts: attempts, passages: passages),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text, style: AppTextStyles.headlineSm),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.selectedSurface : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillRadius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: selected ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The latest attempts with raw scores, newest first.
class _RecentAttempts extends ConsumerWidget {
  const _RecentAttempts({required this.attempts, required this.passages});

  static const _shown = 5;

  final List<ReadingAttempt> attempts;
  final List<ReadingPassage> passages;

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
                passages.where((p) => p.id == a.passageId).firstOrNull?.title ??
                'Reading passage',
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

  final ReadingAttempt attempt;
  final String title;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final type = ReadingQuestionType.values
        .where((t) => t.name == attempt.questionType)
        .firstOrNull;
    final details = [
      attempt.timed ? 'Timed' : 'Learning',
      ?type?.label,
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
