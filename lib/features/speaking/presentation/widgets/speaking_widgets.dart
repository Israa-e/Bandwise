import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/speaking.dart';
import '../../domain/speaking_attempt.dart';

/// Unmistakable while recording: a red dot, the word "Recording" and, unless
/// [elapsed] is null (Confidence mode has no timers), the time so far.
/// Never colour alone; not animated.
class RecordingIndicator extends StatelessWidget {
  const RecordingIndicator({super.key, this.elapsed});

  final Duration? elapsed;

  @override
  Widget build(BuildContext context) {
    final elapsed = this.elapsed;
    return Semantics(
      liveRegion: true,
      label: elapsed == null
          ? 'Recording'
          : 'Recording, ${formatSpeakingTime(elapsed)}',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('recordingIndicator'),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.smd,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.errorTint,
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 12),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Recording',
              style: AppTextStyles.labelLg.copyWith(color: AppColors.errorText),
            ),
            if (elapsed != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatSpeakingTime(elapsed),
                key: const ValueKey('recordingTime'),
                style: AppTextStyles.tabular(
                  AppTextStyles.labelLg,
                ).copyWith(color: AppColors.errorText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A Part 2 cue card: the topic, "You should say:" points, and what to
/// explain.
class CueCardView extends StatelessWidget {
  const CueCardView({super.key, required this.card});

  final CueCard card;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('cueCard-${card.id}'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            card.prompt,
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You should say:',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
          ),
          for (final b in card.bullets)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: AppTextStyles.bodyMd),
                  Expanded(child: Text(b, style: AppTextStyles.bodyMd)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(card.explain, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

/// Confidence mode: short questions that help organise an answer.
class GentlePrompts extends StatelessWidget {
  const GentlePrompts({super.key, required this.part});

  final SpeakingPart part;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('gentlePrompts'),
      decoration: const BoxDecoration(
        color: AppColors.speakingTint,
        borderRadius: AppRadii.nestedRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.smd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ideas to help you',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in gentlePromptsFor(part))
                  AppPill(
                    label: p,
                    size: AppPillSize.small,
                    background: AppColors.card,
                    foreground: AppColors.text,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown with every self-review: there is no AI review yet.
class NoAiFeedbackBanner extends StatelessWidget {
  const NoAiFeedbackBanner({super.key});

  static const text = "AI feedback isn't connected yet — no estimate is given.";

  @override
  Widget build(BuildContext context) => const InfoBanner(
    key: ValueKey('noAiFeedback'),
    type: InfoBannerType.info,
    message: text,
  );
}

/// The label and note that go with every automatic transcript.
abstract final class TranscriptCopy {
  static const label = 'Automatic transcript — may contain mistakes';
  static const deviceNote =
      "Uses your phone's speech recognition while you record, which may "
      'send the audio to its recognition service. It is never used as an '
      'assessment.';
}
