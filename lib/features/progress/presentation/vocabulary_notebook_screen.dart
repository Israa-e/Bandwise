import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../review/domain/review_planner.dart';
import 'progress_controller.dart';
import 'progress_providers.dart';

const _padding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.page,
  AppSpacing.smd,
  AppSpacing.page,
  AppSpacing.xxl,
);

/// Words from finished lessons, with meaning, example and next review.
/// A word taken out of review leaves the queue but stays listed.
class VocabularyNotebookScreen extends ConsumerStatefulWidget {
  const VocabularyNotebookScreen({super.key});

  @override
  ConsumerState<VocabularyNotebookScreen> createState() =>
      _VocabularyNotebookScreenState();
}

class _VocabularyNotebookScreenState
    extends ConsumerState<VocabularyNotebookScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
            title: "Couldn't load your words",
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
      appBar: const TabTopBar(title: 'Vocabulary notebook', showBack: true),
      body: body,
    );
  }

  Widget _content(ProgressPageData data) {
    final words = data.planner.items.whereType<WordReviewItem>().toList();
    if (words.isEmpty) {
      return const EmptyStateView(
        key: ValueKey('wordsEmpty'),
        icon: Icons.translate_rounded,
        title: 'No words yet',
        message: 'Words from the lessons you finish appear here.',
      );
    }
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final w in words)
        if (query.isEmpty ||
            w.card.word.toLowerCase().contains(query) ||
            w.card.meaning.toLowerCase().contains(query))
          w,
    ];
    final today = ref.watch(todayProvider);
    final progress = data.progress;
    return ListView(
      padding: _padding,
      children: [
        AppTextField(
          key: const ValueKey('wordSearch'),
          label: 'Search words',
          hint: 'Word or meaning',
          prefixIcon: Icons.search_rounded,
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            query.isEmpty
                ? (words.length == 1 ? '1 word' : '${words.length} words')
                : '${shown.length} of ${words.length} words',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          ),
        ),
        if (shown.isEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No words match “${_search.text.trim()}”.',
            style: AppTextStyles.bodyMd,
          ),
        ],
        for (final w in shown) ...[
          const SizedBox(height: AppSpacing.smd),
          _WordCard(
            item: w,
            removed: !progress.isInReview(w.key),
            today: today,
            onRemovedChanged: (removed) => ref
                .read(progressControllerProvider.notifier)
                .setRemovedFromReview(w.key, removed: removed),
          ),
        ],
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.item,
    required this.removed,
    required this.today,
    required this.onRemovedChanged,
  });

  final WordReviewItem item;
  final bool removed;
  final DateTime today;
  final ValueChanged<bool> onRemovedChanged;

  @override
  Widget build(BuildContext context) {
    final card = item.card;
    final review = removed
        ? 'Not in your reviews'
        : item.dueOn.isAfter(today)
        ? 'Next review: ${formatMediumDate(item.dueOn)}'
        : 'Next review: today';
    return AppCard(
      key: ValueKey('word-${card.id}'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    Text(card.word, style: AppTextStyles.headlineSm),
                    AppPill(
                      label: card.partOfSpeech,
                      size: AppPillSize.small,
                      background: AppColors.primaryTint,
                      foreground: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(card.meaning, style: AppTextStyles.bodyMd),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  card.example,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.smd),
                Text(
                  review,
                  key: ValueKey('wordReview-${card.id}'),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          MergeSemantics(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Remove from review',
                    style: AppTextStyles.bodyMd,
                  ),
                ),
                Switch(
                  key: ValueKey('removeWord-${card.id}'),
                  value: removed,
                  onChanged: onRemovedChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
