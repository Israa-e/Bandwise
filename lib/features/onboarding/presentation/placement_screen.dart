import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/onboarding_state.dart';
import '../domain/placement.dart';
import 'onboarding_controller.dart';
import 'onboarding_navigation.dart';
import 'widgets/onboarding_scaffold.dart';

/// Step 6: short placement check. One question at a time: pick, check,
/// see the explanation, continue. The result only picks a starting unit.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  static const _step = OnboardingStep.placement;

  /// Option picked for the current question but not yet checked.
  int? _pending;

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  Future<void> _showQuestion(int index) async {
    setState(() => _pending = null);
    await _controller.showPlacementQuestion(index);
  }

  void _back(int index) {
    if (index > 0) {
      _showQuestion(index - 1);
    } else {
      goToOnboardingStep(context, ref, _step.previous!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(placementQuestionsProvider);
    final state = ref.watch(onboardingControllerProvider).requireValue;

    return switch (questions) {
      AsyncData(:final value) when value.isNotEmpty => _buildQuestion(
        value,
        state,
      ),
      AsyncData() => _shell(
        state,
        children: const [
          EmptyStateView(
            icon: Icons.quiz_outlined,
            title: 'No questions available',
            message: 'You can skip this step and start with your plan.',
          ),
        ],
      ),
      AsyncError() => _shell(
        state,
        children: [
          InfoBanner(
            type: InfoBannerType.error,
            title: "Couldn't load the placement check",
            message: 'Check your connection and try again, or skip this step.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(placementQuestionsProvider),
          ),
        ],
      ),
      _ => _shell(
        state,
        children: const [
          Padding(
            padding: EdgeInsetsDirectional.only(top: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    };
  }

  Widget _shell(
    OnboardingState state, {
    required List<Widget> children,
    Widget? header,
    VoidCallback? onContinue,
    String continueLabel = 'Check answer',
    IconData? continueIcon,
    VoidCallback? onBack,
    Key? bodyKey,
  }) {
    return OnboardingScaffold(
      step: _step,
      bodyKey: bodyKey,
      title: 'Quick placement check',
      note:
          'This helps us recommend a starting point. It is not an official '
          'level.',
      header: header,
      onBack: onBack,
      onContinue: onContinue,
      continueLabel: continueLabel,
      continueIcon: continueIcon,
      children: children,
    );
  }

  Widget _buildQuestion(
    List<PlacementQuestion> questions,
    OnboardingState state,
  ) {
    final index = state.placementIndex.clamp(0, questions.length - 1);
    final question = questions[index];
    final answer = state.placementAnswers[index];
    final checked = answer != null;
    final isLast = index == questions.length - 1;

    SelectionCardState optionState(int i) {
      if (!checked) {
        return i == _pending
            ? SelectionCardState.selected
            : SelectionCardState.idle;
      }
      if (i == question.correctIndex) return SelectionCardState.correct;
      if (i == answer) return SelectionCardState.incorrect;
      return SelectionCardState.disabled;
    }

    final VoidCallback? onContinue;
    if (checked) {
      onContinue = isLast
          ? () => goToOnboardingStep(context, ref, _step.next!)
          : () => _showQuestion(index + 1);
    } else if (_pending != null) {
      final pending = _pending!;
      onContinue = () => _controller.answerPlacement(index, pending);
    } else {
      onContinue = null;
    }

    return _shell(
      state,
      bodyKey: ValueKey('question-$index'),
      onBack: () => _back(index),
      onContinue: onContinue,
      continueLabel: checked
          ? (isLast ? 'See my plan' : 'Next question')
          : 'Check answer',
      continueIcon: checked ? Icons.arrow_forward_rounded : null,
      children: [
        _QuestionProgress(
          index: index,
          total: questions.length,
          category: question.category,
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                question.type.toUpperCase(),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(question.prompt, style: AppTextStyles.headlineSm),
              if (question.passage != null) ...[
                const SizedBox(height: AppSpacing.smd),
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.smd + 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadii.nestedRadius,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(question.passage!, style: AppTextStyles.bodyLg),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < question.options.length; i++) ...[
          SelectionCard(
            title: question.options[i],
            leading: SelectionLeadingBox(text: String.fromCharCode(65 + i)),
            state: optionState(i),
            onTap: checked ? null : () => setState(() => _pending = i),
          ),
          const SizedBox(height: AppSpacing.smd),
        ],
        if (checked)
          Semantics(
            liveRegion: true,
            child: InfoBanner(
              type: answer == question.correctIndex
                  ? InfoBannerType.success
                  : InfoBannerType.info,
              icon: Icons.lightbulb_outline_rounded,
              title: answer == question.correctIndex
                  ? 'Correct'
                  : 'The answer is ${String.fromCharCode(65 + question.correctIndex)}',
              message: question.explanation,
            ),
          ),
      ],
    );
  }
}

class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress({
    required this.index,
    required this.total,
    required this.category,
  });

  final int index;
  final int total;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Question ${index + 1} of $total',
                style: AppTextStyles.tabular(
                  AppTextStyles.labelMd,
                ).copyWith(color: AppColors.primary),
              ),
            ),
            Text(
              category,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppLinearProgress(
          value: (index + 1) / total,
          height: 6,
          semanticLabel: 'Question ${index + 1} of $total',
        ),
      ],
    );
  }
}
