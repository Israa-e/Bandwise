import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/listening.dart';
import '../../domain/listening_audio.dart';
import '../listening_providers.dart';
import 'transcript_view.dart';

/// Review: the part of the recording a question is about (the line before
/// the answer, then the answer's line), to play as often as needed. Once
/// [revealed], it also shows what was said, with the answer's words marked.
class ListeningClip extends ConsumerStatefulWidget {
  const ListeningClip({
    super.key,
    required this.set,
    required this.question,
    required this.revealed,
  });

  final ListeningSet set;
  final ListeningQuestion question;
  final bool revealed;

  @override
  ConsumerState<ListeningClip> createState() => _ListeningClipState();
}

class _ListeningClipState extends ConsumerState<ListeningClip> {
  late final ListeningAudio _audio;
  final _subscriptions = <StreamSubscription<Object?>>[];
  var _loaded = false;
  var _failed = false;
  var _playing = false;

  late final LineTiming? _clip = _clipFor(widget.set, widget.question);

  /// From the start of the line before the answer (unless it's the
  /// narrator) to the end of the answer's line.
  static LineTiming? _clipFor(ListeningSet set, ListeningQuestion q) {
    final index = set.lineIndex(q.evidenceLineId);
    final end = set.timings[q.evidenceLineId];
    if (index < 0 || end == null) return null;
    final before = index > 0 ? set.lines[index - 1] : null;
    final start = before == null || before.speakerId == 'narrator'
        ? end
        : set.timings[before.id] ?? end;
    return LineTiming(start.start, end.end);
  }

  @override
  void initState() {
    super.initState();
    _audio = ref.read(listeningAudioFactoryProvider)();
    _subscriptions
      ..add(
        _audio.positionStream.listen((p) {
          final clip = _clip;
          if (clip != null && _playing && p >= clip.end) _stop();
        }),
      )
      ..add(
        _audio.playingStream.listen((p) {
          if (mounted) setState(() => _playing = p);
        }),
      );
    _load();
  }

  Future<void> _load() async {
    try {
      await _audio.load(widget.set.audioAsset);
      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _audio.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final clip = _clip;
    if (clip == null) return;
    await _audio.seek(clip.start);
    await _audio.play();
  }

  Future<void> _stop() => _audio.pause();

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final line = set.lines.where((l) => l.id == widget.question.evidenceLineId);
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LISTEN AGAIN',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_failed)
            Text(
              "Couldn't load the audio.",
              style: AppTextStyles.bodySm.copyWith(color: AppColors.errorText),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton.outline(
                key: const ValueKey('playClip'),
                label: _playing ? 'Stop' : 'Play the clip',
                leadingIcon: _playing
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                compact: true,
                expand: false,
                onPressed: !_loaded || _clip == null
                    ? null
                    : _playing
                    ? _stop
                    : _play,
              ),
            ),
          if (widget.revealed && line.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.smd),
            Text(
              set.speaker(line.first.speakerId)?.name ?? '',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text.rich(
              evidenceSpans(line.first.text, [widget.question.evidence]),
              key: const ValueKey('clipTranscript'),
              style: AppTextStyles.bodyMd,
            ),
          ],
        ],
      ),
    );
  }
}
