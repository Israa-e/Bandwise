import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../progress/domain/progress_state.dart';

/// "All caught up": what the session did and when the next review is.
class ReviewCompleteView extends StatelessWidget {
  const ReviewCompleteView({
    super.key,
    required this.reviewed,
    required this.xpEarned,
    required this.today,
    required this.nextReview,
    required this.xpCapReached,
  });

  final int reviewed;
  final int xpEarned;
  final DateTime today;

  /// Null when nothing is scheduled.
  final DateTime? nextReview;

  /// Today's review XP limit is used up.
  final bool xpCapReached;

  @override
  Widget build(BuildContext context) {
    final next = nextReview;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        const Center(
          child: SuccessBadge(
            icon: Icons.done_all_rounded,
            semanticLabel: 'Review complete',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: const Text(
            'All caught up',
            style: AppTextStyles.headlineLg,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Your reviews are saved and scheduled.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ResultStatTile(
                  key: const ValueKey('reviewed'),
                  label: 'Reviewed',
                  value: '$reviewed',
                  caption: reviewed == 1 ? 'item' : 'items',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  key: const ValueKey('xpEarned'),
                  label: 'XP earned',
                  value: '+$xpEarned',
                  caption: 'XP',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  key: const ValueKey('nextReview'),
                  label: 'Next review',
                  value: next == null ? '–' : formatShortDate(next),
                  caption: next == null
                      ? 'none due'
                      : 'in ${timeUntilLabel(today, next)}',
                ),
              ),
            ],
          ),
        ),
        if (xpCapReached) ...[
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            title: "Today's review XP is maxed out",
            message:
                'Reviews earn up to ${XpRules.maxReviewPerDay} XP a day. '
                'They still count toward your streak and study time.',
          ),
        ],
      ],
    );
  }
}
