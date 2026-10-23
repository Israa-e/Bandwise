import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// "4:05"; hours become minutes.
String formatClock(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Play/pause, back 5 seconds, a seek bar and the speed: learning mode and
/// results.
class AudioControls extends StatelessWidget {
  const AudioControls({
    super.key,
    required this.position,
    required this.length,
    required this.playing,
    required this.speed,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeed,
  });

  static const speeds = [1.0, 0.75];

  final Duration position;
  final Duration length;
  final bool playing;
  final double speed;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeed;

  @override
  Widget build(BuildContext context) {
    final max = length.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, length.inMilliseconds);
    final back = position - const Duration(seconds: 5);
    return AppCard(
      key: const ValueKey('audioControls'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.smd,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('playPause'),
            tooltip: playing ? 'Pause' : 'Play',
            onPressed: onPlayPause,
            icon: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            key: const ValueKey('back5'),
            tooltip: 'Back 5 seconds',
            onPressed: () => onSeek(back.isNegative ? Duration.zero : back),
            icon: const Icon(Icons.replay_5_rounded, color: AppColors.text),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Slider(
                  value: max == 0 ? 0 : value.toDouble(),
                  max: max == 0 ? 1 : max,
                  semanticFormatterCallback: (v) =>
                      formatClock(Duration(milliseconds: v.round())),
                  onChanged: max == 0
                      ? null
                      : (v) => onSeek(Duration(milliseconds: v.round())),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    '${formatClock(position)} / ${formatClock(length)}',
                    style: AppTextStyles.tabular(
                      AppTextStyles.bodySm,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('speed'),
            onPressed: () =>
                onSpeed(speed == speeds.first ? speeds.last : speeds.first),
            child: Text(
              speed == 1 ? '1×' : '$speed×',
              semanticsLabel: 'Speed ${speed == 1 ? 'normal' : '$speed times'}',
              style: AppTextStyles.tabular(AppTextStyles.labelMd),
            ),
          ),
        ],
      ),
    );
  }
}

/// Timed mode: what is playing and how far along, with nothing to press.
/// The audio plays once, like the exam.
class TimedAudioStatus extends StatelessWidget {
  const TimedAudioStatus({
    super.key,
    required this.position,
    required this.length,
    required this.label,
  });

  final Duration position;
  final Duration length;

  /// "Playing" or "Paused for reading time".
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = length == Duration.zero
        ? 0.0
        : (position.inMilliseconds / length.inMilliseconds).clamp(0.0, 1.0);
    return AppCard(
      key: const ValueKey('timedAudioStatus'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      semanticLabel:
          '$label, ${formatClock(position)} of ${formatClock(length)}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.headphones_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(label, style: AppTextStyles.labelLg)),
                Text(
                  '${formatClock(position)} / ${formatClock(length)}',
                  style: AppTextStyles.tabular(
                    AppTextStyles.bodySm,
                  ).copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppLinearProgress(value: fraction, height: 6),
          ],
        ),
      ),
    );
  }
}

/// "Read questions 1–5 · 0:30" while the audio is paused for reading time.
/// Learning mode can skip it.
class ReadingTimeBanner extends StatelessWidget {
  const ReadingTimeBanner({
    super.key,
    required this.label,
    required this.remaining,
    this.onSkip,
  });

  /// "questions 1–5".
  final String label;
  final Duration remaining;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final onSkip = this.onSkip;
    return DecoratedBox(
      key: const ValueKey('readingTime'),
      decoration: const BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.smd,
          AppSpacing.sm,
          AppSpacing.smd,
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label:
                    'Reading time. Read $label. '
                    '${remaining.inSeconds} seconds left.',
                excludeSemantics: true,
                child: Text.rich(
                  TextSpan(
                    text: 'Read $label · ',
                    children: [
                      TextSpan(
                        text: formatClock(remaining),
                        style: AppTextStyles.tabular(
                          AppTextStyles.labelLg,
                        ).copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  style: AppTextStyles.labelLg,
                ),
              ),
            ),
            if (onSkip != null)
              TextButton(
                key: const ValueKey('skipReadingTime'),
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
          ],
        ),
      ),
    );
  }
}
