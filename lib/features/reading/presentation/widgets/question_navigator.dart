import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// One question's state in the navigator.
typedef NavigatorEntry = ({bool answered, bool flagged});

/// Opens the question navigator. Returns the tapped question's index.
Future<int?> showQuestionNavigator(
  BuildContext context,
  List<NavigatorEntry> entries,
) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        child: QuestionNavigator(
          entries: entries,
          onOpen: (i) => Navigator.pop(context, i),
        ),
      ),
    ),
  );
}

/// Numbered tiles showing answered, unanswered and flagged questions.
class QuestionNavigator extends StatelessWidget {
  const QuestionNavigator({
    super.key,
    required this.entries,
    required this.onOpen,
  });

  final List<NavigatorEntry> entries;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final answered = entries.where((e) => e.answered).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Questions', style: AppTextStyles.headlineSm),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '$answered of ${entries.length} answered',
          style: AppTextStyles.tabular(
            AppTextStyles.bodySm,
          ).copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (i, e) in entries.indexed)
              _Tile(number: i + 1, entry: e, onTap: () => onOpen(i)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _Legend(
              swatch: _Swatch(fill: AppColors.primary),
              label: 'Answered',
            ),
            _Legend(
              swatch: _Swatch(fill: AppColors.card, border: AppColors.border),
              label: 'Not answered',
            ),
            _Legend(
              swatch: Icon(
                Icons.flag_rounded,
                size: 16,
                color: AppColors.warning,
              ),
              label: 'Flagged',
            ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.number, required this.entry, required this.onTap});

  final int number;
  final NavigatorEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final answered = entry.answered;
    final label = [
      'Question $number',
      answered ? 'answered' : 'not answered',
      if (entry.flagged) 'flagged',
    ].join(', ');
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: answered ? AppColors.primary : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.nestedRadius,
          side: BorderSide(
            color: entry.flagged
                ? AppColors.warning
                : answered
                ? AppColors.primary
                : AppColors.border,
            width: entry.flagged ? 2.5 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('nav-$number'),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.tabular(AppTextStyles.labelLg)
                        .copyWith(
                          color: answered
                              ? AppColors.onPrimary
                              : AppColors.text,
                        ),
                  ),
                ),
                if (entry.flagged)
                  const PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: Icon(
                      Icons.flag_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.fill, this.border});

  final Color fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: border == null ? null : Border.all(color: border!, width: 1.5),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
