import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/speaking_attempt.dart';
import 'speaking_widgets.dart';

/// Practice and Confidence: record an answer, play it back, record it
/// again.
class RecorderPanel extends StatelessWidget {
  const RecorderPanel({
    super.key,
    required this.recording,
    required this.elapsed,
    required this.answer,
    required this.showTimes,
    required this.playing,
    required this.onRecord,
    required this.onStop,
    required this.onPlay,
    required this.onReRecord,
  });

  final bool recording;
  final Duration elapsed;

  /// The latest take, if any.
  final RecordedAnswer? answer;

  /// False in Confidence mode: no timers anywhere.
  final bool showTimes;
  final bool playing;
  final VoidCallback onRecord;
  final VoidCallback onStop;
  final VoidCallback onPlay;
  final VoidCallback onReRecord;

  @override
  Widget build(BuildContext context) {
    final answer = this.answer;
    final Widget body;
    if (recording) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RecordingIndicator(elapsed: showTimes ? elapsed : null),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            key: const ValueKey('stopRecording'),
            label: 'Stop recording',
            leadingIcon: Icons.stop_rounded,
            onPressed: onStop,
          ),
        ],
      );
    } else if (answer == null) {
      body = AppButton.primary(
        key: const ValueKey('startRecording'),
        label: 'Record my answer',
        leadingIcon: Icons.mic_rounded,
        onPressed: onRecord,
      );
    } else {
      final check = AnswerCheck(answer);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  showTimes
                      ? 'Your answer · ${formatSpeakingTime(answer.duration)}'
                      : 'Your answer is recorded',
                  key: const ValueKey('answerSummary'),
                  style: AppTextStyles.labelLg,
                ),
              ),
            ],
          ),
          if (check.longTurnUnderAMinute) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              showTimes
                  ? 'You spoke for ${formatSpeakingTime(answer.duration)}. '
                        'In the test you can keep going for up to 2 minutes: '
                        'try adding another detail or an example.'
                  : 'You could keep going a little longer: try adding '
                        'another detail or an example.',
              key: const ValueKey('underAMinute'),
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.smd),
          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  key: const ValueKey('playAnswer'),
                  label: playing ? 'Pause' : 'Play my answer',
                  leadingIcon: playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onPressed: answer.path == null ? null : onPlay,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.outline(
                  key: const ValueKey('reRecord'),
                  label: 'Record again',
                  leadingIcon: Icons.refresh_rounded,
                  onPressed: onReRecord,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: body,
    );
  }
}
